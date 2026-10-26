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

@MainActor
final class RealtimeVoiceSession: ObservableObject {

    enum Phase: Equatable {
        case idle, connecting, listening, userSpeaking, thinking, aiSpeaking, ended
        case failed(String)
    }

    struct Turn: Identifiable, Equatable {
        enum Role { case ai, user }
        let id = UUID()
        let role: Role
        var text: String
    }

    // MARK: - Published
    @Published private(set) var phase: Phase = .idle
    /// Şu anki AI konuşmasının ekranda görünen kısmı (sesle senkron açılır)
    @Published private(set) var caption: String = ""
    /// Şu anki AI cevabının tamamı (altyazıda sıradaki kelimeyi soluk göstermek için)
    @Published private(set) var captionFull: String = ""
    /// Her yeni AI cevabında artar (ekrandaki kartı kaldırmak için)
    @Published private(set) var responseCount = 0
    /// Tüm konuşma (Transkript çekmecesi için)
    @Published private(set) var turns: [Turn] = []
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var allowedSeconds: Int = 0
    /// Bas-konuş modu (ifade kartı tekrarında)
    @Published private(set) var pushToTalk = true
    @Published private(set) var isHoldingToTalk = false
    /// Giriş ses seviyesi 0…1 (dinleme animasyonu için)
    @Published private(set) var inputLevel: Float = 0

    /// AI bir araç çağırdığında: (ad, JSON argümanlar) → çıktı metni
    var onToolCall: ((String, [String: Any]) -> String)?
    var onLimitReached: (() -> Void)?

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
    private var currentUserTurnId: UUID?

    // MARK: - Lifecycle
    func start(instructions: String, tools: [[String: Any]]) async {
        guard phase == .idle || phase == .ended || { if case .failed = phase { return true }; return false }() else { return }
        phase = .connecting
        turns = []; caption = ""; elapsedSeconds = 0; lastUsageReport = 0; wallSeconds = 0; warnedTimeUp = false
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
        if let start = holdStartedAt, Date().timeIntervalSince(start) < 0.35 {
            send(["type": "input_audio_buffer.clear"])
            phase = .listening
            return
        }
        send(["type": "input_audio_buffer.commit"])
        send(["type": "response.create"])
        phase = .thinking
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

    private func playAudio(_ buf: AVAudioPCMBuffer) {
        let n = Int(buf.frameLength)
        restartAudioIfNeeded()
        if playbackStart == nil {
            playbackStart = player.lastRenderTime
            playbackWallStart = Date()
            startCaptionTimer()
        }
        scheduledSamples += Double(n)
        // Gerçekten hoparlörden çıkan örnekleri say (oynatıcı saati sessizlikte de ilerlediği için güvenilmez)
        let gen = playbackGeneration
        player.scheduleBuffer(buf, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.playbackGeneration == gen else { return }
                self.playedSamples += Double(n)
            }
        }
        if phase != .aiSpeaking { phase = .aiSpeaking }
    }

    /// Bu cevabın çalınmış örnek sayısı; stopPlayback'te nesil değişir, eski geri çağrılar sayılmaz
    private var playedSamples: Double = 0
    private var playbackGeneration = 0
    /// Ses üretimi bitti mi (bu andan itibaren yazı/ses oranı kesin)
    private var audioComplete = false
    /// Öğretmenin ölçülen konuşma hızı (karakter/sn); her cevapta güncellenir
    private var charsPerSecond = 14.0

