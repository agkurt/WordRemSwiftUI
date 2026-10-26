//
//  VoiceTutorSession.swift
//  WordRemSwiftUI
//
//  Sesli öğretmen motoru (zincirleme, Pingo gibi bas-konuş):
//   1) Kullanıcı basılı tutar → cihazdaki ses tanıma (ücretsiz) konuşmayı yazıya çevirir, canlı gösterir.
//   2) Bırakınca metin sunucuya gider → metin modeli tek bir paket döner: söyleyeceği cümle, kart, çeviri…
//   3) Aynı istekte öğretmenin sesi akarak gelir; altyazı çalınan sesle birebir açılır, kart ses bitince çıkar.
//  Ücret sunucuda, öğretmenin konuşma süresinden hesaplanır.
//

import AVFoundation
import Foundation
import Speech

@MainActor
final class VoiceTutorSession: ObservableObject {

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
    /// Şu anki AI cevabının sesle birlikte açılmış kısmı
    @Published private(set) var caption: String = ""
    /// Şu anki AI cevabının tamamı (sıradaki kelimeyi soluk göstermek için)
    @Published private(set) var captionFull: String = ""
    /// Her yeni AI cevabında artar (ekrandaki kartı kaldırmak için)
    @Published private(set) var responseCount = 0
    @Published private(set) var turns: [Turn] = []
    /// Kullanıcı konuşurken canlı tanınan metin
    @Published private(set) var userPartial: String = ""
    @Published private(set) var isHoldingToTalk = false
    @Published private(set) var inputLevel: Float = 0
    /// Ekranda "kalan dk" için: sunucunun bildirdiği kalan öğretmen konuşma süresi
    @Published private(set) var allowedSeconds: Int = 0
    let elapsedSeconds = 0

    /// Her AI cevabında: kart, kullanılan kelimeler, hafıza, ders bitti mi
    var onReply: ((VoiceBackend.TutorReply) -> Void)?
    var onLimitReached: (() -> Void)?

