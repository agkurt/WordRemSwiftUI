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
    private var micMuted = true
    private var holdStartedAt: Date?
    /// AI konuşurken (ve bitişinden kısa süre sonra) mikrofon sunucuya gitmez:
    /// hoparlörden çıkan ses mikrofona geri girip "kullanıcı konuştu" sanılmasın.
    private var echoGuardUntil = Date.distantPast
    private var aiAudible: Bool { scheduledSamples > 0 || Date() < echoGuardUntil }

    private var fullAIText = ""            // gelen transkript (sesten önde)
    private var scheduledSamples: Double = 0
    private var playbackStart: AVAudioTime?
    /// Ses motoru durursa altyazı yine ilerlesin diye duvar saati yedeği
    private var playbackWallStart: Date?
    private var audioObservers: [NSObjectProtocol] = []
    private var captionTimer: Timer?
    private var clock: Timer?
    private var lastUsageReport = 0
    private var currentUserTurnId: UUID?

    // MARK: - Lifecycle
    func start(instructions: String, tools: [[String: Any]]) async {
        guard phase == .idle || phase == .ended || { if case .failed = phase { return true }; return false }() else { return }
        phase = .connecting
        turns = []; caption = ""; elapsedSeconds = 0; lastUsageReport = 0
        do {
            let grant = try await VoiceBackend.shared.createSession(instructions: instructions, tools: tools)
            sessionId = grant.sessionId
            allowedSeconds = grant.allowedSeconds
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
        try s.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try s.setActive(true)

        try? engine.inputNode.setVoiceProcessingEnabled(true)   // yankı engelleme: AI kendi sesini duymasın
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
        converter = AVAudioConverter(from: inFormat, to: wireFormat)
        input.installTap(onBus: 0, bufferSize: 2400, format: inFormat) { [weak self] buffer, _ in
            guard let self else { return }
            let level = Self.rms(buffer)
            Task { @MainActor in self.handleMic(buffer, level: level) }
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

    private func handleMic(_ buffer: AVAudioPCMBuffer, level: Float) {
        inputLevel = level
        guard !micMuted, socket != nil, let converter else { return }
        if aiAudible && !isHoldingToTalk { return }
        let ratio = wireFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
        guard let out = AVAudioPCMBuffer(pcmFormat: wireFormat, frameCapacity: capacity) else { return }
        var fed = false
        var err: NSError?
        converter.convert(to: out, error: &err) { _, status in
            if fed { status.pointee = .noDataNow; return nil }
            fed = true; status.pointee = .haveData; return buffer
        }
        guard err == nil, out.frameLength > 0, let ch = out.int16ChannelData else { return }
        let data = Data(bytes: ch[0], count: Int(out.frameLength) * 2)
        send(["type": "input_audio_buffer.append", "audio": data.base64EncodedString()])
    }

    private func playAudio(base64: String) {
        guard let data = Data(base64Encoded: base64), data.count >= 2,
              let buf = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: AVAudioFrameCount(data.count / 2)),
              let dst = buf.floatChannelData?[0] else { return }
        let n = data.count / 2
        data.withUnsafeBytes { raw in
            let src = raw.bindMemory(to: Int16.self)
            for i in 0..<n { dst[i] = Float(Int16(littleEndian: src[i])) / 32768 }
        }
        buf.frameLength = AVAudioFrameCount(n)
        restartAudioIfNeeded()
        if playbackStart == nil {
            playbackStart = player.lastRenderTime
            playbackWallStart = Date()
            startCaptionTimer()
        }
        scheduledSamples += Double(n)
        player.scheduleBuffer(buf, completionHandler: nil)
        if phase != .aiSpeaking { phase = .aiSpeaking }
    }

    /// Kullanıcı araya girince AI'ın sesini hemen kes
    private func stopPlayback() {
        player.stop(); player.play()
        scheduledSamples = 0; playbackStart = nil; playbackWallStart = nil
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
        // Çalınan örnek sayısı; motor çalışmıyorsa duvar saatine göre tahmin et
        var playedSamples: Double = 0
        if engine.isRunning, let node = player.lastRenderTime, let t = player.playerTime(forNodeTime: node), t.sampleTime > 0 {
            playedSamples = Double(t.sampleTime)
        } else if let start = playbackWallStart {
            playedSamples = Date().timeIntervalSince(start) * outFormat.sampleRate
        }
        let played = min(1, playedSamples / scheduledSamples)
        captionFull = fullAIText
        let target = Self.wordBoundary(in: fullAIText, upTo: Int(Double(fullAIText.count) * played))
        if target > caption.count { caption = String(fullAIText.prefix(target)) }
        if played >= 0.999 && responseFinished {
            caption = fullAIText; captionFull = fullAIText
            captionTimer?.invalidate()
            scheduledSamples = 0; playbackStart = nil; playbackWallStart = nil
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

    private static func rms(_ buffer: AVAudioPCMBuffer) -> Float {
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
        task.resume()
        receive()
    }

    private func send(_ event: [String: Any]) {
        guard let socket, let data = try? JSONSerialization.data(withJSONObject: event),
              let text = String(data: data, encoding: .utf8) else { return }
        socket.send(.string(text)) { _ in }
    }

    private func receive() {
        socket?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .failure:
                    if self.phase != .ended { self.phase = .failed("connection"); self.stop() }
                case .success(let message):
                    if case .string(let text) = message,
                       let data = text.data(using: .utf8),
                       let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.handle(event)
                    }
                    self.receive()
                }
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
            fullAIText = ""; caption = ""; captionFull = ""; responseFinished = false
            responseCount += 1
            turns.append(Turn(role: .ai, text: ""))

        case "response.output_audio.delta", "response.audio.delta":
            if let d = e["delta"] as? String { playAudio(base64: d) }

        case "response.output_audio_transcript.delta", "response.audio_transcript.delta":
            if let d = e["delta"] as? String {
                fullAIText += d
                if let i = turns.lastIndex(where: { $0.role == .ai }) { turns[i].text = fullAIText }
            }

        case "response.function_call_arguments.done":
            let name = e["name"] as? String ?? ""
            let callId = e["call_id"] as? String ?? ""
            let args = (e["arguments"] as? String).flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
            let output = onToolCall?(name, args) ?? "ok"
            send(["type": "conversation.item.create",
                  "item": ["type": "function_call_output", "call_id": callId, "output": output]])
            // Kart gösterildiyse sıra kullanıcıda: AI'ı tekrar konuşturma (yoksa kendi kendine devam eder).
            // Diğer araçlarda yalnızca AI bu yanıtta hiç konuşmadıysa devam ettir.
            if name != "show_phrase" && name != "finish_lesson" && fullAIText.isEmpty {
                pendingToolFollowUp = true
            }

        case "response.done":
            responseFinished = true
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

    // MARK: - Süre & kullanım
    private func startClock() {
        clock?.invalidate()
        clock = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickClock() }
        }
    }

    private func tickClock() {
        guard phase != .connecting, phase != .ended else { return }
        elapsedSeconds += 1
        if elapsedSeconds - lastUsageReport >= 30 { reportUsage(final: false) }
        if allowedSeconds > 0 && elapsedSeconds == max(0, allowedSeconds - 30) {
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
