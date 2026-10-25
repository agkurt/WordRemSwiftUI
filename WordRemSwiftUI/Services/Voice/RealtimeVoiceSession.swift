//
//  RealtimeVoiceSession.swift
//  WordRemSwiftUI
//
//  Sesli öğretmen motoru. Akış:
//   1) VoiceBackend'den kısa ömürlü OpenAI anahtarı + izin verilen süre alınır (dakika sınırı sunucuda).
//   2) OpenAI Realtime'a WebSocket ile bağlanılır; mikrofon 24 kHz PCM16 olarak akıtılır.
//   3) AI'ın sesi akış halinde çalınır, altyazı çalınan sesle aynı hızda açılır.
//   4) AI'ın araç çağrıları (ifade kartı göster, kelimeyi kullandı…) `onToolCall` ile uygulamaya iletilir.
//  Konuşma modu: sunucu tarafı ses algılama (eller serbest). Kart modu: basılı tut → bırak → gönder.
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
    /// Tüm konuşma (Transkript çekmecesi için)
    @Published private(set) var turns: [Turn] = []
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var allowedSeconds: Int = 0
    /// Bas-konuş modu (ifade kartı tekrarında)
    @Published private(set) var pushToTalk = false
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
    private var micMuted = false

    private var fullAIText = ""            // gelen transkript (sesten önde)
    private var scheduledSamples: Double = 0
    private var playbackStart: AVAudioTime?
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
        player.stop()
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        caption = fullAIText
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
        guard pushToTalk else { return }
        stopPlayback()
        send(["type": "input_audio_buffer.clear"])
        micMuted = false
        isHoldingToTalk = true
        phase = .userSpeaking
    }

    func endHold() {
        guard pushToTalk, isHoldingToTalk else { return }
        isHoldingToTalk = false
        micMuted = true
        send(["type": "input_audio_buffer.commit"])
        send(["type": "response.create"])
        phase = .thinking
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

        let input = engine.inputNode
        try? input.setVoiceProcessingEnabled(true)       // yankı engelleme: AI kendi sesini duymasın
        let inFormat = input.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inFormat, to: wireFormat)

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: outFormat)

        input.installTap(onBus: 0, bufferSize: 2400, format: inFormat) { [weak self] buffer, _ in
            guard let self else { return }
            let level = Self.rms(buffer)
            Task { @MainActor in self.handleMic(buffer, level: level) }
        }
        engine.prepare()
        try engine.start()
        player.play()
    }

    private func handleMic(_ buffer: AVAudioPCMBuffer, level: Float) {
        inputLevel = level
        guard !micMuted, socket != nil, let converter else { return }
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
        if playbackStart == nil { playbackStart = player.lastRenderTime; startCaptionTimer() }
        scheduledSamples += Double(n)
        player.scheduleBuffer(buf, completionHandler: nil)
        if phase != .aiSpeaking { phase = .aiSpeaking }
    }

    /// Kullanıcı araya girince AI'ın sesini hemen kes
    private func stopPlayback() {
        player.stop(); player.play()
        scheduledSamples = 0; playbackStart = nil
        captionTimer?.invalidate()
        if !fullAIText.isEmpty { caption = fullAIText }
    }

    /// Altyazı, çalınan ses kadar açılır (Pingo tarzı karaoke)
    private func startCaptionTimer() {
        captionTimer?.invalidate()
        captionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickCaption() }
        }
    }

    private func tickCaption() {
        guard scheduledSamples > 0,
              let node = player.lastRenderTime, let t = player.playerTime(forNodeTime: node) else { return }
        let played = min(1, Double(t.sampleTime) / scheduledSamples)
        let target = Int(Double(fullAIText.count) * played)
        if target > caption.count { caption = String(fullAIText.prefix(target)) }
        if played >= 0.999 && responseFinished {
            caption = fullAIText
            captionTimer?.invalidate()
            scheduledSamples = 0; playbackStart = nil
            if phase == .aiSpeaking { phase = pushToTalk ? .listening : .listening }
        }
    }

    private var responseFinished = false

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
            fullAIText = ""; caption = ""; responseFinished = false
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
            pendingToolFollowUp = true

        case "response.done":
            responseFinished = true
            if pendingToolFollowUp {
                pendingToolFollowUp = false
                send(["type": "response.create"])
            } else if scheduledSamples == 0 {
                caption = fullAIText
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