    // MARK: - Private
    private var instructions = ""
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let outFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false)!
    private let tapState = TapState()
    private var audioObservers: [NSObjectProtocol] = []

    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var finalTranscript: CheckedContinuation<String, Never>?
    private var lastPartial = ""
    private var holdStartedAt: Date?

    private var turnTask: Task<Void, Never>?
    private var fullAIText = ""
    private var scheduledSamples: Double = 0
    private var playedSamples: Double = 0
    private var playbackGeneration = 0
    private var audioFinished = false
    private var playbackWallStart: Date?
    private var captionTimer: Timer?

    // MARK: - Lifecycle

    /// - Parameter history: kaldığı yerden devam için önceki konuşma satırları
    func start(instructions: String, history: [Turn] = []) async {
        guard phase == .idle || phase == .ended || { if case .failed = phase { return true }; return false }() else { return }
        self.instructions = instructions
        phase = .connecting
        turns = history
        caption = ""; captionFull = ""

        guard VoiceBackend.shared.isConfigured else { phase = .failed("not_configured"); return }
        _ = await AVAudioApplication.requestRecordPermission()
        _ = await withCheckedContinuation { c in SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) } }
        recognizer = SFSpeechRecognizer(locale: Self.locale(for: targetCode))

        do { try configureAudio() } catch { phase = .failed("audio"); return }
        requestTurn(userText: nil)
    }

    func stop() {
        guard phase != .ended else { return }
        turnTask?.cancel()
        recognitionTask?.cancel()
        finalTranscript?.resume(returning: "")
        finalTranscript = nil
        tapState.set(request: nil)
        captionTimer?.invalidate()
        audioObservers.forEach(NotificationCenter.default.removeObserver)
        audioObservers = []
        player.stop()
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if !fullAIText.isEmpty { caption = fullAIText; captionFull = fullAIText }
        phase = .ended
    }

    // MARK: - Bas-konuş

    func beginHold() {
        guard phase == .listening || phase == .aiSpeaking || phase == .thinking, let recognizer, recognizer.isAvailable else { return }
        if phase != .listening { interrupt() }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
        lastPartial = ""
        userPartial = ""
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            Task { @MainActor in
                guard let self else { return }
                if let text { self.lastPartial = text; if self.isHoldingToTalk { self.userPartial = text } }
                if isFinal || error != nil {
                    self.finalTranscript?.resume(returning: self.lastPartial)
                    self.finalTranscript = nil
                }
            }
        }
        tapState.set(request: request)
        holdStartedAt = Date()
        isHoldingToTalk = true
        phase = .userSpeaking
    }

    func endHold() {
        guard isHoldingToTalk else { return }
        isHoldingToTalk = false
        inputLevel = 0
        let request = tapState.takeRequest()
        // Çok kısa basış: yok say
        if let start = holdStartedAt, Date().timeIntervalSince(start) < 0.35 {
            recognitionTask?.cancel()
            userPartial = ""
            phase = .listening
            return
        }
        request?.endAudio()
        phase = .thinking
        Task {
            // Son sonuç en geç 1.2 sn içinde; gelmezse eldeki kısmi metinle devam
            let text = await withCheckedContinuation { (c: CheckedContinuation<String, Never>) in
                finalTranscript = c
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    guard let self, let pending = self.finalTranscript else { return }
                    self.finalTranscript = nil
                    pending.resume(returning: self.lastPartial)
                }
            }.trimmingCharacters(in: .whitespacesAndNewlines)
            userPartial = ""
            guard phase == .thinking else { return }
            guard !text.isEmpty else { phase = .listening; return }
            turns.append(Turn(role: .user, text: text))
            requestTurn(userText: text)
        }
    }

    /// Öğretmen konuşurken/düşünürken sözünü kes
    func interrupt() {
        turnTask?.cancel()
        stopPlayback()
        phase = .listening
    }

    // MARK: - Tur: metin modeli + akan ses

    private func requestTurn(userText: String?) {
        turnTask?.cancel()
        phase = .thinking
        let history = turns.dropLast(userText == nil ? 0 : 1).map { (ai: $0.role == .ai, text: $0.text) }
        let stream = VoiceBackend.shared.tutorTurn(instructions: instructions, history: history, userText: userText)
        turnTask = Task { [weak self] in
            do {
                for try await event in stream {
                    guard let self, !Task.isCancelled else { return }
                    switch event {
                    case .reply(let reply, let remaining):
                        self.beginReply(reply, remaining: remaining)
                    case .audio(let data):
                        if let buf = Self.decodePCM(data, format: self.outFormat) { self.playAudio(buf) }
                    }
                }
                guard let self, !Task.isCancelled else { return }
                self.audioFinished = true
                if self.scheduledSamples == 0 { self.finishReply() }   // ses gelmediyse metni hemen göster
            } catch let e as VoiceBackend.Failure {
                guard let self, !Task.isCancelled else { return }
                if e.code == "limit_reached" { self.onLimitReached?() }
                self.phase = .failed(e.code)
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.phase = .failed("network")
            }
        }
    }

    private func beginReply(_ reply: VoiceBackend.TutorReply, remaining: Int) {
        allowedSeconds = remaining
        fullAIText = reply.say
        caption = ""; captionFull = reply.say
        audioFinished = false
        responseCount += 1
        turns.append(Turn(role: .ai, text: reply.say))
        onReply?(reply)
    }

    /// Cevabın sesi bitti: tam metni göster, sıra kullanıcıda
    private func finishReply() {
        captionTimer?.invalidate()
        caption = fullAIText; captionFull = fullAIText
        scheduledSamples = 0; playedSamples = 0; playbackGeneration += 1; playbackWallStart = nil
        if phase == .aiSpeaking || phase == .thinking { phase = .listening }
    }

    // MARK: - Ses

    private func configureAudio() throws {
        let s = AVAudioSession.sharedInstance()
        try s.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
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

    /// Mikrofon tamponları ses iş parçacığında doğrudan tanıma isteğine verilir
    private func installMicTap() {
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }
        let state = tapState
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let request = state.request else { return }
            request.append(buffer)
            let level = Self.rms(buffer)
            Task { @MainActor in self?.inputLevel = level }
        }
    }

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
            try? engine.start()
        }
        if !player.isPlaying { player.play() }
    }

    nonisolated private static func decodePCM(_ data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let n = data.count / 2
        guard n > 0, let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n)),
              let dst = buf.floatChannelData?[0] else { return nil }
        data.withUnsafeBytes { raw in
            let src = raw.bindMemory(to: Int16.self)
            for i in 0..<n { dst[i] = Float(Int16(littleEndian: src[i])) / 32768 }
        }
        buf.frameLength = AVAudioFrameCount(n)
        return buf
    }

    private func playAudio(_ buf: AVAudioPCMBuffer) {
        let n = Double(buf.frameLength)
        restartAudioIfNeeded()
        if playbackWallStart == nil {
            playbackWallStart = Date()
            startCaptionTimer()
        }
        scheduledSamples += n
        // Gerçekten hoparlörden çıkan örnekleri say; kesilince nesil değişir, eski geri çağrılar sayılmaz
        let gen = playbackGeneration
        player.scheduleBuffer(buf, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.playbackGeneration == gen else { return }
                self.playedSamples += n
            }
        }
        if phase != .aiSpeaking { phase = .aiSpeaking }
    }

    private func stopPlayback() {
        playbackGeneration += 1
        player.stop(); player.play()
        scheduledSamples = 0; playedSamples = 0; playbackWallStart = nil
        captionTimer?.invalidate()
        if !fullAIText.isEmpty { caption = fullAIText; captionFull = fullAIText }
    }

    // MARK: - Altyazı: çalınan sesle birebir

    private func startCaptionTimer() {
        captionTimer?.invalidate()
        captionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickCaption() }
        }
    }

    private func tickCaption() {
        guard scheduledSamples > 0 else { return }
        var done = playedSamples
        if !engine.isRunning, let start = playbackWallStart {
            done = max(done, Date().timeIntervalSince(start) * outFormat.sampleRate)
        }
        let n = fullAIText.count
        // Ses tamamen geldiyse toplam süreye oranla; gelmeye devam ediyorsa ortalama konuşma hızıyla (~14 karakter/sn)
        let revealed = audioFinished
            ? Int(Double(n) * min(1, done / scheduledSamples))
            : min(n, Int(done / outFormat.sampleRate * 14))
        let target = Self.wordBoundary(in: fullAIText, upTo: revealed)
        if target > caption.count { caption = String(fullAIText.prefix(target)) }
        if audioFinished && done >= scheduledSamples { finishReply() }
    }

    /// Altyazı kelime kelime açılsın
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

    // MARK: - Dil
    private var targetCode: String { (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased() }

    private static func locale(for code: String) -> Locale {
        let map = ["en": "en-US", "de": "de-DE", "fr": "fr-FR", "es": "es-ES", "it": "it-IT",
                   "ru": "ru-RU", "zh": "zh-CN", "tr": "tr-TR"]
        return Locale(identifier: map[code] ?? code)
    }
}

/// Ses iş parçacığı ile ana iş parçacığı arasında paylaşılan tanıma isteği (kilitli)
final class TapState: @unchecked Sendable {
    private let lock = NSLock()
    private var current: SFSpeechAudioBufferRecognitionRequest?

    var request: SFSpeechAudioBufferRecognitionRequest? { lock.lock(); defer { lock.unlock() }; return current }
    func set(request: SFSpeechAudioBufferRecognitionRequest?) { lock.lock(); current = request; lock.unlock() }
    func takeRequest() -> SFSpeechAudioBufferRecognitionRequest? {
        lock.lock(); defer { lock.unlock() }
        let r = current; current = nil; return r
    }
}
