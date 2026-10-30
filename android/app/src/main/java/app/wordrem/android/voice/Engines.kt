package app.wordrem.android.voice

import android.util.Base64
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

const val TAG = "WordRemVoice"

/**
 * Ses motoru: oturum (TutorSession) motordan bağımsız olarak OpenAI Realtime olaylarıyla konuşur
 * ("response.output_audio.delta", "response.function_call_arguments.done" …). iOS'taki gibi Gemini bu olaylara çevrilir.
 * Bütün çağrılar ve teslimler ana iş parçacığındadır.
 */
interface VoiceEngine {
    fun start()
    /** Bas-konuş kaydı (PCM 24 kHz) commit'ten önce verilir */
    fun pushAudio(pcm: ByteArray)
    fun handle(e: JSONObject)
    fun close()
}

private fun ev(type: String) = JSONObject().put("type", type)

/** OpenAI Realtime, sunucunun sayaçlı aktarıcısı üzerinden (Gemini kapalıysa ya da açılamazsa) */
class RealtimeEngine(
    private val sessionId: String,
    private val deliver: (JSONObject) -> Unit,
) : VoiceEngine {
    private val main = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var socket: WebSocket? = null
    private var closed = false

    override fun start() {
        socket = VoiceBackend.openSocket("v1/voice/realtime", sessionId, object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) {
                main.launch { runCatching { JSONObject(text) }.getOrNull()?.let(deliver) }
            }
            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                main.launch { if (!closed) deliver(ev(if (code == 4001) "engine.time_up" else "engine.failed")) }
            }
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "realtime socket failed", t)
                main.launch { if (!closed) deliver(ev("engine.failed")) }
            }
        })
    }

    override fun pushAudio(pcm: ByteArray) {
        // 32 KB'lık parçalar hâlinde (tek mesaj sınırına takılmasın)
        var i = 0
        while (i < pcm.size) {
            val end = minOf(pcm.size, i + 32_000)
            send(ev("input_audio_buffer.append").put("audio", Base64.encodeToString(pcm.copyOfRange(i, end), Base64.NO_WRAP)))
            i = end
        }
    }

    override fun handle(e: JSONObject) = send(e)

    private fun send(e: JSONObject) { socket?.send(e.toString()) }

    override fun close() {
        closed = true
        socket?.close(1000, null)
        socket = null
        main.cancel()
    }
}

/**
 * Gemini Live (iOS'taki varsayılan motor): öğrencinin sesi önce sunucuda yazıya çevrilir, ders notlarıyla
 * aynı mesajda gönderilir; cevap Gemini'nin kendi sesiyle akar. Model, ses ve talimat sunucuda ayarlanır.
 */