    /// Kullanıcı araya girince AI'ın sesini hemen kes
    private func stopPlayback() {
        playbackGeneration += 1
        player.stop(); player.play()
        scheduledSamples = 0; playedSamples = 0; playbackStart = nil; playbackWallStart = nil
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
        // Gerçekten çalınan örnekler; motor durduysa duvar saatine göre tahmin
        var done = playedSamples
        if !engine.isRunning, let start = playbackWallStart {
            done = max(done, Date().timeIntervalSince(start) * outFormat.sampleRate)
        }
        let played = min(1, done / scheduledSamples)
        captionFull = fullAIText
        // Altyazı sesle aynı hızda: cevap tamamlandıysa toplam süreye oranla, değilse ortalama konuşma hızıyla
        let n = fullAIText.count
        let revealed: Int = audioComplete
            ? Int(Double(n) * played)
            : min(n, Int(done / outFormat.sampleRate * charsPerSecond))
        let target = Self.wordBoundary(in: fullAIText, upTo: revealed)
        if target > caption.count { caption = String(fullAIText.prefix(target)) }
        if played >= 0.999 && responseFinished && audioComplete {
            // Ölçülen hızı bir sonraki cevabın ilk saniyeleri için sakla
            let seconds = scheduledSamples / outFormat.sampleRate
            if seconds > 1.5, n > 10 { charsPerSecond = 0.6 * charsPerSecond + 0.4 * Double(n) / seconds }
            caption = fullAIText; captionFull = fullAIText
            captionTimer?.invalidate()
            scheduledSamples = 0; playedSamples = 0; playbackGeneration += 1
            playbackStart = nil; playbackWallStart = nil
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
        switch type {
        case "session.created", "session.updated":
            if phase == .connecting {
                phase = .listening
                // Sunucu ses algılaması kapalı: yalnızca basılı tutunca dinlenir
                send(["type": "session.update", "session": ["type": "realtime", "audio": ["input": ["turn_detection": NSNull()]]]])
                // AI ilk sözü alsın (karşılama)
                send(["type": "response.create"])
            }

        case "input_audio_buffer.speech_started":
            stopPlayback()
            send(["type": "response.cancel"])
            phase = .userSpeaking

        case "input_audio_buffer.speech_stopped":
            phase = .thinking

        case "conversation.item.input_audio_transcription.completed":
            let t = (e["transcript"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { turns.append(Turn(role: .user, text: t)) }

        case "response.created":
            fullAIText = ""; rawAIText = ""; phraseShownThisResponse = false; audioComplete = false
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
            if name == "show_phrase" { phraseShownThisResponse = true }
            let output = onToolCall?(name, args) ?? "ok"
            send(["type": "conversation.item.create",
                  "item": ["type": "function_call_output", "call_id": callId, "output": output]])
            // Kart gösterildiyse sıra kullanıcıda: AI'ı tekrar konuşturma (yoksa kendi kendine devam eder).
            // Diğer araçlarda yalnızca AI bu yanıtta hiç konuşmadıysa devam ettir.
            if name != "show_phrase" && name != "finish_lesson" && fullAIText.isEmpty {
                pendingToolFollowUp = true
            }

        case "response.output_audio.done", "response.audio.done":
            audioComplete = true

        case "response.done":
            responseFinished = true
            audioComplete = true
            ensurePhraseCard()
            if pendingToolFollowUp {
                pendingToolFollowUp = false
                send(["type": "response.create"])
            } else if scheduledSamples == 0 {
                caption = fullAIText; captionFull = fullAIText
                phase = .listening
            }

        case "error":
            let msg = (e["error"] as? [String: Any])?["message"] as? String ?? "error"
            print("⚠️ Realtime error: \(msg)")

        default:
            break
        }
    }

    private var pendingToolFollowUp = false

    /// Küçük model kart komutunu bazen düz metin olarak yazar: ekranda/transkriptte gösterme
    nonisolated static func stripToolText(_ s: String) -> String {
        var t = s.replacingOccurrences(of: #"show_phrase\s*\([^)]*\)?"#, with: "", options: .regularExpression)
        if let r = t.range(of: "show_phrase") { t = String(t[..<r.lowerBound]) }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Her tur bir kartla bitmeli (Pingo gibi). Model aracı çağırmadıysa: metne yazdığı komutu ya da
    /// son tırnak içindeki ifadeyi kart yap.
    private func ensurePhraseCard() {
        guard !phraseShownThisResponse, !pendingToolFollowUp, !rawAIText.isEmpty else { return }
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
            phrase = quotes.last { q in
                let r = NLLanguageRecognizer()
                r.processString(q)
                return r.dominantLanguage?.rawValue.hasPrefix(target) ?? false
            }
        }
        guard let phrase, !phrase.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        phraseShownThisResponse = true
        _ = onToolCall?("show_phrase", ["phrase": phrase, "translation": translation])
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
            onLimitReached?(); stop(); return
        }
        if allowedSeconds > 0 && !warnedTimeUp && elapsedSeconds >= max(0, allowedSeconds - 30) {
            warnedTimeUp = true
            // 30 sn kala AI'dan kibarca toparlamasını iste
            send(["type": "conversation.item.create",
                  "item": ["type": "message", "role": "system",
                           "content": [["type": "input_text", "text": "Time is almost up. In one or two short sentences, praise the learner and say goodbye."]]]])
            send(["type": "response.create"])
        }
        if allowedSeconds > 0 && elapsedSeconds >= allowedSeconds {
            onLimitReached?()
            stop()
        }
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
    func set(socket: URLSessionWebSocketTask?) { lock.lock(); self.socket = socket; lock.unlock() }
    /// Mikrofon akışı açıksa gönderilecek soket
    var streamingSocket: URLSessionWebSocketTask? { lock.lock(); defer { lock.unlock() }; return stream ? socket : nil }
}
