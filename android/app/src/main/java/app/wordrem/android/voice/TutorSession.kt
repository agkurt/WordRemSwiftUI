package app.wordrem.android.voice

import android.util.Base64
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.wordrem.android.data.Store
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

enum class Phase { CONNECTING, READY, LISTENING, THINKING, SPEAKING, ENDED, FAILED }

data class Turn(val role: Role, val text: String, val translation: String = "") {
    enum class Role { AI, USER, CARD }
}

/**
 * Canlı ders/sohbet oturumu: bas-konuş, altyazı, kartlar ve ders yönlendirmesi (iOS RealtimeVoiceSession'ın özü).
 * Öğretmene, öğrencinin söylediğine göre sıradaki adımı gizli notlarla söyler (yeni parça → kendine uyarla → birleştir → canlandırma).
 */
class TutorSession(private val mode: TutorMode) {
    private val main = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val recorder = PcmRecorder()
    private val player = PcmPlayer()
    private var engine: VoiceEngine? = null
    private var sessionId: String? = null
    private var startedAt = 0L
    private var holdStartedAt = 0L
    private var transcriptTimeout: Job? = null
    private var awaitingTranscript = false

    var phase by mutableStateOf(Phase.CONNECTING); private set
    val turns = mutableStateListOf<Turn>()
    var card by mutableStateOf<Turn?>(null); private set
    /** "paywall" · "limit_reached" · "network" · "not_configured" · "time_up" */
    var errorCode by mutableStateOf<String?>(null); private set
    var lessonComplete by mutableStateOf(false); private set
    val micLevel: Float get() = recorder.level

    // Ders yönlendirmesi
    private val targets = TutorBrain.targets(mode)
    private val withRoleplay = mode is TutorMode.Goal
    private val answerCardsOnly = mode == TutorMode.Demo
    private var warmupPending = mode is TutorMode.Goal && targets.isNotEmpty()
    private var targetProgress = 0
    private var attempts = 0
    private var pendingCombine = false
    private var pendingPersonalize = false
    private var roleplayTurns = 0
    private var correctsSincePraise = 0
    private var personalizeIndex = 0
    private var chatMisses = 0
    private var finishCalled = false

    fun start() {
        TutorBrain.sessionLanguage = null
        connect(engineName = "gemini")
    }

    private fun connect(engineName: String) {
        phase = Phase.CONNECTING
        main.launch {
            val grant = try {
                VoiceBackend.createSession(TutorBrain.instructions(mode), TutorBrain.tools,
                    quality = if (mode == TutorMode.FreeChat) "standard" else "high", engine = engineName)
            } catch (f: VoiceBackend.Failure) {
                errorCode = f.code; phase = Phase.FAILED; return@launch
            }
            sessionId = grant.sessionId
            startedAt = System.currentTimeMillis()
            engine = if (grant.model == "gemini")
                GeminiEngine(grant.sessionId, TutorBrain.tools, { TutorBrain.targetCode }, Store.nativeLang, ::onEvent)
            else RealtimeEngine(grant.sessionId, ::onEvent)
            engine!!.start()
        }
    }

    // MARK: Bas-konuş
    fun holdStart() {
        val e = engine ?: return
        if (phase == Phase.CONNECTING || phase == Phase.ENDED || phase == Phase.FAILED) return
        if (phase == Phase.SPEAKING || phase == Phase.THINKING) {
            e.handle(ev("response.cancel"))
            player.flush()
        }
        e.handle(ev("input_audio_buffer.clear"))
        holdStartedAt = System.currentTimeMillis()
        recorder.start()
        phase = Phase.LISTENING
    }

    fun holdEnd() {
        if (phase != Phase.LISTENING) return
        val pcm = recorder.stop()
        val e = engine ?: return
        if (System.currentTimeMillis() - holdStartedAt < 200 || pcm.size < 9_600) { phase = Phase.READY; return }
        e.pushAudio(pcm)
        e.handle(ev("input_audio_buffer.commit"))
        phase = Phase.THINKING
        awaitingTranscript = true
        transcriptTimeout?.cancel()
        transcriptTimeout = main.launch {
            delay(8_000)
            if (awaitingTranscript) { awaitingTranscript = false; requestResponse() }
        }
    }

