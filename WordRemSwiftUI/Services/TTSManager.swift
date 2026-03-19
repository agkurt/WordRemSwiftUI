//
//  TTSManager.swift
//  WordRemSwiftUI
//
//  OpenAI TTS API (tts-1-hd, nova voice) kullanarak yüksek kaliteli ses üretir.
//  Ağ yoksa veya API başarısız olursa AVSpeechSynthesizer'a fallback yapar.
//  Aynı kelime için audio data in-memory cache'te tutulur (max 80 giriş).
//

import AVFoundation

final class TTSManager {

    static let shared = TTSManager()

    // MARK: - Private state
    private var audioPlayer: AVAudioPlayer?
    private let fallback = AVSpeechSynthesizer()

    /// Cache key: "\(text)|\(langCode)|\(speedTag)"  value: raw MP3 data from OpenAI
    private var cache: [String: Data] = [:]
    private let maxCacheSize = 80

    private init() {}

    // MARK: - Public API

    func speak(_ text: String, langCode: String) {
        stop()
        Task { await playWithOpenAI(text, langCode: langCode, speed: 1.0, speedTag: "normal") }
    }

    func speakSlow(_ text: String, langCode: String) {
        stop()
        Task { await playWithOpenAI(text, langCode: langCode, speed: 0.65, speedTag: "slow") }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        fallback.stopSpeaking(at: .immediate)
    }

    // MARK: - Async / Prefetch API

    /// Async version: awaits until audio is fetched and starts playing.
    /// Useful for showing a loading state in the UI before playback begins.
    func speakAsync(_ text: String, langCode: String) async {
        stop()
        await playWithOpenAI(text, langCode: langCode, speed: 1.0, speedTag: "normal")
    }

    /// Silently fetch and cache audio without playing.
    /// Call this ahead of time so the word plays instantly when needed.
    func prefetchAsync(_ text: String, langCode: String) async {
        let key = "\(text)|\(langCode)|normal"
        guard cache[key] == nil else { return }
        if let data = await fetchAudio(text: text, speed: 1.0) {
            evictIfNeeded()
            cache[key] = data
        }
    }

    /// Returns true if the audio for this text is already cached (plays instantly).
    func isCached(_ text: String, langCode: String) -> Bool {
        cache["\(text)|\(langCode)|normal"] != nil
    }

    // MARK: - OpenAI TTS

    private func playWithOpenAI(_ text: String, langCode: String, speed: Double, speedTag: String) async {
        let key = "\(text)|\(langCode)|\(speedTag)"

        let audioData: Data
        if let cached = cache[key] {
            audioData = cached
        } else if let fetched = await fetchAudio(text: text, speed: speed) {
            evictIfNeeded()
            cache[key] = fetched
            audioData = fetched
        } else {
            // Fallback: AVSpeechSynthesizer
            await MainActor.run { playFallback(text, langCode: langCode, speed: speed) }
            return
        }

        await MainActor.run { playData(audioData) }
    }

    private func fetchAudio(text: String, speed: Double) async -> Data? {
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var req = URLRequest(url: url)
        req.httpMethod  = "POST"
        req.timeoutInterval = 12
        req.setValue("application/json",          forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(APIKey.geminiApi)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model":  "tts-1",          // tts-1-hd daha kaliteli ama ~2x yavaş; quiz için tts-1 yeterli
            "input":  text,
            "voice":  "nova",           // doğal kadın sesi; alternatifler: shimmer, alloy, onyx, echo
            "speed":  speed,
            "response_format": "mp3"
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        req.httpBody = bodyData

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              !data.isEmpty else {
            return nil
        }

        return data
    }

    // MARK: - Playback

    @MainActor
    private func playData(_ data: Data) {
        configureAudioSession()
        do {
            audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("⚠️ TTSManager AVAudioPlayer error: \(error)")
        }
    }

    // MARK: - Fallback (AVSpeechSynthesizer)

    @MainActor
    private func playFallback(_ text: String, langCode: String, speed: Double) {
        configureAudioSession()
        let utterance   = AVSpeechUtterance(string: text)
        let locale      = bcp47(langCode)
        utterance.rate  = Float(AVSpeechUtteranceDefaultSpeechRate) * Float(speed)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        if #available(iOS 16.0, *) {
            let best = AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language.hasPrefix(locale.components(separatedBy: "-").first ?? locale) }
                .sorted {
                    let order: [AVSpeechSynthesisVoiceQuality] = [.premium, .enhanced, .default]
                    return (order.firstIndex(of: $0.quality) ?? 99) < (order.firstIndex(of: $1.quality) ?? 99)
                }
                .first
            utterance.voice = best ?? AVSpeechSynthesisVoice(language: locale)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: locale)
        }

        fallback.speak(utterance)
    }

    // MARK: - Helpers

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func evictIfNeeded() {
        guard cache.count >= maxCacheSize else { return }
        // Remove a random entry to keep memory bounded
        if let key = cache.keys.randomElement() { cache.removeValue(forKey: key) }
    }

    // MARK: - BCP-47 locale (fallback only)

    func bcp47(_ code: String) -> String {
        switch code.uppercased() {
        case "FR": return "fr-FR"
        case "DE": return "de-DE"
        case "ES": return "es-ES"
        case "IT": return "it-IT"
        case "RU": return "ru-RU"
        case "ZH": return "zh-CN"
        case "TR": return "tr-TR"
        case "JA": return "ja-JP"
        case "KO": return "ko-KR"
        case "PT": return "pt-BR"
        default:   return "en-US"
        }
    }
}