class GeminiEngine(
    private val sessionId: String,
    private val tools: JSONArray,
    private val targetLang: () -> String,
    private val nativeLang: String,
    private val deliver: (JSONObject) -> Unit,
) : VoiceEngine {
    private val main = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var socket: WebSocket? = null
    private val audio = ByteArrayOutputStream()
    private val pending = mutableListOf<String>()
    private var sttJob: Job? = null
    private var inResponse = false
    private var dropping = false
    private var started = false
    private var ready = false
    private var closed = false
    private var spoken = StringBuilder()
    private val heldCalls = mutableListOf<JSONObject>()
    private var nudged = false
    private var resumeHandle: String? = null
    private var reconnects = 0
    private var reconnectAfterTurn = false

    override fun start() {
        open()
        // Birkaç saniyede açılmazsa oturum realtime ile sürer (kullanıcı beklemesin)
        main.launch {
            delay(8_000)
            if (!ready && !closed) {
                Log.e(TAG, "gemini setup timed out → realtime fallback")
                close()
                deliver(ev("engine.unavailable"))
            }
        }
    }

    private fun open() {
        val old = socket
        socket = VoiceBackend.openSocket("v1/voice/gemini", sessionId, object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) = onText(webSocket, text)
            override fun onMessage(webSocket: WebSocket, bytes: ByteString) = onText(webSocket, bytes.utf8())
            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                main.launch {
                    if (webSocket !== socket || closed) return@launch
                    Log.e(TAG, "gemini closed $code $reason")
                    if (code == 4001) deliver(ev("engine.time_up")) else if (ready) reconnect()
                }
            }
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "gemini socket failed", t)
                main.launch { if (webSocket === socket && !closed && ready) reconnect() }
            }
        })
        old?.close(1000, null)
        val decls = JSONArray()
        for (i in 0 until tools.length()) {
            val t = tools.getJSONObject(i)
            decls.put(JSONObject().put("name", t.getString("name")).put("description", t.optString("description"))
                .put("parameters", geminiSchema(t.getJSONObject("parameters"))))
        }
        send(JSONObject().put("setup", JSONObject()
            .put("model", "")
            .put("generationConfig", JSONObject().put("responseModalities", JSONArray().put("AUDIO")))
            .put("tools", JSONArray().put(JSONObject().put("functionDeclarations", decls)))
            .put("realtimeInputConfig", JSONObject().put("automaticActivityDetection", JSONObject().put("disabled", true)))
            .put("outputAudioTranscription", JSONObject())
            .put("sessionResumption", resumeHandle?.let { JSONObject().put("handle", it) } ?: JSONObject())))
    }

    private fun onText(ws: WebSocket, text: String) {
        main.launch {
            if (ws !== socket || closed) return@launch
            runCatching { JSONObject(text) }.getOrNull()?.let(::handleServer)
        }
    }

    /** Google bağlantıyı ~10 dk'da bir kapatır: kaldığı yerden yeni bağlantı (en fazla 3 kez üst üste) */
    private fun reconnect() {
        if (closed) return
        if (resumeHandle == null || reconnects >= 3) { deliver(ev("engine.failed")); return }
        reconnects++
        inResponse = false; dropping = false; spoken.clear()
        open()
    }

    private fun send(obj: JSONObject) { socket?.send(obj.toString()) }

    /** JSON şema tiplerini Gemini biçimine çevirir ("string" → "STRING") */
    private fun geminiSchema(v: Any): Any = when (v) {
        is JSONObject -> JSONObject().also { out ->
            v.keys().forEach { k ->
                if (k == "additionalProperties" || k == "\$schema") return@forEach
                val value = v.get(k)
                out.put(k, if (k == "type" && value is String) value.uppercase() else geminiSchema(value))
            }
        }
        is JSONArray -> JSONArray().also { out -> for (i in 0 until v.length()) out.put(geminiSchema(v.get(i))) }
        else -> v
    }

    private fun beginResponseIfNeeded() {
        if (inResponse) return
        inResponse = true
        deliver(ev("response.created"))
    }

    private fun handleServer(m: JSONObject) {
        m.optJSONObject("sessionResumptionUpdate")?.let { upd ->
            if (upd.optBoolean("resumable")) upd.optString("newHandle").takeIf { it.isNotEmpty() }?.let { resumeHandle = it }
            return
        }
        if (m.has("goAway")) {
            if (inResponse) reconnectAfterTurn = true else reconnect()
            return
        }
        if (m.has("setupComplete")) {
            if (ready) { reconnects = 0; return }
            ready = true
            deliver(ev("session.created"))
            return
        }
        m.optJSONObject("toolCall")?.let { tc ->
            beginResponseIfNeeded()
            val calls = tc.optJSONArray("functionCalls") ?: JSONArray()
            for (i in 0 until calls.length()) {
                val c = calls.getJSONObject(i)
                val id = c.optString("id")
                val name = c.optString("name")
                // Kart, öğretmen sözünü bitirince gösterilir; Gemini beklemesin diye cevap hemen gider
                heldCalls += ev("response.function_call_arguments.done").put("name", name).put("call_id", id)
                    .put("arguments", (c.optJSONObject("args") ?: JSONObject()).toString())
                send(JSONObject().put("toolResponse", JSONObject().put("functionResponses", JSONArray().put(
                    JSONObject().put("id", id).put("name", name).put("response", JSONObject().put("result", "ok")).put("scheduling", "SILENT")))))
            }
            return
        }
        val sc = m.optJSONObject("serverContent") ?: return
        sc.optJSONObject("modelTurn")?.optJSONArray("parts")?.let { parts ->
            for (i in 0 until parts.length()) {
                val b64 = parts.getJSONObject(i).optJSONObject("inlineData")?.optString("data") ?: continue
                if (dropping || b64.isEmpty()) continue
                beginResponseIfNeeded()
                deliver(ev("response.output_audio.delta").put("delta", b64))
            }
        }
        sc.optJSONObject("outputTranscription")?.optString("text")?.takeIf { it.isNotEmpty() && !dropping }?.let { t ->
            beginResponseIfNeeded()
            spoken.append(t)
            deliver(ev("response.output_audio_transcript.delta").put("delta", t))
        }
        if (sc.optBoolean("turnComplete")) {
            if (spoken.isEmpty() && heldCalls.isNotEmpty() && !nudged) {
                // Yalnızca kart açıp sustu: söylemesi gerekeni sesli söylesin
                nudged = true
                sendTurn(listOf("[Private note from the app: the card is ready, but you said nothing out loud. Now say your turn out loud (what you planned, ending with your question). Do not call show_phrase again.]"))
                return
            }
            nudged = false
            heldCalls.forEach(deliver); heldCalls.clear()
            spoken.clear()
            dropping = false
            if (reconnectAfterTurn) { reconnectAfterTurn = false; reconnect() }
            if (!inResponse) return
            inResponse = false
            deliver(ev("response.output_audio.done"))
            deliver(ev("response.done"))
        }
    }

    private fun sendTurn(parts: List<String>) {
        val p = JSONArray().apply { parts.forEach { put(JSONObject().put("text", it)) } }
        send(JSONObject().put("clientContent", JSONObject()
            .put("turns", JSONArray().put(JSONObject().put("role", "user").put("parts", p)))
            .put("turnComplete", true)))
    }

    override fun pushAudio(pcm: ByteArray) { audio.reset(); audio.write(pcm) }

    override fun handle(e: JSONObject) {
        if (closed) return
        when (e.optString("type")) {
            "input_audio_buffer.clear" -> audio.reset()
            "input_audio_buffer.commit" -> {
                val pcm = audio.toByteArray(); audio.reset()
                sttJob = main.launch {
                    val t = transcribeLearner(pcm).trim()
                    if (closed) return@launch
                    if (t.isNotEmpty()) pending += t
                    deliver(ev("conversation.item.input_audio_transcription.completed").put("transcript", t))
                }
            }
            "conversation.item.create" -> {
                val item = e.optJSONObject("item") ?: return
                if (item.optString("type") == "function_call_output") return   // araç cevabı zaten verildi
                val content = item.optJSONArray("content") ?: JSONArray()
                val text = (0 until content.length()).mapNotNull { content.getJSONObject(it).optString("text").takeIf { s -> s.isNotEmpty() } }
                    .joinToString("\n")
                if (text.isEmpty()) return
                if (item.optString("role") == "system") {
                    pending += "[Private note from the app, never read aloud or mention it: $text]"
                } else {
                    pending += text
                }
            }
            "response.create" -> {
                main.launch {
                    sttJob?.join()
                    if (closed) return@launch
                    val parts = if (pending.isEmpty())
                        listOf(if (started) "(Go on.)" else "(The call starts now. Do your opening turn: speak first, end with your question said out loud, and only then show the card.)")
                    else pending.toList()
                    started = true
                    pending.clear()
                    dropping = false
                    sendTurn(parts)
                }
            }
            "response.cancel" -> if (inResponse) dropping = true
        }
    }

    /** Aksan yüzünden başka bir dil sanıldıysa (ör. Latin yerine Kiril) bir kez öğrenilen dil zorlanarak tekrar */
    private suspend fun transcribeLearner(pcm: ByteArray): String {
        val first = VoiceBackend.transcribe(sessionId, pcm)
        if (!isStrayScript(first)) return first
        val second = VoiceBackend.transcribe(sessionId, pcm, targetLang())
        return second.ifEmpty { first }
    }

    private fun scriptOf(code: String) = when (code) { "ru" -> 'C'; "zh" -> 'H'; else -> 'L' }
    private fun isStrayScript(text: String): Boolean {
        val letters = text.filter { it.isLetter() }
        if (letters.length < 3) return false
        val allowed = setOf(scriptOf(targetLang()), scriptOf(nativeLang))
        val counts = letters.groupingBy { c ->
            when (Character.UnicodeScript.of(c.code)) {
                Character.UnicodeScript.CYRILLIC -> 'C'
                Character.UnicodeScript.HAN -> 'H'
                Character.UnicodeScript.LATIN -> 'L'
                else -> 'X'
            }
        }.eachCount()
        val top = counts.maxByOrNull { it.value }?.key ?: return false
        return top !in allowed
    }

    override fun close() {
        closed = true
        sttJob?.cancel()
        socket?.close(1000, null)
        socket = null
        main.cancel()
    }
}