    /** Yazarak konuşma: aynı canlı oturuma öğrencinin mesajı olarak gider */
    fun sendText(text: String) {
        val t = text.trim()
        val e = engine ?: return
        if (t.isEmpty() || phase == Phase.ENDED || phase == Phase.FAILED || phase == Phase.CONNECTING) return
        if (phase == Phase.SPEAKING) { e.handle(ev("response.cancel")); player.flush() }
        turns += Turn(Turn.Role.USER, t)
        guide(t)
        e.handle(ev("conversation.item.create").put("item", JSONObject().put("type", "message").put("role", "user")
            .put("content", JSONArray().put(JSONObject().put("type", "input_text").put("text", t)))))
        requestResponse()
    }

    private fun requestResponse() {
        phase = Phase.THINKING
        engine?.handle(ev("response.create"))
    }

    // MARK: Motor olayları (OpenAI Realtime biçiminde)
    private fun onEvent(e: JSONObject) {
        when (e.optString("type")) {
            "session.created" -> {
                if (phase != Phase.CONNECTING) return
                if (mode == TutorMode.FreeChat) phase = Phase.READY else requestResponse()
            }
            "response.created" -> turns += Turn(Turn.Role.AI, "")
            "response.output_audio.delta", "response.audio.delta" -> {
                player.enqueue(Base64.decode(e.optString("delta"), Base64.DEFAULT))
                if (phase != Phase.LISTENING) phase = Phase.SPEAKING
            }
            "response.output_audio_transcript.delta", "response.audio_transcript.delta" -> {
                val i = turns.indexOfLast { it.role == Turn.Role.AI }
                if (i >= 0) turns[i] = turns[i].copy(text = turns[i].text + e.optString("delta"))
                else turns += Turn(Turn.Role.AI, e.optString("delta"))
            }
            "conversation.item.input_audio_transcription.completed" -> {
                if (!awaitingTranscript) return
                awaitingTranscript = false
                transcriptTimeout?.cancel()
                val said = e.optString("transcript").trim()
                if (said.isNotEmpty()) turns += Turn(Turn.Role.USER, said)
                guide(said)
                requestResponse()
            }
            "response.function_call_arguments.done" -> {
                val args = runCatching { JSONObject(e.optString("arguments")) }.getOrDefault(JSONObject())
                val name = e.optString("name")
                val output = TutorBrain.handle(name, args, mode,
                    onPhrase = { p, t -> val c = Turn(Turn.Role.CARD, p, t); turns += c; card = c },
                    onFinish = { finishCalled = true; Store.markStudiedToday() })
                engine?.handle(ev("conversation.item.create").put("item", JSONObject()
                    .put("type", "function_call_output").put("call_id", e.optString("call_id")).put("output", output)))
            }
            "response.done" -> {
                turns.removeAll { it.role == Turn.Role.AI && it.text.isBlank() }
                if (phase != Phase.LISTENING) phase = Phase.READY
                if (finishCalled) main.launch {
                    while (player.isSpeaking) delay(200)
                    delay(1500)
                    lessonComplete = true
                    end()
                }
            }
            "engine.unavailable" -> { engine = null; connect(engineName = "realtime") }
            "engine.time_up" -> { errorCode = "time_up"; end() }
            "engine.failed" -> { if (phase != Phase.ENDED) { errorCode = "network"; phase = Phase.FAILED } }
            "error" -> Log.e(TAG, "server error: $e")
        }
    }

    // MARK: Ders yönlendirmesi
    private fun words(s: String) = s.lowercase().split(Regex("[^\\p{L}']+")).filter { it.isNotEmpty() }
    private fun overlap(said: String, cardText: String): Double {
        val s = words(said).toSet()
        return cardText.split(" / ").maxOf { opt ->
            val w = words(opt).filter { it != "..." }
            if (w.isEmpty()) 0.0 else w.count { it in s }.toDouble() / w.size
        }
    }

    private fun sendGuide(note: String) {
        Log.i(TAG, "guide: $note")
        engine?.handle(ev("conversation.item.create").put("item", JSONObject().put("type", "message").put("role", "system")
            .put("content", JSONArray().put(JSONObject().put("type", "input_text").put("text", note + NOTE_LANGUAGE)))))
    }

