//
//  RealtimeVoiceSession.swift
//  WordRemSwiftUI
//
//  Sesli öğretmen motoru. Akış:
//   1) VoiceBackend'den kısa ömürlü OpenAI anahtarı + izin verilen süre alınır (dakika sınırı sunucuda).
//   2) OpenAI Realtime'a WebSocket ile bağlanılır; mikrofon 24 kHz PCM16 olarak akıtılır.
//   3) AI'ın sesi akış halinde çalınır, altyazı çalınan sesle aynı hızda açılır.
//   4) AI'ın araç çağrıları (ifade kartı göster, kelimeyi kullandı…) `onToolCall` ile uygulamaya iletilir.
//  Pingo gibi her zaman bas-konuş: basılı tut → konuş → bırak → gönder. Mikrofon kendiliğinden dinlemez,
//  böylece AI kendi sesini duyup kendine cevap vermez.
//

import AVFoundation
import UIKit
import NaturalLanguage
import Foundation
import os

let voiceLog = Logger(subsystem: "com.twinflare.WordRemSwiftUI", category: "voice")

@MainActor
final class RealtimeVoiceSession: ObservableObject {

    enum Phase: Equatable {
        case idle, connecting, listening, userSpeaking, thinking, aiSpeaking, ended
        case failed(String)
    }

    struct Turn: Identifiable, Equatable {
        enum Role { case ai, user, card }
        let id = UUID()
        let role: Role
        var text: String
        /// Kartlarda çeviri
        var detail: String? = nil
    }

    // MARK: - Published
    @Published private(set) var phase: Phase = .idle {
        didSet {
            // Bağlanamadı / süre-limit: oturum özetiyle birlikte analitiğe
            guard case .failed(let code) = phase, oldValue != phase else { return }
            trackLesson(code == "paywall" || code == "limit_reached" ? "limit_hit" : "connect_fail", ["error_code": code])
        }
    }
    /// Analitik için dersin kimliği (mode, lesson_id, topic…); VoiceTutorView doldurur
    var analyticsContext: [String: Any?] = [:]
    private var connectStartedAt: Date?
    private var reconnectCount = 0
    private var lessonTracked = false
    /// Bağlanamayınca ekranda küçük yazıyla gösterilen teknik ayrıntı
    @Published private(set) var errorDetail: String?
    private var lastSocketError: String?
    /// Şu anki AI konuşmasının ekranda görünen kısmı (sesle senkron açılır)
    @Published private(set) var caption: String = ""
    /// Şu anki AI cevabının tamamı (altyazıda sıradaki kelimeyi soluk göstermek için)
    @Published private(set) var captionFull: String = ""
    /// Her yeni AI cevabında artar (ekrandaki kartı kaldırmak için)
    @Published private(set) var responseCount = 0
    /// Ders hedeflerinde ilerleme (uygulama yönetir; model takılsa da ders ilerler)
    @Published private(set) var targetProgress = 0
    @Published private(set) var targetTotal = 0
    @Published private(set) var lessonComplete = false
    /// Ders özeti için: doğru / toplam cevap, başlangıç zamanı
    /// Son cevabın değerlendirmesi (kartta ✓ / sallanma için); her cevapta `answerCount` artar
    @Published private(set) var lastAnswerCorrect = false
    @Published private(set) var answerCount = 0
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalAnswers = 0
    private(set) var startedAt = Date()
    /// Son kelimenin ekrana geldiği an (yumuşak belirme için)
    @Published private(set) var captionChangedAt = Date()
    /// Tüm konuşma (Transkript çekmecesi için)
    @Published private(set) var turns: [Turn] = []
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var allowedSeconds: Int = 0
    /// Günlük süre doldu: AI vedalaşıyor, ardından paywall
    @Published private(set) var timeUp = false
    /// Bas-konuş modu (ifade kartı tekrarında)
    @Published private(set) var pushToTalk = true
    @Published private(set) var isHoldingToTalk = false
    /// Giriş ses seviyesi 0…1 (dinleme animasyonu için)
    @Published private(set) var inputLevel: Float = 0

    /// AI bir araç çağırdığında: (ad, JSON argümanlar) → çıktı metni
    var onToolCall: ((String, [String: Any]) -> String)?
    var onLimitReached: (() -> Void)?
    /// Her değerlendirilen cevap: (kart, doğru mu) — tekrar planını beslemek için
    var onAnswer: ((String, Bool) -> Void)?

