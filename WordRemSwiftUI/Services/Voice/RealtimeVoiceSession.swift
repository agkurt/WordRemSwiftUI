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
import NaturalLanguage
import Foundation
import os

private let voiceLog = Logger(subsystem: "com.twinflare.WordRemSwiftUI", category: "voice")

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
    @Published private(set) var phase: Phase = .idle
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
        self.withRoleplay = roleplay
        self.cardTool = tools.first { $0["name"] as? String == "show_phrase" }
        targetTotal = targets.count
        targetProgress = min(startStep, targets.count); attempts = 0; roleplayTurns = 0; lessonComplete = false
        pendingCombine = false; correctAnswers = 0; totalAnswers = 0; startedAt = Date()
        guard phase == .idle || phase == .ended || { if case .failed = phase { return true }; return false }() else { return }
        phase = .connecting
        turns = []; caption = ""; elapsedSeconds = 0; lastUsageReport = 0; wallSeconds = 0; warnedTimeUp = false; timeUp = false; timeUpAt = nil
        do {
            let grant = try await VoiceBackend.shared.createSession(instructions: instructions, tools: tools)
            sessionId = grant.sessionId
            allowedSeconds = grant.allowedSeconds
            // İzin penceresi ses motorunu yarıda kesmesin: önce izni al
            _ = await AVAudioApplication.requestRecordPermission()
            try configureAudio()
            connect(model: grant.model, secret: grant.clientSecret)
            startClock()
        } catch let e as VoiceBackend.Failure {
            phase = .failed(e.code)
        } catch {
            phase = .failed("network")
        }
    }

    func stop() {
        guard phase != .ended else { return }
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
        // Cevabı, ne söylendiği yazıya dökülünce iste (ders yönlendirmesi için); en geç 1.5 sn
        awaitingReply = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
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
    private var currentCard: String?
    private var attempts = 0
    private var roleplayTurns = 0
    private var pendingCombine = false
    private var withRoleplay = true
    private var awaitingReply = false

    /// Öğrencinin söylediğine göre öğretmene bir sonraki adımı söyler (Pingo tarzı: yeni parça → birleştir → yeni parça…).
    /// Sıralama arka planda; öğretmen bunu "adım" diye anlatmaz.
    private func guide(after said: String) {
        guard !targets.isEmpty, !lessonComplete else { return }
        // Hiçbir şey duyulmadı (çok kısa bastı / mikrofon sesi almadı): hata sayma, nazikçe tekrar iste
        if said.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sendGuide("You couldn't hear the learner this time (no words came through). Don't quote anything or count it as a mistake — say in a few playful words you didn't catch that, and ask them to say the line again.")
        }
        // Karta hiç benzemeyen birkaç kelime: deneme değil, sohbet/şaka → keyifle karşıla, derse dön
        if let card = currentCard, said.split(separator: " ").count >= 3, Self.overlap(said: said, card: card) < 0.25 {
            return sendGuide("The learner said something off-script (a joke, a flirt or a side comment). Enjoy it: react in the moment with one warm, witty line — laugh if it's funny — then smoothly bring them back (\"Okay, let's focus and keep going!\") and invite them to say the current line again. Don't treat it as a mistake.")
        }
        // Demoda kart yalnızca örnek cevap: kendi bilgisini söyleyen ("I'm a morning person") doğru sayılır
        let ok = currentCard.map { Self.matches(said: said, card: $0) || Self.overlap(said: said, card: $0) >= (answerCardsOnly ? 0.25 : 0.6) } ?? !said.isEmpty
        totalAnswers += 1
        if ok { correctAnswers += 1 }
        lastAnswerCorrect = ok
        answerCount += 1
        if let card = currentCard { onAnswer?(card, ok) }
        var note: String

        if targetProgress < targets.count || pendingCombine {
            attempts += 1
            guard ok || attempts >= 2 else {
                note = "The learner's attempt wasn't quite right. Quote what you heard kindly (\"Oh, I heard: '\(said)'\"), name the tiny fix in a few words, and have them say the correct line again."
                return sendGuide(note)
            }
            attempts = 0
            currentCard = nil
            let praise = ok ? "The learner got it right — react with a short, varied, genuine praise (never the same words twice)."
                            : "Two tries are enough here — encourage them warmly and move on."
            if pendingCombine {
                pendingCombine = false
                note = targetProgress < targets.count
                    ? "\(praise) \(Self.nextPiece(targets[targetProgress]))"
                    : finishOrRoleplay(praise)
            } else {
                targetProgress += 1
                if withRoleplay && targetProgress >= 2 && targetProgress % 2 == 0 {
                    // Pingo gibi: öğrendiklerini birleştirip biraz daha uzun bir cümle kurdur
                    pendingCombine = true
                    note = "\(praise) Now build on what they know: have them say one slightly longer line that combines their earlier phrases with this one (for example a greeting + their name + nice to meet you)."
                } else if targetProgress < targets.count, answerCardsOnly {
                    // Sohbet demosu: önce soruyu SESLİ sor, kart (olası cevaplar) ondan sonra
                    note = "\(praise) Then, out loud, \(targets[targetProgress]). Your spoken turn MUST end with the question itself; only after asking it, call show_phrase."
                } else if targetProgress < targets.count {
                    note = "\(praise) \(Self.nextPiece(targets[targetProgress]))"
                } else {
                    note = finishOrRoleplay(praise)
                }
            }
        } else {
            roleplayTurns += 1
            if roleplayTurns < 4 {
                note = ok || said.count > 3
                    ? "Stay in character: react naturally to what they said, then say the next line as the other person and give the learner's reply as the card."
                    : "Stay in character but help them: give the reply they could use as the card and let them try."
            } else {
                note = "End the roleplay warmly. Then, like a real teacher, recap with 2–3 real-life example lines they can now use (quote them), celebrate in one sentence and say you'll continue next time. Say all of this OUT LOUD first, then call finish_lesson with success true. No new card."
                lessonComplete = true
            }
        }
        sendGuide(note)
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
        "Next piece: \(target). Bring it in as a real mini-exchange in the scene: set up the moment in a few words, ask the learner the natural question out loud (the way a real person would), then card the learner's answer. When there's a natural choice, put two answer options separated by \" / \"."
    }

    private static let roleplayStart = "Time for a real-life roleplay that fits the lesson scene (e.g. you are the check-in agent or a new friend at a party). Set the scene in a few words, then SAY OUT LOUD the other person's first line in character, and only then call show_phrase with the learner's reply."

    private func sendGuide(_ note: String) {
        voiceLog.info("guide: \(note, privacy: .public)")
        send(["type": "conversation.item.create",
              "item": ["type": "message", "role": "system", "content": [["type": "input_text", "text": note]]]])
    }

    private func guide(roleplay note: String) {
        voiceLog.info("guide: \(note, privacy: .public)")
        send(["type": "conversation.item.create",
              "item": ["type": "message", "role": "system", "content": [["type": "input_text", "text": note]]]])
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

    private func installMicTap() {
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        let inFormat = input.outputFormat(forBus: 0)
        guard inFormat.sampleRate > 0 else { return }
        guard let converter = AVAudioConverter(from: inFormat, to: wireFormat) else { return }
        let wire = wireFormat
        let state = tapState
        // Dönüştürme + gönderme ses iş parçacığında; ana iş parçacığına yalnızca konuşurken seviye gider
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
            Task { @MainActor in self?.inputLevel = level }
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
        ]
    }

    private func restartAudioIfNeeded(reinstallTap: Bool = false) {
        guard phase != .ended, phase != .idle else { return }
        if reinstallTap { installMicTap() }
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            engine.prepare()
            do { try engine.start() } catch { print("⚠️ audio engine restart failed: \(error)") }
        }
        if !player.isPlaying { player.play() }
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
    private func connect(model: String, secret: String) {
        var req = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime?model=\(model)")!)
        req.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.webSocketTask(with: req)
        socket = task
        tapState.set(socket: task)
        task.resume()
        receive()
    }

    private func send(_ event: [String: Any]) {
        guard let socket, let data = try? JSONSerialization.data(withJSONObject: event),
              let text = String(data: data, encoding: .utf8) else { return }
        socket.send(.string(text)) { _ in }
    }

    /// JSON çözme ve ses çözme arka planda; ana iş parçacığına yalnızca hazır olay/tampon gider
    private func receive() {
        let format = outFormat
        socket?.receive { [weak self] result in
            switch result {
            case .failure:
                Task { @MainActor in
                    guard let self else { return }
                    if self.phase != .ended { self.phase = .failed("connection"); self.stop() }
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
                Task { @MainActor in self?.receive() }
            }
        }
    }

    private func handle(_ e: [String: Any]) {
        let type = e["type"] as? String ?? ""
        if silentCardActive || silentCardPending { voiceLog.info("silent event: \(type, privacy: .public)") }
        switch type {
        case "session.created", "session.updated":
            if phase == .connecting {
                phase = .listening
                // Sunucu ses algılaması kapalı: yalnızca basılı tutunca dinlenir
                send(["type": "session.update", "session": ["type": "realtime", "audio": ["input": ["turn_detection": NSNull()]]]])
                // AI ilk sözü alsın (karşılama) — serbest sohbette öğrenci başlar
                if aiSpeaksFirst { send(["type": "response.create"]) }
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
            let args = (e["arguments"] as? String).flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
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
            if name == "show_phrase" {
                phraseShownThisResponse = true
                currentCard = args["phrase"] as? String
                voiceLog.info("card: \(self.currentCard ?? "", privacy: .public)")
                if ((args["translation"] as? String) ?? "").trimmingCharacters(in: .whitespaces).isEmpty, let p = currentCard {
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
            if silentCardActive { silentCardActive = false; translationPending = nil; break }
            voiceLog.info("tutor said: \(self.fullAIText, privacy: .public)")
            responseFinished = true
            audioComplete = true
            ensurePhraseCard()
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
    private var aiSpeaksFirst = true

    /// Çevirisiz gösterilen kart: cevap bitince çevirisi sessizce istenir
    private var translationPending: String?
    /// Kartlar yalnızca öğrencinin cevabı olabilir (soru kartı reddedilir) — onboarding demosu
    var answerCardsOnly = false
    /// Pro kullanıcıya süre bitiminde satın alma önerilmez
    var isPro = false
    private var silentCardPending = false
    private var cardTool: [String: Any]?
    private var silentCardActive = false

    /// Öğretmen turu kartsız bitirdiyse: sesi olmayan bir cevapla yalnızca kartı iste (kullanıcı ne diyeceğini hep görsün)
    private func requestCard(answerTo question: String? = nil, translating phrase: String? = nil) {
        guard !silentCardPending, !silentCardActive, let cardTool else { return }
        let native = Locale(identifier: "en").localizedString(forLanguageCode: OL.nativeLangCode) ?? "the learner's native language"
        let instructions = phrase.map {
            "Do not say anything. Call show_phrase with exactly this phrase: \"\($0)\" and its natural translation into \(native)."
        } ?? question.map {
            "Do not say anything. You just said: \"\($0)\". Call show_phrase with a short example ANSWER the learner can say back to you (in the target language, first person, e.g. \"I'm 25 years old.\"), never a question, and its translation."
        } ?? "Do not say anything. Call show_phrase with the exact short line the learner should say next in the target language (a model answer, use ... for their own info) and its translation."
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
    nonisolated static func stripToolText(_ s: String) -> String {
        var t = s.replacingOccurrences(of: #"show_phrase\s*\([^)]*\)?"#, with: "", options: .regularExpression)
        if let r = t.range(of: "show_phrase") { t = String(t[..<r.lowerBound]) }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Her tur bir kartla bitmeli (Pingo gibi). Model aracı çağırmadıysa: metne yazdığı komutu ya da
    /// son tırnak içindeki ifadeyi kart yap.
    private func ensurePhraseCard() {
        guard !phraseShownThisResponse, !pendingToolFollowUp, !rawAIText.isEmpty, !lessonComplete, !timeUp else { return }
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
            let target = (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased()
            let quotes = fullAIText.matches(of: try! Regex(#"[“"]([^"“”]{2,80})[”"]"#))
                .compactMap { $0.output[1].substring.map(String.init) }
            // Ana dilde olmayan son alıntı (isim geçen kısa cümleler yanlış dil sanılabiliyor)
            let native = OL.nativeLangCode.lowercased()
            phrase = quotes.last { q in
                let r = NLLanguageRecognizer()
                r.processString(q)
                guard let lang = r.dominantLanguage?.rawValue else { return true }
                return lang.hasPrefix(target) || !lang.hasPrefix(native)
            }
        }
        guard let phrase, !phrase.trimmingCharacters(in: .whitespaces).isEmpty else {
            requestCard()
            return
        }
        phraseShownThisResponse = true
        currentCard = phrase
        voiceLog.info("card: \(phrase, privacy: .public)")
        _ = onToolCall?("show_phrase", ["phrase": phrase, "translation": translation])
        if translation.trimmingCharacters(in: .whitespaces).isEmpty { requestCard(translating: phrase) }
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

    private func reportUsage(final: Bool) {
        guard let sessionId else { return }
        lastUsageReport = elapsedSeconds
        let seconds = elapsedSeconds
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