    private fun praiseNote(afterMiss: Boolean): String {
        correctsSincePraise++
        if (afterMiss || correctsSincePraise >= 4) {
            correctsSincePraise = 0
            return "The learner got it right${if (afterMiss) " after a struggle" else ""}. Give ONE short, specific, genuine word of praise (what exactly was good), never generic like \"very natural, you sound confident\" and never the same compliment word as before."
        }
        return "The learner got it right. Do NOT praise or compliment this time: react to WHAT they said, like a friend in a real conversation, and keep going."
    }

    private fun guide(said: String) {
        val current = card?.text
        if (said.isEmpty()) {
            return sendGuide("You couldn't hear the learner this time (no words came through). Don't quote anything or count it as a mistake — say in a few playful words you didn't catch that, and ask them to say the line again.")
        }
        Store.markStudiedToday()
        if (targets.isEmpty()) {
            if (current == null) return
            card = null
            if (overlap(said, current) >= 0.6 || words(said).size >= 3 && overlap(said, current) >= 0.3) {
                chatMisses = 0
                return sendGuide("The learner said the card line correctly (the transcript may look a bit off because of their accent, that's fine). Count it as right and carry on, don't ask them to repeat it. ${praiseNote(false)}")
            }
            chatMisses++
            card = Turn(Turn.Role.CARD, current)
            return sendGuide(when (chatMisses) {
                1 -> "The learner's try at \"$current\" wasn't quite right (unless it's close; then count it as right). Quote what you heard kindly, give ONE concrete tip for the tricky sound, and show the same line again."
                2 -> "Second miss on \"$current\". Help differently: break it into small chunks and have them say it piece by piece slowly, or compare the tricky sound to a word in their native language. Show the same line again."
                else -> { chatMisses = 0; card = null; "Third miss on \"$current\". Celebrate the effort, cheerfully suggest a different one and show an easier or different sentence." }
            })
        }
        if (warmupPending) {
            warmupPending = false
            card = null
            val next = if (targetProgress < targets.size) nextPiece(targets[targetProgress]) else ROLEPLAY_START
            return sendGuide("They answered your warm-up question. React to what they said in ONE short sentence, then go straight into the first piece, with the setting folded into your question (e.g. \"At a party someone new says hi to you. How would you greet them?\"). Three sentences at most, and don't announce that you are moving on or setting a scene. $next")
        }
        val ok = current?.let { overlap(said, it) >= (if (answerCardsOnly) 0.25 else 0.6) } ?: true
            || (pendingPersonalize && words(said).size >= 2)
            || (answerCardsOnly && words(said).size >= 3)

        val note: String
        if (targetProgress < targets.size || pendingCombine || pendingPersonalize) {
            attempts++
            if (!ok && attempts < 3) {
                return sendGuide(if (attempts == 1)
                    "The learner's attempt wasn't quite right (if it only looks off because of their accent or a transcript slip, treat it as right and move on instead). Quote what you heard kindly (they said: '$said') in the language you are explaining in, not in English unless that is it, give ONE concrete tip for the tricky sound or word, and have them say the line again."
                else "Second miss on the same line (again: if it's close, count it as right). Help differently now: break the line into small chunks and have them say it piece by piece slowly, or compare the tricky sound to a word in their native language, then let them try the whole line once more. Show the same line.")
            }
            val before = attempts
            attempts = 0
            card = null
            val praise = if (ok) praiseNote(before > 1)
                else "Three tries are enough for this line: celebrate the effort warmly, say cheerfully that you'll try a different one, and move on."
            note = when {
                pendingPersonalize -> { pendingPersonalize = false; advance(praise) }
                pendingCombine -> {
                    pendingCombine = false
                    if (targetProgress < targets.size) "$praise ${nextPiece(targets[targetProgress])}" else finishOrRoleplay(praise)
                }
                withRoleplay -> {
                    pendingPersonalize = true
                    "$praise Don't move on yet — make it theirs. ${PERSONALIZE_STYLES[personalizeIndex++ % PERSONALIZE_STYLES.size]} Your spoken turn must end with your question; then show a complete sample answer. Never reuse the wording or structure of your previous turn."
                }
                else -> advance(praise)
            }
        } else {
            roleplayTurns++
            card = null
            note = if (roleplayTurns < 6) {
                if (ok || said.length > 3)
                    "Stay in character: react to what they said, then SPEAK the other person's next line out loud, word for word in ${app.wordrem.android.data.lang(TutorBrain.targetCode).englishName} (e.g. \"Where are you from?\"). Never describe it instead (never \"now the person asks you...\"). Then show the LEARNER'S reply to that exact line."
                else "Stay in character but help them: give the reply they could use as the card and let them try."
            } else "End the roleplay warmly. Then step OUT of character and switch back to the learner's explaining language (their own language if they are a beginner) for the wrap-up. Like a real teacher, recap with 2–3 real-life example lines they can now use (quote them), celebrate in one sentence, and tell them clearly that this lesson is COMPLETE and next time a new lesson starts (never say you will continue from here). Say all of this OUT LOUD first, then call finish_lesson with success true. No new card."
        }
        sendGuide(note)
    }