    // MARK: - Private
    private var socket: URLSessionWebSocketTask?
    private var sessionId: String?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let outFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false)!
    private let wireFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24_000, channels: 1, interleaved: false)!
    private var converter: AVAudioConverter?
    private var micMuted = true { didSet { tapState.set(stream: !micMuted) } }
    /// Ses iş parçacığının okuduğu durum (mikrofon akışı açık mı, hangi sokete)
    private let tapState = TapState()
    private var holdStartedAt: Date?
    /// AI konuşurken (ve bitişinden kısa süre sonra) mikrofon sunucuya gitmez:
    /// hoparlörden çıkan ses mikrofona geri girip "kullanıcı konuştu" sanılmasın.
    private var echoGuardUntil = Date.distantPast
    private var aiAudible: Bool { scheduledSamples > 0 || Date() < echoGuardUntil }

    private var fullAIText = ""            // gelen transkript (sesten önde), temizlenmiş
    private var rawAIText = ""             // modelin ham metni
    private var phraseShownThisResponse = false
    private var scheduledSamples: Double = 0
    private var playbackStart: AVAudioTime?
    /// Ses motoru durursa altyazı yine ilerlesin diye duvar saati yedeği
    private var playbackWallStart: Date?
    private var audioObservers: [NSObjectProtocol] = []
    private var captionTimer: Timer?
    private var clock: Timer?
    private var lastUsageReport = 0
    private var wallSeconds = 0
    private var warnedTimeUp = false
    private var timeUpAt: Date?
    private var currentUserTurnId: UUID?

    // MARK: - Lifecycle
    /// - Parameter targets: ders hedefleri (sırayla); boşsa serbest sohbet
    /// - Parameter roleplay: hedefler bitince canlandırma yapılsın mı (onboarding demosunda hayır)
    func start(instructions: String, tools: [[String: Any]], targets: [String] = [], startStep: Int = 0, roleplay: Bool = true,
               aiSpeaksFirst: Bool = true) async {
        self.aiSpeaksFirst = aiSpeaksFirst
        self.targets = targets
        lastInstructions = instructions; lastTools = tools; usageBase = 0
        #if DEBUG
        // Geliştirirken AI'a giden tam talimatı incelemek için
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? instructions.write(to: dir.appendingPathComponent("prompt-\(targets.isEmpty ? "chat" : "lesson").txt"), atomically: true, encoding: .utf8)
        }
        #endif
        self.withRoleplay = roleplay
        self.cardTool = tools.first { $0["name"] as? String == "show_phrase" }
        targetTotal = targets.count
        targetProgress = min(startStep, targets.count); attempts = 0; roleplayTurns = 0; lessonComplete = false; pendingPersonalize = false
        pendingCombine = false; correctAnswers = 0; totalAnswers = 0; startedAt = Date()
        guard phase == .idle || phase == .ended || { if case .failed = phase { return true }; return false }() else { return }
        phase = .connecting
        connectStartedAt = Date(); reconnectCount = 0; lessonTracked = false
        errorDetail = nil; lastSocketError = nil
        turns = []; caption = ""; elapsedSeconds = 0; lastUsageReport = 0; wallSeconds = 0; warnedTimeUp = false; timeUp = false; timeUpAt = nil
        trackLesson("start")
        do {
            let grant = try await VoiceBackend.shared.createSession(instructions: instructions, tools: tools)
            sessionId = grant.sessionId
            allowedSeconds = grant.allowedSeconds
            Track.setTier(grant.tier)
            // İzin penceresi ses motorunu yarıda kesmesin: önce izni al
            _ = await AVAudioApplication.requestRecordPermission()
            try configureAudio()
            connect(model: grant.model, secret: grant.clientSecret)
            startClock()
        } catch let e as VoiceBackend.Failure {
            errorDetail = "http \(e.code)"
            phase = .failed(e.code)
        } catch {
            errorDetail = await VoiceBackend.shared.diagnose(error)
            phase = .failed("network")
        }
    }

    /// Ders özeti: ne kadar konuştu, ne kadar doğru, dersin neresinde
    private func trackLesson(_ action: String, _ extra: [String: Any?] = [:]) {
        let userTurns = turns.filter { $0.role == .user && !$0.text.isEmpty }.count
        let stage: String = lessonComplete ? "done"
            : userTurns == 0 ? "warmup"
            : (!targets.isEmpty && targetProgress >= targets.count) ? "roleplay" : "teaching"
        var params: [String: Any?] = analyticsContext
        params["target_lang"] = Self.currentTarget
        params["duration_sec"] = elapsedSeconds
        params["user_turns"] = userTurns
        params["answers"] = totalAnswers
        params["correct"] = correctAnswers
        params["accuracy_pct"] = totalAnswers > 0 ? correctAnswers * 100 / totalAnswers : nil
        params["progress_pct"] = targetTotal > 0 ? targetProgress * 100 / targetTotal : nil
        params["stage"] = stage
        params["via_relay"] = viaRelay
        params["reconnects"] = reconnectCount
        params["error_detail"] = errorDetail
        Track.lesson(action, params.merging(extra) { _, new in new })
    }

    func stop() {
        guard phase != .ended else { return }
        if !lessonTracked, phase != .connecting, phase != .idle, { if case .failed = phase { return false }; return true }() {
            lessonTracked = true
            trackLesson(lessonComplete ? "complete" : timeUp ? "time_up" : "exit")
        }
        reportUsage(final: true)
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        tapState.set(socket: nil)
        clock?.invalidate(); captionTimer?.invalidate()
        audioObservers.forEach(NotificationCenter.default.removeObserver)
        audioObservers = []
        player.stop()
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        caption = fullAIText; captionFull = fullAIText
        phase = .ended
    }

    // MARK: - Push to talk (ifade kartı)
    /// Kart modunda sunucu ses algılaması kapanır; kullanıcı basılı tutarken kaydedilir.
    func setPushToTalk(_ on: Bool) {
        guard pushToTalk != on else { return }
        pushToTalk = on
        let detection: Any = on ? NSNull()
            : ["type": "semantic_vad", "eagerness": "medium", "create_response": true, "interrupt_response": true]
        send(["type": "session.update", "session": ["type": "realtime", "audio": ["input": ["turn_detection": detection]]]])
        micMuted = on
    }

    func beginHold() {
        guard pushToTalk, socket != nil else { return }
        if !micTapInstalled {
            installMicTap(retries: 0)
            if !engine.isRunning { try? engine.start() }
        }
        if phase == .aiSpeaking || phase == .thinking { send(["type": "response.cancel"]) }
        stopPlayback()
        send(["type": "input_audio_buffer.clear"])
        holdStartedAt = Date()
        micMuted = false
        isHoldingToTalk = true
        phase = .userSpeaking
    }

    func endHold() {
        guard pushToTalk, isHoldingToTalk else { return }
        isHoldingToTalk = false
        micMuted = true
        // Çok kısa basış: boş ses gönderme (sunucu hata verir)
        if let start = holdStartedAt, Date().timeIntervalSince(start) < 0.2 {
            send(["type": "input_audio_buffer.clear"])
            phase = .listening
            return
        }
        let stats = tapState.takeStats()
        voiceLog.info("mic sent \(stats.bytes, privacy: .public) bytes, peak level \(stats.peak, privacy: .public), format \(self.engine.inputNode.outputFormat(forBus: 0).description, privacy: .public)")
        voiceLog.info("hold released after \(Date().timeIntervalSince(self.holdStartedAt ?? Date()), privacy: .public)s → commit")
        send(["type": "input_audio_buffer.commit"])
        phase = .thinking
        // Cevabı, ne söylendiği yazıya dökülünce iste (ders yönlendirmesi için). Uzun cümlenin yazıya dökülmesi
        // daha uzun sürer: bekleme konuşma süresiyle büyür (3–6 sn); yoksa öğretmen yazı gelmeden cevap verip karışıyor.
        let spoken = Date().timeIntervalSince(holdStartedAt ?? Date())
        let wait = min(6, max(3, 2.5 + spoken * 0.5))
        awaitingReply = true
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
            guard let self, self.awaitingReply else { return }
            self.awaitingReply = false
            self.send(["type": "response.create"])
        }
    }

    /// Ekranda gösterilen kartı transkripte ekle
    func appendCard(_ phrase: String, translation: String) {
        turns.append(Turn(role: .card, text: phrase, detail: translation.isEmpty ? nil : translation))
    }

    /// Sonradan gelen çeviriyi transkriptteki karta da yaz
    func updateCardTranslation(_ phrase: String, translation: String) {
        if let i = turns.lastIndex(where: { $0.role == .card && $0.text == phrase }) { turns[i].detail = translation }
    }

    // MARK: - Ders yönlendirme
    private var targets: [String] = []
    private var chatMisses: (card: String?, count: Int) = (nil, 0)
    private var currentCard: String?
    private var attempts = 0
    private var roleplayTurns = 0
    private var pendingCombine = false
    /// Parçanın ikinci aşaması: öğrenci cümleyi kendine uyarlar (yeni kelimelerle) — ders aceleye gelmesin
    private var pendingPersonalize = false
    private var withRoleplay = true
    private var awaitingReply = false

    /// Öğrencinin söylediğine göre öğretmene bir sonraki adımı söyler (Pingo tarzı: yeni parça → birleştir → yeni parça…).
    /// Sıralama arka planda; öğretmen bunu "adım" diye anlatmaz.
    private func guide(after said: String) {
        // Serbest sohbet (hedef yok): konu/soru değiştirmek isterse hemen değiştir
        if targets.isEmpty, !noCards, Self.wantsToSkip(said) {
            voiceLog.info("learner asked to change topic")
            Track.tutor("skip_request", mode: (analyticsContext["mode"] as? String) ?? "free_chat")
            return sendGuide("The learner wants a different question or topic. Happily switch right away, never push back or say \"let's focus\": offer two fresh, fun topics (or ask a completely different question) and follow their choice.")
        }
        // Serbest sohbette ders akışı yok ama karttaki cümleyi söyleyince yine ✓ yansın
        if targets.isEmpty, let card = currentCard, !said.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let ok = Self.matches(said: said, card: card) || Self.overlap(said: said, card: card) >= 0.6
                || (Self.isTargetLanguage(said) && said.split(separator: " ").count >= 3)
            totalAnswers += 1
            if ok { correctAnswers += 1 }
            lastAnswerCorrect = ok
            answerCount += 1
            onAnswer?(card, ok)
            currentCard = nil
            if ok {
                chatMisses = (nil, 0)
                return sendGuide("The learner said the card line correctly (the transcript may look a bit off because of their accent, that's fine). Count it as right: praise it briefly and carry on, don't ask them to repeat it.")
            }
            // Aynı cümlede üst üste kaçırma: 1 ipucu → parça parça yardım → başka cümle
            chatMisses = chatMisses.card == card ? (card, chatMisses.count + 1) : (card, 1)
            switch chatMisses.count {
            case 1: return sendGuide("The learner's try at \"\(card)\" wasn't quite right (unless it's close; then count it as right). Quote what you heard kindly, give ONE concrete tip for the tricky sound, and show the same line again.")
            case 2: return sendGuide("Second miss on \"\(card)\". Help differently: break it into small chunks and have them say it piece by piece slowly, or compare the tricky sound to a word in their native language. Show the same line again.")
            default:
                chatMisses = (nil, 0)
                return sendGuide("Third miss on \"\(card)\". Celebrate the effort, cheerfully suggest a different one and show an easier or different sentence.")
            }
        }
        guard !targets.isEmpty, !lessonComplete else { return }
        // Hiçbir şey duyulmadı (çok kısa bastı / mikrofon sesi almadı): hata sayma, nazikçe tekrar iste
        if said.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sendGuide("You couldn't hear the learner this time (no words came through). Don't quote anything or count it as a mistake — say in a few playful words you didn't catch that, and ask them to say the line again.")
        }
        // Öğrenilen dilde, en az 3 kelimelik kendi cümlesi: soruya gerçek bir cevap (kart birebir uymasa da) → doğru say
        let wordCount = said.split(separator: " ").count
        let inTarget = Self.isTargetLanguage(said)
        // Öğrenci soruyu geçmek / konuyu değiştirmek istiyor: asla direnme, hemen sıradakine geç
        if Self.wantsToSkip(said) {
            voiceLog.info("learner asked to skip")
            Track.tutor("skip_request", mode: (analyticsContext["mode"] as? String) ?? "goal")
            attempts = 0
            currentCard = nil
            let next: String
            if pendingPersonalize || pendingCombine {
                pendingPersonalize = false; pendingCombine = false
                next = targetProgress < targets.count ? Self.nextPiece(targets[targetProgress]) : finishOrRoleplay("")
            } else if targetProgress < targets.count {
                targetProgress += 1
                next = targetProgress < targets.count ? Self.nextPiece(targets[targetProgress]) : finishOrRoleplay("")
            } else {
                next = "Switch to a different situation in the roleplay, one they'd enjoy more, and continue in character."
            }
            return sendGuide("The learner doesn't want this question and wants to move on. Happily agree in a few words, never push back or say \"let's focus\". \(next)")
        }
        // Karta hiç benzemeyen ve öğrenilen dilde olmayan sözler: sohbet/şaka → keyifle karşıla, derse dön
        if let card = currentCard, wordCount >= 3, !inTarget, Self.overlap(said: said, card: card) < 0.25 {
            let en = Locale(identifier: "en")
            let targetName = en.localizedString(forLanguageCode: Self.currentTarget) ?? "the target language"
            let nativeName = en.localizedString(forLanguageCode: OL.nativeLangCode) ?? "their native language"
            sendGuide("If the learner is asking to learn or practice a DIFFERENT language: reply in \(nativeName) in one or two short sentences — you'd love to teach that too, they can add it in a minute from the flag at the top of the home screen or practice it now in \"Talk with your assistant\" — then continue this \(targetName) lesson. Never say you only teach \(targetName). Otherwise:")
            return sendGuide("The learner answered in their own words instead of saying the card line (a reply like \"yes, I'm ready\", a question, a joke or a side comment). React naturally to what they actually said (answer a question, laugh at a joke), then invite them to try the current line. Don't treat it as a mistake, and if they seem to want something else, give it to them.")
        }
        // Demoda kart yalnızca örnek cevap: kendi bilgisini söyleyen ("I'm a morning person") doğru sayılır
        let ok = currentCard.map { Self.matches(said: said, card: $0) || Self.overlap(said: said, card: $0) >= (answerCardsOnly ? 0.25 : 0.6) } ?? !said.isEmpty
            || (inTarget && wordCount >= 3)
            || (pendingPersonalize && inTarget)   // kendi versiyonu: kartla birebir aynı olması beklenmez
        totalAnswers += 1
        if ok { correctAnswers += 1 }
        lastAnswerCorrect = ok
        answerCount += 1
        if let card = currentCard { onAnswer?(card, ok) }
        var note: String

        if targetProgress < targets.count || pendingCombine || pendingPersonalize {
            attempts += 1
            guard ok || attempts >= 3 else {
                note = attempts == 1
                    ? "The learner's attempt wasn't quite right (if it only looks off because of their accent or a transcript slip, treat it as right and move on instead). Quote what you heard kindly (they said: '\(said)') in the language you are explaining in, not in English unless that is it, give ONE concrete tip for the tricky sound or word, and have them say the line again."
                    : "Second miss on the same line (again: if it's close, count it as right). Help differently now: break the line into small chunks and have them say it piece by piece slowly, or compare the tricky sound to a word in their native language, then let them try the whole line once more. Show the same line."
                return sendGuide(note)
            }
            attempts = 0
            currentCard = nil
            let praise = ok ? "The learner got it right — react with a short, varied, genuine praise (never the same words twice)."
                            : "Three tries are enough for this line: celebrate the effort warmly, say cheerfully that you'll try a different one, and move on."
            if pendingPersonalize {
                // Kendi versiyonunu da söyledi → şimdi parça gerçekten bitti
                pendingPersonalize = false
                note = advance(praise)
            } else if pendingCombine {
                pendingCombine = false
                note = targetProgress < targets.count
                    ? "\(praise) \(Self.nextPiece(targets[targetProgress]))"
                    : finishOrRoleplay(praise)
            } else if withRoleplay {
                // Ders: model cümleyi söyledi → hemen geçme, kendi hayatına uyarlat ve 1–2 yeni kelime öğret
                pendingPersonalize = true
                note = "\(praise) Don't move on yet — make it theirs: teach 1–2 useful new words that fit this moment (say each one with a tiny example, e.g. \"you can also say 'painting' or 'hiking'\"), then ask them a natural follow-up question so they say their OWN version (their real life, using one of the new words if it fits). Your spoken turn must end with that question; then show a complete sample answer that uses one of the new words."
            } else {
                note = advance(praise)
            }
        } else {
            roleplayTurns += 1
            if roleplayTurns < 6 {
                note = ok || said.count > 3
                    ? "Stay in character: react naturally to what they said, then say the next line as the other person out loud, and show the LEARNER'S reply to it (never your own line)."
                    : "Stay in character but help them: give the reply they could use as the card and let them try."
            } else {
                note = "End the roleplay warmly. Then, like a real teacher, recap with 2–3 real-life example lines they can now use (quote them), celebrate in one sentence and say you'll continue next time. Say all of this OUT LOUD first, then call finish_lesson with success true. No new card."
                lessonComplete = true
            }
        }
        sendGuide(note)
    }

    /// Parça bitti: sıradaki parça, ara ara birleştirme, en sonda rol oyunu ya da kapanış
    private func advance(_ praise: String) -> String {
        targetProgress += 1
        if withRoleplay && targetProgress >= 2 && targetProgress % 2 == 0 {
            // Pingo gibi: öğrendiklerini birleştirip biraz daha uzun bir cümle kurdur
            pendingCombine = true
            return "\(praise) Now build on what they know: have them say one slightly longer line that combines their earlier phrases with this one, built from what THEY actually said (their real name, job, city…), not the example answers. Ask them to put it together out loud, then show that line."
        }
        if targetProgress < targets.count, answerCardsOnly {
            // Sohbet demosu: önce soruyu SESLİ sor, kart (olası cevaplar) ondan sonra
            return "\(praise) Then, out loud, \(targets[targetProgress]). Your spoken turn MUST end with the question itself; only after asking it, call show_phrase."
        }
        if targetProgress < targets.count { return "\(praise) \(Self.nextPiece(targets[targetProgress]))" }
        return finishOrRoleplay(praise)
    }

    private func finishOrRoleplay(_ praise: String) -> String {
        guard withRoleplay else {
            lessonComplete = true
            return "\(praise) That's the last piece — wrap up now: celebrate proudly what they just did, tell them their personal plan is ready, say a warm \"see you soon\" — say all of this OUT LOUD first, and only after speaking call finish_lesson with success true. No new card."
        }
        return "\(praise) \(Self.roleplayStart)"
    }

    /// Yeni parça: gerçek bir mini sohbet olarak (soru sesli, cevap kartta; doğal bir seçim varsa iki seçenek)
    private static func nextPiece(_ target: String) -> String {
        // Öğrencinin soru sorduğu parçalar ("ask what someone does"): kart öğrencinin SORUSU olur
        if target.lowercased().hasPrefix("ask") {
            return "Next piece: \(target). Here the LEARNER asks the question: play the other person in the scene, say one short line about yourself, then invite them to ask you (\"Now you ask me!\"). Show the learner's QUESTION (e.g. \"What do you do?\"), not an answer."
        }
        return "Next piece: \(target). Bring it in as a real mini-exchange in the scene: set up the moment in a few words, then ASK the learner the natural question out loud (the way a real person would) — your spoken turn MUST end with that question (never just \"let's move on\"). Only then show the learner's answer as a complete, natural sentence. Only a real either/or choice gets two options separated by \" / \"."
    }

    private static let roleplayStart = "Time for a real-life roleplay that fits the lesson scene (e.g. you are the check-in agent or a new friend at a party). Set the scene in a few words, then SAY OUT LOUD the other person's first line in character, and only then call show_phrase with the LEARNER'S reply — never your own line. Example: you say \"Hi, I'm Emma. What's your name?\" → card \"Nice to meet you, Emma! I'm Ahmet.\""

    /// Notlar İngilizce yazılı; model içindeki örnek kalıpları ("welcome back", "Sure, no problem!") aynen okumasın
    private static let noteLanguage = " (Any quoted wording in this note is only an English example of the idea: say it in your own words, in the language you are speaking to the learner right now.)"

    private func sendGuide(_ note: String) {
        voiceLog.info("guide: \(note, privacy: .public)")
        send(["type": "conversation.item.create",
              "item": ["type": "message", "role": "system", "content": [["type": "input_text", "text": note + Self.noteLanguage]]]])
    }

    private func guide(roleplay note: String) {
        voiceLog.info("guide: \(note, privacy: .public)")
        send(["type": "conversation.item.create",
              "item": ["type": "message", "role": "system", "content": [["type": "input_text", "text": note + Self.noteLanguage]]]])
    }

    /// Söylenen cümle öğrenilen dilde mi (ana dildeki sohbetten ayırmak için)
    static func isTargetLanguage(_ text: String) -> Bool {
        let target = Self.currentTarget
        let r = NLLanguageRecognizer()
        r.processString(text)
        guard let lang = r.dominantLanguage?.rawValue else { return false }
        return lang.hasPrefix(target)
    }

    /// Kart açıkça başka bir dilde mi? (kısa ifadelerde tahmin şaşabilir: yalnızca emin olunca "evet")
    nonisolated static func isClearlyOtherLanguage(_ text: String) -> Bool {
        guard text.split(separator: " ").count >= 3 else { return false }
        let r = NLLanguageRecognizer()
        r.processString(text)
        let hyp = r.languageHypotheses(withMaximum: 3)
        guard let top = hyp.max(by: { $0.value < $1.value }), top.value > 0.8 else { return false }
        let target = Self.currentTarget
        return !top.key.rawValue.hasPrefix(target) && (hyp[NLLanguage(target)] ?? 0) < 0.1
    }

    /// "A / B" biçimindeki kartın seçenekleri
    nonisolated static func cardOptions(_ card: String) -> [String] {
        card.components(separatedBy: " / ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// Karttaki kelimelerin ne kadarı söylendi (0…1)
    nonisolated static func overlap(said: String, card: String) -> Double {
        let options = cardOptions(card)
        if options.count > 1 { return options.map { overlap(said: said, card: $0) }.max() ?? 0 }
        let a = Set(said.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { $0.count > 1 })
        let b = card.lowercased().replacingOccurrences(of: "...", with: " ")
            .components(separatedBy: CharacterSet.letters.inverted).filter { $0.count > 1 }
        guard !b.isEmpty else { return 1 }
        return Double(b.filter { a.contains($0) }.count) / Double(b.count)
    }

    /// Söylenen, karttaki cümleyle yeterince örtüşüyor mu ("..." yerleri serbest; Ahmed≈Ahmet gibi küçük farklar sayılmaz)
    nonisolated static func matches(said: String, card: String) -> Bool {
        // Seçenekli kart ("I love coffee. / I love tea."): herhangi biri yeter
        let options = cardOptions(card)
        if options.count > 1 { return options.contains { matches(said: said, card: $0) } }
        let contractions = ["i'm": "i am", "you're": "you are", "it's": "it is", "what's": "what is",
                            "i'd": "i would", "don't": "do not", "can't": "cannot", "let's": "let us"]
        func words(_ s: String) -> [String] {
            var t = s.lowercased().replacingOccurrences(of: "’", with: "'")
            for (k, v) in contractions { t = t.replacingOccurrences(of: k, with: v) }
            return t.components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'")).inverted)
                .filter { !$0.isEmpty }
        }
        func close(_ a: String, _ b: String) -> Bool {
            if a == b { return true }
            let x = Array(a), y = Array(b)
            guard abs(x.count - y.count) <= 2, max(x.count, y.count) >= 4 else { return false }
            var prev = Array(0...y.count)
            for i in 1...x.count {
                var cur = [i] + Array(repeating: 0, count: y.count)
                for j in 1...y.count { cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1)) }
                prev = cur
            }
            return prev[y.count] <= max(1, x.count / 4)
        }
        let expected = words(card.replacingOccurrences(of: "...", with: " ").replacingOccurrences(of: "…", with: " "))
        guard !expected.isEmpty else { return true }
        let heard = words(said)
        let hit = expected.filter { e in heard.contains { close($0, e) } }.count
        return Double(hit) / Double(expected.count) >= 0.5
    }

    /// AI konuşurken ekrana dokununca sözünü kes (mikrofon AI konuşurken kapalı olduğundan sesle kesilemez)
    func interrupt() {
        guard phase == .aiSpeaking || phase == .thinking else { return }
        stopPlayback()
        send(["type": "response.cancel"])
        send(["type": "input_audio_buffer.clear"])
        phase = .listening
    }

    /// "Takıldın mı?": öğretmen son söylediğini yavaşça tekrarlar ya da ana dilde yeniden açıklar
    func requestHelp(slower: Bool) {
        if phase == .aiSpeaking || phase == .thinking { interrupt() }
        guard phase == .listening else { return }
        let native = Locale(identifier: "en").localizedString(forLanguageCode: OL.nativeLangCode) ?? "the learner's native language"
        sendGuide(slower
            ? "The learner tapped 'repeat more slowly'. Say your last line again, slowly and very clearly, with small pauses between words. Then show the same card again with show_phrase."
            : "The learner tapped 'explain again' — they're stuck. In \(native), explain simply what the current line means and when to use it (1–2 short sentences), say it once more slowly in the target language, and show the same card again with show_phrase.")
        send(["type": "response.create"])
        phase = .thinking
    }

    /// Asistanla sohbette konu seçildi: öğretmen o konuya geçer
    func startTopic(display: String, topic: String) {
        if phase == .aiSpeaking || phase == .thinking { interrupt() }
        guard phase == .listening else { return }
        turns.append(Turn(role: .user, text: "→ \(display)"))
        sendGuide("The learner picked a topic: \(topic). Switch to it now: one warm line about the topic, then start a natural, step-by-step conversation around it — ask them something real and show their answer.")
        send(["type": "response.create"])
        phase = .thinking
    }

    /// Kullanıcı yazıyla bir şey göndermek isterse (ör. konu seçimi çipleri)
    func sendText(_ text: String) {
        guard phase == .listening else { return }
        send(["type": "conversation.item.create",
              "item": ["type": "message", "role": "user", "content": [["type": "input_text", "text": text]]]])
        send(["type": "response.create"])
        turns.append(Turn(role: .user, text: text))
        phase = .thinking
    }

    // MARK: - Audio
    private func configureAudio() throws {
        let s = AVAudioSession.sharedInstance()
        // .voiceChat + ses işleme (VPIO) gerçek iPhone'da AVAudioPlayerNode çıkışını susturabiliyor;
        // bas-konuş kullandığımız için yankı engellemeye gerek yok → sade playAndRecord + hoparlör.
        try s.setCategory(.playAndRecord, mode: .default,
                          options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
        try s.setActive(true)
        try? s.overrideOutputAudioPort(.speaker)

        if player.engine == nil { engine.attach(player) }
        engine.connect(player, to: engine.mainMixerNode, format: outFormat)
        installMicTap()
        engine.prepare()
        try engine.start()
        player.play()
        observeAudioChanges()
    }

    /// Mikrofon dokunuşu kuruldu mu (giriş biçimi bazen bir an 0 Hz gelir: yeniden denenir)
    private var micTapInstalled = false

    private func installMicTap(retries: Int = 4) {
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        micTapInstalled = false
        let inFormat = input.outputFormat(forBus: 0)
        guard inFormat.sampleRate > 0 else {
            // Önceki oturum yeni kapandıysa ses donanımı hazır olmayabilir: kısa süre sonra tekrar dene
            voiceLog.info("mic format not ready, retrying")
            guard retries > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.socket != nil, !self.micTapInstalled else { return }
                self.installMicTap(retries: retries - 1)
                if !self.engine.isRunning { try? self.engine.start() }
            }
            return
        }
        guard let converter = AVAudioConverter(from: inFormat, to: wireFormat) else { return }
        let wire = wireFormat
        let state = tapState
        // Dönüştürme + gönderme ses iş parçacığında; ana iş parçacığına yalnızca konuşurken seviye gider
        micTapInstalled = true
        input.installTap(onBus: 0, bufferSize: 2400, format: inFormat) { [weak self] buffer, _ in
            guard let socket = state.streamingSocket else { return }
            let level = Self.rms(buffer)
            let ratio = wire.sampleRate / buffer.format.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
            guard let out = AVAudioPCMBuffer(pcmFormat: wire, frameCapacity: capacity) else { return }
            var fed = false
            var err: NSError?
            converter.convert(to: out, error: &err) { _, status in
                if fed { status.pointee = .noDataNow; return nil }
                fed = true; status.pointee = .haveData; return buffer
            }
            guard err == nil, out.frameLength > 0, let ch = out.int16ChannelData else { return }
            let b64 = Data(bytes: ch[0], count: Int(out.frameLength) * 2).base64EncodedString()
            socket.send(.string("{\"type\":\"input_audio_buffer.append\",\"audio\":\"\(b64)\"}")) { _ in }
            state.record(bytes: Int(out.frameLength) * 2, level: level)
            // Ani sıçramalar logoyu zıplatmasın: yükselişte hızlı, düşüşte yavaş yumuşatma
            Task { @MainActor in
                guard let self else { return }
                let k: Float = level > self.inputLevel ? 0.35 : 0.12
                self.inputLevel += (level - self.inputLevel) * k
            }
        }
    }

    /// Ses yolu değişince (hoparlöre geçiş, kulaklık, kesinti) AVAudioEngine kendini durdurur:
    /// yeniden başlatılmazsa AI sesi çalınmaz ve altyazı ilerlemez.
    private func observeAudioChanges() {
        guard audioObservers.isEmpty else { return }
        let nc = NotificationCenter.default
        let restart: (Notification) -> Void = { [weak self] _ in
            Task { @MainActor in self?.restartAudioIfNeeded(reinstallTap: true) }
        }
        audioObservers = [
            nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main, using: restart),
            nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main, using: restart),
            nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main, using: restart),
            // Arka plandan dönünce: ses motoru kalksın, sıra öğrenciye geçsin, bağlantı ölüyse yenilensin
            nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.resumeFromBackground() }
            },
        ]
    }

    private func restartAudioIfNeeded(reinstallTap: Bool = false) {
        guard phase != .ended, phase != .idle else { return }
        // Önce ses oturumu: etkin değilken mikrofon biçimi 0 Hz gelir ve dokunuş kurulamaz
        try? AVAudioSession.sharedInstance().setActive(true)
        if reinstallTap { installMicTap() }
        if !engine.isRunning {
            engine.prepare()
            do { try engine.start() } catch { print("⚠️ audio engine restart failed: \(error)") }
        }
        if !player.isPlaying { player.play() }
    }

    // MARK: - Arka plandan dönüş & yeniden bağlanma
    private var lastInstructions = ""
    private var lastTools: [[String: Any]] = []
    private var resumeNote: String?
    private var reconnecting = false
    private var needsReconnect = false
    /// Yeni realtime oturumunda kullanım sayacı sıfırdan başlar (önceki oturum ayrı raporlandı)
    private var usageBase = 0

    private func resumeFromBackground() {
        guard phase != .ended, phase != .idle, phase != .connecting else { return }
        if case .failed = phase { return }
        // Basılı tutarken arka plana gittiyse kayıt yarım kaldı: at
        if isHoldingToTalk {
            isHoldingToTalk = false
            micMuted = true
            send(["type": "input_audio_buffer.clear"])
        }
        restartAudioIfNeeded(reinstallTap: true)
        // Arka planda yarım kalan konuşma bir daha çalınmaz: sıra öğrenciye
        if phase == .aiSpeaking || phase == .thinking || phase == .userSpeaking {
            stopPlayback()
            awaitingReply = false
            if !fullAIText.isEmpty { caption = fullAIText; captionFull = fullAIText }
            phase = .listening
        }
        if needsReconnect { needsReconnect = false; Task { await reconnect() }; return }
        // Soket sessizce ölmüş olabilir: ping atıp kontrol et
        let task = socket
        task?.sendPing { [weak self] error in
            guard error != nil else { return }
            Task { @MainActor in
                guard let self, task === self.socket else { return }
                await self.reconnect()
            }
        }
    }

    /// Bağlantı koptuysa yeni oturumla bağlan ve konuşmayı kaldığı yerden sürdür (öğrenci baştan başlamasın)
    private func reconnect() async {
        guard !reconnecting, phase != .ended else { return }
        reconnecting = true
        defer { reconnecting = false }
        voiceLog.info("reconnecting after dropped connection")
        reconnectCount += 1
        reportUsage(final: true)
        let old = socket
        socket = nil
        tapState.set(socket: nil)
        old?.cancel(with: .goingAway, reason: nil)
        let history = turns.filter { !$0.text.isEmpty }.suffix(10).map { t -> String in
            switch t.role {
            case .ai: return "Tutor: " + t.text
            case .user: return "Learner: " + t.text
            default: return "Card shown: " + t.text
            }
        }.joined(separator: "\n")
        resumeNote = """
        The connection dropped for a moment and is back. The conversation so far:
        \(history)
        Do NOT greet again or restart the lesson. Briefly say you're glad they're back (in your own words, in the language you are speaking to them), then continue exactly where you left off \
        (ask your last question again\(currentCard.map { " — the learner's current line is \"\($0)\"; show it with show_phrase again" } ?? "")).
        """
        phase = .connecting
        do {
            let grant = try await VoiceBackend.shared.createSession(instructions: lastInstructions, tools: lastTools)
            sessionId = grant.sessionId
            usageBase = elapsedSeconds
            lastUsageReport = elapsedSeconds
            allowedSeconds = elapsedSeconds + grant.allowedSeconds
            restartAudioIfNeeded(reinstallTap: true)
            connect(model: grant.model, secret: grant.clientSecret)
        } catch let e as VoiceBackend.Failure {
            resumeNote = nil
            errorDetail = "http \(e.code)"
            phase = .failed(e.code)
        } catch {
            resumeNote = nil
            errorDetail = await VoiceBackend.shared.diagnose(error)
            phase = .failed("connection")
        }
    }

    /// base64 PCM16 → Float32 tampon (arka planda çağrılır)
    nonisolated private static func decodePCM(_ base64: String, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let data = Data(base64Encoded: base64), data.count >= 2,
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(data.count / 2)),
              let dst = buf.floatChannelData?[0] else { return nil }
        let n = data.count / 2
        data.withUnsafeBytes { raw in
            let src = raw.bindMemory(to: Int16.self)
            for i in 0..<n { dst[i] = Float(Int16(littleEndian: src[i])) / 32768 }
        }
        buf.frameLength = AVAudioFrameCount(n)
        return buf
    }

    /// Gelen ses parçası. Her cevabın başında ~0.3 sn biriktirilir (titreme tamponu): parçalar arasında
    /// boşluk olup ses takılmasın.
    private func playAudio(_ buf: AVAudioPCMBuffer) {
        restartAudioIfNeeded()
        if phase != .aiSpeaking { phase = .aiSpeaking }
        guard prerolled else {
            preroll.append(buf)
            if preroll.reduce(0, { $0 + Double($1.frameLength) }) >= outFormat.sampleRate * 0.3 { flushPreroll() }
            return
        }
        schedule(buf)
    }

    private func flushPreroll() {
        prerolled = true
        let queued = preroll
        preroll = []
        queued.forEach(schedule)
    }

    private func schedule(_ buf: AVAudioPCMBuffer) {
        let n = Double(buf.frameLength)
        if playbackStart == nil {
            playbackStart = player.lastRenderTime
            playbackWallStart = Date()
            anchorSample = playerSampleTime
            gapSamples = 0
            startCaptionTimer()
        } else if let pos = rawPosition, pos > scheduledSamples {
            // Tampon boşaldı (ses parçası geç geldi): aradaki sessizliği konumdan düş
            gapSamples += pos - scheduledSamples
        }
        scheduledSamples += n
        let gen = playbackGeneration
        player.scheduleBuffer(buf, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.playbackGeneration == gen else { return }
                self.playedSamples += n
            }
        }
    }

    /// Oynatıcının o anki örnek konumu
    private var playerSampleTime: Double? {
        guard engine.isRunning, let node = player.lastRenderTime, let t = player.playerTime(forNodeTime: node) else { return nil }
        return Double(t.sampleTime)
    }

    /// Bu cevabın başından beri (boşluklar düşülmeden) geçen örnek
    private var rawPosition: Double? {
        guard let anchorSample, let now = playerSampleTime else { return nil }
        return now - anchorSample - gapSamples
    }

    /// Şu an çalınan konum (örnek): oynatıcı saatinden sürekli; yoksa tamamlanan parçalardan / duvar saatinden
    private var playbackPosition: Double {
        if let pos = rawPosition { return min(max(pos, playedSamples), scheduledSamples) }
        if !engine.isRunning, let start = playbackWallStart {
            return min(scheduledSamples, Date().timeIntervalSince(start) * outFormat.sampleRate)
        }
        return playedSamples
    }

    /// Bu cevabın çalınmış örnek sayısı; stopPlayback'te nesil değişir, eski geri çağrılar sayılmaz
    private var playedSamples: Double = 0
    private var playbackGeneration = 0
    private var anchorSample: Double?
    private var gapSamples: Double = 0
    private var preroll: [AVAudioPCMBuffer] = []
    private var prerolled = false
    /// Ses üretimi bitti mi (bu andan itibaren yazı/ses oranı kesin)
    private var audioComplete = false { didSet { if audioComplete && !prerolled { flushPreroll() } } }
    /// Öğretmenin ölçülen konuşma hızı (karakter/sn); her cevapta güncellenir
    private var charsPerSecond = 14.0
    /// Yazı sesin biraz önünde aksın (sn)
    private static let captionLead = 0.45

    /// Kullanıcı araya girince AI'ın sesini hemen kes
    private func stopPlayback() {
        playbackGeneration += 1
        player.stop(); player.play()
        scheduledSamples = 0; playedSamples = 0; playbackStart = nil; playbackWallStart = nil
        anchorSample = nil; gapSamples = 0; preroll = []; prerolled = false
        captionTimer?.invalidate()
        if !fullAIText.isEmpty { caption = fullAIText; captionFull = fullAIText }
    }

    /// Altyazı, çalınan ses kadar açılır (Pingo tarzı karaoke)
    private func startCaptionTimer() {
        captionTimer?.invalidate()
        captionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickCaption() }
        }
    }

    private func tickCaption() {
        guard scheduledSamples > 0 else { return }
        let done = playbackPosition
        let played = min(1, done / scheduledSamples)
        // Yazı ~0.3 sn önde: kelime söylenirken ekranda olsun
        let ahead = min(1, (done + Self.captionLead * outFormat.sampleRate) / scheduledSamples)
        captionFull = fullAIText
        // Altyazı sesle aynı hızda: cevap tamamlandıysa toplam süreye oranla, değilse ortalama konuşma hızıyla
        let n = fullAIText.count
        let revealed: Int = audioComplete
            ? Int(Double(n) * ahead)
            : min(n, Int((done / outFormat.sampleRate + Self.captionLead) * charsPerSecond))
        let target = Self.wordBoundary(in: fullAIText, upTo: revealed)
        if target > caption.count { caption = String(fullAIText.prefix(target)); captionChangedAt = Date() }
        if played >= 0.999 && responseFinished && audioComplete {
            // Ölçülen hızı bir sonraki cevabın ilk saniyeleri için sakla
            let seconds = scheduledSamples / outFormat.sampleRate
            if seconds > 1.5, n > 10 { charsPerSecond = 0.6 * charsPerSecond + 0.4 * Double(n) / seconds }
            caption = fullAIText; captionFull = fullAIText
            captionTimer?.invalidate()
            scheduledSamples = 0; playedSamples = 0; playbackGeneration += 1
            playbackStart = nil; playbackWallStart = nil
            anchorSample = nil; gapSamples = 0; prerolled = false
            echoGuardUntil = Date().addingTimeInterval(0.6)
            send(["type": "input_audio_buffer.clear"])
            if phase == .aiSpeaking { phase = .listening }
        }
    }

    private var responseFinished = false

    /// Altyazı kelime kelime açılsın: hedefi son tamamlanmış kelimenin sonuna çek
    private static func wordBoundary(in text: String, upTo n: Int) -> Int {
        guard n < text.count else { return text.count }
        let prefix = text.prefix(n)
        guard let lastSpace = prefix.lastIndex(where: { $0 == " " || $0 == "\n" }) else { return 0 }
        return prefix.distance(from: prefix.startIndex, to: lastSpace) + 1
    }

    nonisolated private static func rms(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let ch = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += ch[i] * ch[i] }
        return min(1, sqrt(sum / Float(buffer.frameLength)) * 6)
    }

    // MARK: - Socket
    /// Doğrudan bağlantı bir kez kurulamadıysa (bazı mobil operatörler) uygulama açık kaldıkça hep aktarıcı kullanılır
    private static var preferRelay = false
    private var viaRelay = false
    private var lastGrant: (model: String, secret: String)?

    private func connect(model: String, secret: String) {
        lastGrant = (model, secret)
        let relayReq = VoiceBackend.shared.relayRequest(model: model, secret: secret)
        viaRelay = Self.preferRelay && relayReq != nil
        var req = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime?model=\(model)")!)
        req.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        open(viaRelay ? relayReq! : req)
    }

    private func open(_ req: URLRequest) {
        voiceLog.info("socket open (relay: \(self.viaRelay, privacy: .public))")
        let task = URLSession.shared.webSocketTask(with: req)
        socket = task
        tapState.set(socket: task)
        task.resume()
        receive()
        // Oturum birkaç saniyede açılmazsa (soket asılı kaldı) aktarıcıya geç
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard let self, task === self.socket, self.phase == .connecting else { return }
            self.connectFailed()
        }
    }

    /// Oturum açılmadan düştü: doğrudan bağlantıdaysak aktarıcıyı dene, o da olmazsa hata göster
    private func connectFailed() {
        let old = socket
        socket = nil
        tapState.set(socket: nil)
        old?.cancel(with: .goingAway, reason: nil)
        if !viaRelay, let g = lastGrant, let req = VoiceBackend.shared.relayRequest(model: g.model, secret: g.secret) {
            voiceLog.info("direct socket failed, switching to relay")
            Self.preferRelay = true
            viaRelay = true
            open(req)
        } else {
            resumeNote = nil
            errorDetail = "socket " + (lastSocketError ?? "timeout")
            phase = .failed("connection")
        }
    }

    private func send(_ event: [String: Any]) {
        guard let socket, let data = try? JSONSerialization.data(withJSONObject: event),
              let text = String(data: data, encoding: .utf8) else { return }
        socket.send(.string(text)) { _ in }
    }

    /// JSON çözme ve ses çözme arka planda; ana iş parçacığına yalnızca hazır olay/tampon gider
    private func receive() {
        let format = outFormat
        let task = socket
        task?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                let ns = error as NSError
                let desc = "\(ns.code)" + ((task?.response as? HTTPURLResponse).map { " http \($0.statusCode)" } ?? "")
                Task { @MainActor in
                    if let self, task === self.socket { self.lastSocketError = desc }
                    // Yeniden bağlanırken eski soketin hatası oturumu düşürmesin
                    guard let self, task === self.socket, self.phase != .ended else { return }
                    if self.phase == .connecting { self.connectFailed(); return }
                    // Arka planda iOS soketi kapatır: önce sessizce yeniden bağlan, olmazsa hata göster
                    if UIApplication.shared.applicationState == .active { await self.reconnect() }
                    else { self.needsReconnect = true }
                }
            case .success(let message):
                if case .string(let text) = message, let data = text.data(using: .utf8),
                   let event = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                    let type = event["type"] as? String ?? ""
                    if type == "response.output_audio.delta" || type == "response.audio.delta" {
                        let buf = (event["delta"] as? String).flatMap { Self.decodePCM($0, format: format) }
                        Task { @MainActor in if let buf { self?.playAudio(buf) } }
                    } else {
                        nonisolated(unsafe) let e = event
                        Task { @MainActor in self?.handle(e) }
                    }
                }
                Task { @MainActor in if task === self?.socket { self?.receive() } }
            }
        }
    }

    private func handle(_ e: [String: Any]) {
        let type = e["type"] as? String ?? ""
        if silentCardActive || silentCardPending { voiceLog.info("silent event: \(type, privacy: .public)") }
        switch type {
        case "session.created", "session.updated":
            if phase == .connecting, resumeNote == nil, let started = connectStartedAt {
                connectStartedAt = nil
                trackLesson("connected", ["connect_ms": Int(Date().timeIntervalSince(started) * 1000)])
            }
            if phase == .connecting {
                phase = .listening
                // Sunucu ses algılaması kapalı: yalnızca basılı tutunca dinlenir
                send(["type": "session.update", "session": ["type": "realtime", "audio": ["input": ["turn_detection": NSNull()]]]])
                if let note = resumeNote {
                    // Kopan bağlantı yenilendi: baştan selamlama yok, kaldığı yerden devam
                    resumeNote = nil
                    sendGuide(note)
                    send(["type": "response.create"])
                } else if aiSpeaksFirst {
                    // AI ilk sözü alsın (karşılama) — serbest sohbette öğrenci başlar
                    send(["type": "response.create"])
                }
            }

        case "input_audio_buffer.speech_started":
            stopPlayback()
            send(["type": "response.cancel"])
            phase = .userSpeaking

        case "input_audio_buffer.speech_stopped":
            phase = .thinking

        case "conversation.item.input_audio_transcription.completed":
            voiceLog.info("heard: \((e["transcript"] as? String) ?? "", privacy: .public)")
            let t = (e["transcript"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { turns.append(Turn(role: .user, text: t)) }
            if awaitingReply {
                awaitingReply = false
                guide(after: t)
                send(["type": "response.create"])
            }

        case "response.created":
            // Yalnızca kart isteyen sessiz cevap: ekrandaki yazıyı/sesi bozma
            if silentCardPending { silentCardPending = false; silentCardActive = true; break }
            fullAIText = ""; rawAIText = ""; phraseShownThisResponse = false; audioComplete = false
            preroll = []; prerolled = false
            caption = ""; captionFull = ""; responseFinished = false
            responseCount += 1
            turns.append(Turn(role: .ai, text: ""))

        case "response.output_audio_transcript.delta", "response.audio_transcript.delta":
            if let d = e["delta"] as? String {
                rawAIText += d
                fullAIText = Self.stripToolText(rawAIText)
                if let i = turns.lastIndex(where: { $0.role == .ai }) { turns[i].text = fullAIText }
            }

        case "response.function_call_arguments.done":
            let name = e["name"] as? String ?? ""
            let callId = e["call_id"] as? String ?? ""
            var args = (e["arguments"] as? String).flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
            // Ders/demo bitti: vedadan sonra yeni kart açılmaz (yoksa konuşma bitmiş gibiyken yeniden başlar)
            if name == "show_phrase", lessonComplete {
                voiceLog.info("card after wrap-up rejected")
                send(["type": "conversation.item.create",
                      "item": ["type": "function_call_output", "call_id": callId,
                               "output": "rejected: the lesson is over — no more cards. Just say a short goodbye if you haven't."]])
                break
            }
            // Dersin ne zaman biteceğine uygulama karar verir: model erken finish_lesson çağırırsa ders kesilmesin
            if name == "finish_lesson", !allowModelFinish, !lessonComplete, !timeUp {
                voiceLog.info("early finish rejected")
                send(["type": "conversation.item.create",
                      "item": ["type": "function_call_output", "call_id": callId,
                               "output": "rejected: the lesson is NOT over — keep teaching. Continue with the current step and end your turn with a question for the learner."]])
                break
            }
            // Onboarding demosunda model bazen kendi sorusunu kart yapıyor: kart her zaman öğrencinin cevabı olmalı
            if name == "show_phrase", answerCardsOnly, let p = args["phrase"] as? String,
               let last = p.trimmingCharacters(in: .whitespacesAndNewlines).last, "?？".contains(last) {
                voiceLog.info("question card rejected: \(p, privacy: .public)")
                needsAnswerCard = true
                send(["type": "conversation.item.create",
                      "item": ["type": "function_call_output", "call_id": callId,
                               "output": "rejected: the card must be the learner's ANSWER, not your question"]])
                break
            }
            // "..." şablonları yalnızca onboarding demosunda: derste/sohbette kart tam bir örnek cümle olmalı (bir kez yeniden istenir)
            if name == "show_phrase", !answerCardsOnly, !completeCardRetried, let p = args["phrase"] as? String,
               p.contains("...") || p.contains("…") {
                voiceLog.info("template card rejected: \(p, privacy: .public)")
                needsCompleteCard = true
                completeCardRetried = true
                phraseShownThisResponse = true
                send(["type": "conversation.item.create",
                      "item": ["type": "function_call_output", "call_id": callId,
                               "output": "rejected: no '...' blanks — the card must be a complete example sentence"]])
                break
            }
            // Derste kart her zaman planın dilinde (model başka dil isteyince kartı o dilde açabiliyor)
            if name == "show_phrase", !allowLanguageSwitch, !answerCardsOnly, translatingPhrase == nil,
               let p = args["phrase"] as? String, Self.isClearlyOtherLanguage(p) {
                voiceLog.info("card in wrong language rejected: \(p, privacy: .public)")
                needsAnswerCard = true
                let en = Locale(identifier: "en")
                send(["type": "conversation.item.create",
                      "item": ["type": "function_call_output", "call_id": callId,
                               "output": "rejected: cards in this lesson must be in \(en.localizedString(forLanguageCode: Self.currentTarget) ?? "the target language")"]])
                break
            }
            // Yalnızca çeviri istendiyse kart cümlesi değişmez (model bazen cümleyi de yeniden yazıyor)
            if name == "show_phrase", silentCardActive, let fixed = translatingPhrase {
                args["phrase"] = fixed
            }
            if name == "show_phrase", let p = args["phrase"] as? String {
                args["phrase"] = Self.unsyllabify(p, spoken: fullAIText)
            }
            if name == "show_phrase" {
                phraseShownThisResponse = true
                completeCardRetried = false
                currentCard = args["phrase"] as? String
                voiceLog.info("card: \(self.currentCard ?? "", privacy: .public)")
                // Çeviri boşsa ya da ana dilde değilse (model bazen İspanyolca vb. yazıyor) doğrusu sessizce istenir
                let tr = ((args["translation"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
                if !tr.isEmpty, translatingPhrase == nil, !Self.isNativeLanguage(tr) {
                    voiceLog.info("translation not in native language, refetching: \(tr, privacy: .public)")
                    args["translation"] = ""
                }
                if ((args["translation"] as? String) ?? "").isEmpty, let p = currentCard {
                    translationPending = p
                }
            }
            let output = onToolCall?(name, args) ?? "ok"
            send(["type": "conversation.item.create",
                  "item": ["type": "function_call_output", "call_id": callId, "output": output]])
            // Kart gösterildiyse sıra kullanıcıda: AI'ı tekrar konuşturma (yoksa kendi kendine devam eder).
            // Diğer araçlarda yalnızca AI bu yanıtta hiç konuşmadıysa devam ettir.
            // Ders konuşmadan bitirildiyse vedayı söylesin (araçsız), ekran ondan sonra kapanır.
            if name != "show_phrase" && fullAIText.isEmpty {
                pendingToolFollowUp = true
                followUpWithoutTools = name == "finish_lesson"
            }

        case "response.output_audio.done", "response.audio.done":
            audioComplete = true

        case "response.done":
            if silentCardActive {
                silentCardActive = false
                // Sessiz kartın çevirisi eksik/yanlış dildeyse bir kez daha (yalnızca çeviri) istenir
                let pending = translatingPhrase == nil ? translationPending : nil
                translationPending = nil; translatingPhrase = nil
                if needsCompleteCard { needsCompleteCard = false; requestCard(answerTo: fullAIText, complete: true) }
                else if let p = pending { requestCard(translating: p) }
                break
            }
            voiceLog.info("tutor said: \(self.fullAIText, privacy: .public)")
            // Demoda son adımda öğretmen kendiliğinden vedalaştıysa: bitti say (yeni kart/tur açılmasın)
            if answerCardsOnly, !lessonComplete, !targets.isEmpty, targetProgress >= targets.count - 1,
               fullAIText.range(of: #"see you|goodbye|bye for now|take care"#, options: [.regularExpression, .caseInsensitive]) != nil {
                lessonComplete = true
            }
            // Model veda edip finish_lesson'ı unutursa ekran takılı kalmasın
            if let n = completeAfterUserTurns, !lessonComplete,
               turns.filter({ $0.role == .user && !$0.text.isEmpty }).count >= n {
                lessonComplete = true
            }
            responseFinished = true
            audioComplete = true
            if needsCompleteCard {
                needsCompleteCard = false
                requestCard(answerTo: fullAIText, complete: true)
            } else {
                ensurePhraseCard()
            }
            if let p = translationPending {
                translationPending = nil
                requestCard(translating: p)
            }
            if pendingToolFollowUp {
                pendingToolFollowUp = false
                if followUpWithoutTools {
                    followUpWithoutTools = false
                    sendGuide("Now say your warm goodbye out loud in 1–2 short sentences, as planned. No tools.")
                    send(["type": "response.create", "response": ["tool_choice": "none"]])
                } else {
                    send(["type": "response.create"])
                }
            } else if scheduledSamples == 0 {
                caption = fullAIText; captionFull = fullAIText
                phase = .listening
            }

        case "error":
            let msg = (e["error"] as? [String: Any])?["message"] as? String ?? "error"
            voiceLog.error("realtime error: \(msg, privacy: .public)")

        default:
            break
        }
    }

    private var pendingToolFollowUp = false
    private var followUpWithoutTools = false
    private var needsAnswerCard = false
    private var needsCompleteCard = false
    private var completeCardRetried = false
    private var aiSpeaksFirst = true

    /// Çevirisiz gösterilen kart: cevap bitince çevirisi sessizce istenir
    private var translationPending: String?
    /// Sessiz çeviri isteğindeki sabit kart cümlesi
    private var translatingPhrase: String?
    /// Kartlar yalnızca öğrencinin cevabı olabilir (soru kartı reddedilir) — onboarding demosu
    var answerCardsOnly = false
    /// Kartsız konuşma (yeni dil kurulumu): her tur kart istenmez
    var noCards = false
    /// Sabit akışlı konuşma (dil kurulumu): öğrencinin bu kadar cevabından sonraki öğretmen turu kapanıştır
    var completeAfterUserTurns: Int?
    /// Kartsız konuşmada yine de kart istenen tur: öğrenciye bir şey söyletilen an (kurulumda ilk kelime)
    var cardAfterUserTurns: Int?
    /// Yeni dil kurulumunda öğrenilen dil henüz değişmedi: kartlar/dil algılama bu dile göre yapılır
    nonisolated(unsafe) static var targetOverride: String?
    nonisolated static var currentTarget: String {
        targetOverride ?? (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased()
    }
    /// Modelin finish_lesson ile konuşmayı kendisi bitirebildiği modlar (kurulum, kelime tekrarı)
    var allowModelFinish = false
    /// Serbest sohbette öğrenci başka dile geçebilir (kartlar o dilde olabilir)
    var allowLanguageSwitch = false
    /// Pro kullanıcıya süre bitiminde satın alma önerilmez
    var isPro = false
    private var silentCardPending = false
    private var cardTool: [String: Any]?
    private var silentCardActive = false

    /// Öğretmen turu kartsız bitirdiyse: sesi olmayan bir cevapla yalnızca kartı iste (kullanıcı ne diyeceğini hep görsün)
    private func requestCard(answerTo question: String? = nil, translating phrase: String? = nil, complete: Bool = false) {
        guard !silentCardPending, !silentCardActive, let cardTool else { return }
        translatingPhrase = phrase
        let native = Locale(identifier: "en").localizedString(forLanguageCode: OL.nativeLangCode) ?? "the learner's native language"
        // Dil adı açıkça yazılır: "target language" deyince model bazen başka dil seçiyor
        let targetCode = Self.currentTarget
        let target = Locale(identifier: "en").localizedString(forLanguageCode: targetCode) ?? "English"
        let instructions = phrase.map {
            "Do not say anything. Call show_phrase with exactly this phrase: \"\($0)\" and its natural translation into \(native)."
        } ?? question.map {
            "Do not say anything. You just said: \"\($0)\". Call show_phrase with a short, natural example answer to exactly that question that the learner can say back to you (in \(target), first person), never a question, and its translation into \(native)."
                + (complete ? " Make it a complete, realistic example sentence — fill in real details, no '...' or blanks." : "")
        } ?? "Do not say anything. Call show_phrase with the exact short line the learner should say next in \(target) (a complete, natural model answer — never placeholders like [your name]) and its translation into \(native)."
            + (targetProgress < targets.count ? " The current step is: \(targets[targetProgress]) — show the line it specifies with show_phrase." : "")
        silentCardPending = true
        voiceLog.info("no card this turn → asking silently")
        // Araç cevabın içinde de verilmeli, yoksa model zorunlu çağrıyı yok sayıyor
        send(["type": "response.create", "response": [
            "output_modalities": ["text"],
            "tools": [cardTool],
            "tool_choice": "required",
            "instructions": instructions,
        ] as [String: Any]])
    }

    /// Küçük model kart komutunu bazen düz metin olarak yazar: ekranda/transkriptte gösterme
    /// Kısa metinde dil tahmini şaşabilir: yalnızca açıkça başka bir dilse "değil" der
    nonisolated static func isNativeLanguage(_ text: String) -> Bool {
        let native = OL.nativeLangCode.lowercased()
        let r = NLLanguageRecognizer()
        r.processString(text)
        let hyp = r.languageHypotheses(withMaximum: 3)
        guard let top = hyp.max(by: { $0.value < $1.value }), top.value > 0.6 else { return true }
        return top.key.rawValue.hasPrefix(native) || (hyp[NLLanguage(native)] ?? 0) > 0.2
    }

    /// "Bu soruyu sevmedim, geçelim", "skip", "başka bir şey konuşalım"…
    nonisolated static func wantsToSkip(_ said: String) -> Bool {
        let t = said.lowercased()
        let patterns = [
            #"\bge[çc](elim|ebilir|sene|iyorum|mek istiyorum)\b"#, #"\b(sonraki|başka) (soru|şey|konu)"#, #"(soruyu|konuyu) (değiştir|geç|sevmedim|beğenmedim)"#,
            #"\b(beğenmedim|sevmedim)\b"#, #"\bskip\b"#, #"next question"#, #"another (question|topic)"#, #"something else"#,
            #"change (the )?(topic|subject|question)"#, #"don'?t like (this|that) question"#, #"(talk|speak) about something"#,
            #"\b(weiter|nächste frage|etwas anderes)\b"#, #"\b(autre chose|question suivante|on passe)\b"#, #"\b(otra cosa|siguiente pregunta)\b"#,
        ]
        return patterns.contains { t.range(of: $0, options: .regularExpression) != nil }
    }

    nonisolated static func stripToolText(_ s: String) -> String {
        // Arka plandaki araç adları (show_phrase, finish_lesson…) kullanıcıya asla görünmesin
        let tools = #"(show_phrase|finish_lesson|remember_fact|mark_word_used|functions?\.\w+)"#
        var t = s.replacingOccurrences(of: tools + #"\s*\([^)]*\)?"#, with: "", options: .regularExpression)
        // Yarım gelen çağrı ("show_phrase(\"Hel…"): adından sonrasını kes
        if let r = t.range(of: tools, options: .regularExpression) { t = String(t[..<r.lowerBound]) }
        // "Card: Hallo!" / "Kart: …" gibi etiketli satırlar: kart zaten açılıyor, metinde tekrar yazılmasın
        let label = #"(?i)(card|kart|karte|carte|tarjeta|carta|scheda|карточка|卡片)\s*[:：]\s*[^\n]*"#
        t = t.replacingOccurrences(of: label, with: "", options: .regularExpression)
        // Sahne notları: "(showing you the phrase now)", "[card]", "*pauses*" gibi parantez içi anlatımlar
        let stage = #"(phrase|card|showing|show|shown|screen|tool|function|pause|waits?|waiting|smiles?|laughs?|kart|ifade|gösteri)"#
        t = t.replacingOccurrences(of: #"[\(\[\*][^\)\]\*\n]{0,80}"# + stage + #"[^\)\]\*\n]{0,80}[\)\]\*]"#,
                                   with: "", options: [.regularExpression, .caseInsensitive])
        // Akış sırasında henüz kapanmamış parantez: kapanana kadar gösterme (sahne notu çıkabilir)
        t = t.replacingOccurrences(of: #"[\(\[][^\)\]]*$"#, with: "", options: .regularExpression)
        // Herhangi bir snake_case tanımlayıcı da (ör. "finish lesson" değil "finish_lesson") metinden çıkar
        t = t.replacingOccurrences(of: #"\b[a-z]+(_[a-z]+)+\b"#, with: "", options: .regularExpression)
        // Düz konuşma metni: cümle arası tireler ("had— twice", "nice - right") virgül/boşluk olur, "e-mail" gibi kelimeler kalır
        t = t.replacingOccurrences(of: #"\s*[—–]\s*"#, with: ", ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(\w)-\s+"#, with: "$1 ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\s+-\s+"#, with: ", ", options: .regularExpression)
        t = t.replacingOccurrences(of: #",\s*([,.!?])"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Telaffuz için hecelenmiş kelime ("Ha-llo") kartta normal yazılsın; "E-Mail" gibi gerçek tireli kelimeler
    /// yalnızca birleşik hali konuşmada da geçiyorsa birleştirilir.
    nonisolated static func unsyllabify(_ card: String, spoken: String) -> String {
        let known = Set(spoken.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { $0.count > 1 })
        var out = card
        for m in card.matches(of: try! Regex(#"\p{L}+(?:-\p{L}+)+"#)) {
            let word = String(card[m.range])
            let joined = word.replacingOccurrences(of: "-", with: "")
            if known.contains(joined.lowercased()) { out = out.replacingOccurrences(of: word, with: joined) }
        }
        return out
    }

    /// Her tur bir kartla bitmeli (Pingo gibi). Model aracı çağırmadıysa: metne yazdığı komutu ya da
    /// son tırnak içindeki ifadeyi kart yap.
    private func ensurePhraseCard() {
        let userTurns = turns.filter { $0.role == .user && !$0.text.isEmpty }.count
        guard !noCards || cardAfterUserTurns == userTurns, !phraseShownThisResponse, !pendingToolFollowUp, !rawAIText.isEmpty, !lessonComplete, !timeUp else { return }
        if needsAnswerCard {
            needsAnswerCard = false
            return requestCard(answerTo: fullAIText)
        }
        var phrase: String?, translation = ""
        let q = #"["“”]"#
        if let r = rawAIText.range(of: #"show_phrase\s*\(\s*\#(q)([^"“”]+)\#(q)\s*,\s*\#(q)([^"“”]*)\#(q)"#, options: .regularExpression) {
            let parts = rawAIText[r].split(whereSeparator: { "\"“”".contains($0) }).map(String.init)
            if parts.count >= 2 { phrase = parts[1] }
            if parts.count >= 4 { translation = parts[3] }
        }
        if phrase == nil {
            // Tırnak içindeki ifadelerden öğrenilen dildeki sonuncusu (ana dildeki açıklamalar değil)
            let target = Self.currentTarget
            let quotes = fullAIText.matches(of: try! Regex(#"[“"„«]([^"“”„«»]{2,80})[”"“»]"#))
                .compactMap { $0.output[1].substring.map(String.init) }
            // Ana dilde olmayan son alıntı (isim geçen kısa cümleler yanlış dil sanılabiliyor)
            let native = OL.nativeLangCode.lowercased()
            func lang(_ q: String) -> String? {
                let r = NLLanguageRecognizer()
                r.processString(q)
                return r.dominantLanguage?.rawValue
            }
            // Önce öğrenilen dildeki son alıntı ("Hallo, wie geht's?" → değil anlamı "Hi, how are you?")
            // Tek kelimelik alıntılar ("Gast" (misafir)) kelime açıklamasıdır; söylenecek cümle tercih edilir
            let sentences = quotes.filter { $0.split(separator: " ").count >= 2 }
            phrase = sentences.last { lang($0)?.hasPrefix(target) == true }
                ?? quotes.last { lang($0)?.hasPrefix(target) == true }
                ?? quotes.last { q in lang(q).map { !$0.hasPrefix(native) } ?? true }
        }
        guard let phrase, !phrase.trimmingCharacters(in: .whitespaces).isEmpty else {
            // Öğretmen soru sorduysa kart o sorunun cevabı olsun (dersin sıradaki adımı değil)
            let asked = fullAIText.trimmingCharacters(in: .whitespacesAndNewlines)
            if asked.hasSuffix("?") { requestCard(answerTo: asked) } else { requestCard() }
            return
        }
        let card = Self.unsyllabify(phrase, spoken: fullAIText)
        phraseShownThisResponse = true
        currentCard = card
        voiceLog.info("card: \(card, privacy: .public)")
        _ = onToolCall?("show_phrase", ["phrase": card, "translation": translation])
        if translation.trimmingCharacters(in: .whitespaces).isEmpty { requestCard(translating: card) }
    }

    // MARK: - Süre & kullanım
    private func startClock() {
        clock?.invalidate()
        clock = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickClock() }
        }
    }

    /// Yalnızca gerçek konuşma süresi sayılır (kullanıcı basılı tutarken + AI sesi çalarken);
    /// sessizlik/kart okuma ücretsiz. Kötüye kullanıma karşı duvar saatinde de bir tavan var.
    private func tickClock() {
        guard phase != .connecting, phase != .ended else { return }
        wallSeconds += 1
        watchForStall()
        if isHoldingToTalk || scheduledSamples > 0 { elapsedSeconds += 1 }
        if elapsedSeconds - lastUsageReport >= 30 { reportUsage(final: false) }
        if allowedSeconds > 0 && wallSeconds >= max(allowedSeconds * 3, 900) {
            endForLimit(); return
        }
        guard allowedSeconds > 0 else { return }
        // Süre bitiyor: sıra kullanıcıdayken (kimsenin sözü kesilmeden) AI son bir veda cümlesi söyler
        if !warnedTimeUp && elapsedSeconds >= max(0, allowedSeconds - 20) && phase == .listening && !isHoldingToTalk {
            sayTimeUp()
        }
        // Veda bitti (ya da takıldı) → paywall
        if let at = timeUpAt, (phase == .listening && Date().timeIntervalSince(at) > 1.5) || Date().timeIntervalSince(at) > 20 {
            endForLimit(); return
        }
        // Kullanıcı süreyi aşıp konuşmaya devam ederse kesin sınır
        if elapsedSeconds >= allowedSeconds + 45 { endForLimit() }
    }

    private func sayTimeUp() {
        warnedTimeUp = true
        timeUp = true
        timeUpAt = Date()
        currentCard = nil
        phase = .thinking
        sendGuide(isPro
            ? "The learner's speaking time for this period is used up. Say a warm goodbye in 1–2 short sentences, in the learner's native language: that's all the talk time for now (a little sad, end with 😞), praise one thing they did well, and say you'll be here again soon. Do NOT call any tool."
            : "The learner's free speaking time for today is over. Say a warm goodbye in 1–2 short sentences, in the learner's native language: today's free practice is done for now (a little sad, end the sentence with 😞), praise one thing they did well, and say Pro unlocks unlimited practice. Do NOT call any tool.")
        send(["type": "response.create", "response": ["tool_choice": "none"]])
    }

    private func endForLimit() {
        timeUpAt = nil
        onLimitReached?()
        stop()
    }

    // MARK: - Takılma koruması
    /// Uygulama arka plana alınınca iOS ses motorunu durdurur: çalınmayı bekleyen ses hiç "bitmez" ve ekran
    /// "öğretmen konuşuyor" durumunda kalır (yalnızca Transkript görünür). İlerleme durursa toparla, sırayı öğrenciye ver.
    private var stallMark: Double = -1
    private var stallTicks = 0

    private func watchForStall() {
        guard phase == .aiSpeaking || phase == .thinking, !isHoldingToTalk else { stallTicks = 0; return }
        let mark = playedSamples + scheduledSamples + Double(fullAIText.count)
        if mark != stallMark { stallMark = mark; stallTicks = 0; return }
        stallTicks += 1
        // Ses bitti ama çalınması takıldı: 4 sn; hiç cevap gelmiyor: 15 sn
        let limit = phase == .aiSpeaking ? (responseFinished ? 4 : 10) : 15
        guard stallTicks >= limit else { return }
        voiceLog.info("stall recovered (phase \(String(describing: self.phase), privacy: .public))")
        stallTicks = 0
        restartAudioIfNeeded()
        stopPlayback()
        if !fullAIText.isEmpty { caption = fullAIText; captionFull = fullAIText }
        phase = .listening
    }

    private func reportUsage(final: Bool) {
        guard let sessionId else { return }
        lastUsageReport = elapsedSeconds
        let seconds = elapsedSeconds - usageBase
        Task { await VoiceBackend.shared.reportUsage(sessionId: sessionId, seconds: seconds) }
    }
}

/// Ses iş parçacığı ile ana iş parçacığı arasında paylaşılan küçük durum (kilitli)
final class TapState: @unchecked Sendable {
    private let lock = NSLock()
    private var stream = false
    private var socket: URLSessionWebSocketTask?

    func set(stream: Bool) { lock.lock(); self.stream = stream; lock.unlock() }
    private var sentBytes = 0
    private var peak: Float = 0
    func record(bytes: Int, level: Float) { lock.lock(); sentBytes += bytes; peak = max(peak, level); lock.unlock() }
    func takeStats() -> (bytes: Int, peak: Float) {
        lock.lock(); defer { sentBytes = 0; peak = 0; lock.unlock() }
        return (sentBytes, peak)
    }
    func set(socket: URLSessionWebSocketTask?) { lock.lock(); self.socket = socket; lock.unlock() }
    /// Mikrofon akışı açıksa gönderilecek soket
    var streamingSocket: URLSessionWebSocketTask? { lock.lock(); defer { lock.unlock() }; return stream ? socket : nil }
}