    private fun advance(praise: String): String {
        targetProgress++
        if (withRoleplay && targetProgress >= 2 && targetProgress % 2 == 0) {
            pendingCombine = true
            return "$praise Now build on what they know: have them say one slightly longer line that combines their earlier phrases with this one, built from what THEY actually said (their real name, job, city…), not the example answers. Ask them to put it together out loud, then show that line."
        }
        if (targetProgress < targets.size && answerCardsOnly) {
            return "$praise Then, out loud, ${targets[targetProgress]}. Ask it directly, never announce it (no \"next up\", \"first let me offer you a choice\"). Your spoken turn MUST end with the question itself; only after asking it, call show_phrase."
        }
        if (targetProgress < targets.size) return "$praise ${nextPiece(targets[targetProgress])}"
        return finishOrRoleplay(praise)
    }

    private fun finishOrRoleplay(praise: String): String =
        if (!withRoleplay) "$praise That's the last piece — wrap up now: celebrate proudly what they just did, tell them their personal plan is ready, say a warm \"see you soon\" — say all of this OUT LOUD first, and only after speaking call finish_lesson with success true. No new card."
        else "$praise $ROLEPLAY_START"

    private fun nextPiece(target: String): String =
        if (target.lowercase().startsWith("ask"))
            "Next piece: $target. Here the LEARNER asks the question: play the other person in the scene, say one short line about yourself, then invite them, in your own words, to ask you. Show the learner's QUESTION (e.g. \"What do you do?\"), not an answer."
        else "Next piece: $target. Bring it in as a real mini-exchange in the scene: set up the moment in a few words, then ASK the learner the natural question out loud (the way a real person would) — your spoken turn MUST end with that question (never just \"let's move on\"). Only then show the learner's answer as a complete, natural sentence. Only a real either/or choice gets two options separated by \" / \"."

    fun end() {
        if (phase == Phase.ENDED) return
        if (phase == Phase.LISTENING) recorder.stop()
        phase = Phase.ENDED
        engine?.close(); engine = null
        player.flush()
        val id = sessionId
        val secs = ((System.currentTimeMillis() - startedAt) / 1000).toInt()
        if (id != null && startedAt > 0) {
            if (secs >= 30) Store.markStudiedToday()
            CoroutineScope(Dispatchers.IO).launch { VoiceBackend.reportUsage(id, secs) }
        }
    }

    fun release() {
        end()
        player.release()
        main.cancel()
    }

    private fun ev(type: String) = JSONObject().put("type", type)

    private companion object {
        val PERSONALIZE_STYLES = listOf(
            "Teach ONE useful new word or phrase that fits what they just said (with a tiny example), then ask about their real life so they use it.",
            "Ask a curious follow-up about THEIR real life (why, when, with whom, how often) so they say their own version; no new vocabulary lecture this time.",
            "Ask a natural either/or question about their life that fits what they said (two real options), so they pick one and say it.",
            "React to what they said with a short personal comment of your own, then ask them a natural follow-up question so they extend their answer with one more detail.",
        )
        const val ROLEPLAY_START = "Time for a real-life roleplay that fits the lesson scene (e.g. you are the check-in agent or a new friend at a party). Set the scene in one short sentence (in the learner's explaining language), then switch to character and SPEAK the other person's first line out loud, word for word in the target language, short and simple (never describe it instead, never \"now the person greets you\"), and only then call show_phrase with the LEARNER'S reply — never your own line. Example: you say \"Hi, I'm Emma. What's your name?\" → card \"Nice to meet you, Emma! I'm Ahmet.\""
        const val NOTE_LANGUAGE = " (This note is private stage direction: never describe it or announce your plan to the learner, just DO it in your next turn. Any quoted wording is only an English example of the idea: say it in your own words, in the language you are speaking to the learner right now.)"
    }
}
