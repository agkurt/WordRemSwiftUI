//
//  SpeechRecognitionManager.swift
//  WordRemSwiftUI
//
//  Ses tanıma — AVAudioRecorder ile kayıt alır, Apple Speech ile hedef dilin
//  yerel ayarında yazıya döker (mümkünse cihaz üstünde). Cihaz diline bağlı
//  olmadığından Fransızca söylenen kelimeyi Türkçeye çevirmez.
//

import Foundation
import AVFoundation
import Speech

@MainActor
final class SpeechRecognitionManager: ObservableObject {

    static let shared = SpeechRecognitionManager()

    @Published var recognizedText: String = ""
    @Published var isRecording: Bool      = false
    @Published var isProcessing: Bool     = false   // true while transcription is running
    @Published var micPermission: AVAudioSession.RecordPermission = AVAudioSession.sharedInstance().recordPermission

    private var audioRecorder: AVAudioRecorder?
    private var tempFileURL: URL?
    private var currentLangCode: String = "EN"
    private var silenceTimer: Timer?
    private var autoStopTimer: Timer?
    var onAutoStop: (() -> Void)?   // callback when auto-stopped
    private var consecutiveSilenceCount = 0

    private init() {}

    // MARK: - Permission

    func requestMicPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] _ in
            DispatchQueue.main.async {
                self?.micPermission = AVAudioSession.sharedInstance().recordPermission
            }
        }
    }

    // MARK: - Recording

    func startRecording(langCode: String) throws {
        recognizedText  = ""
        currentLangCode = langCode

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        tempFileURL = url

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let settings: [String: Any] = [
            AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey:          16000,          // speech recognizers prefer 16 kHz
            AVNumberOfChannelsKey:    1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        isRecording = true
        audioRecorder?.isMeteringEnabled = true
        // Auto-stop after 6 seconds max
        autoStopTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
            guard let self, self.isRecording else { return }
            Task { @MainActor in
                self.stopRecording()
                self.onAutoStop?()
            }
        }
        // Silence detection: check every 0.3s, stop after 1.5s of silence
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.audioRecorder, self.isRecording else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            if power < -45 { // silence threshold in dB
                self.consecutiveSilenceCount += 1
                if self.consecutiveSilenceCount >= 5 { // 5 * 0.3s = 1.5s silence
                    Task { @MainActor in
                        guard self.isRecording else { return }
                        self.stopRecording()
                        self.onAutoStop?()
                    }
                }
            } else {
                self.consecutiveSilenceCount = 0
            }
        }
    }

    func stopRecording() {
        silenceTimer?.invalidate(); silenceTimer = nil
        autoStopTimer?.invalidate(); autoStopTimer = nil
        consecutiveSilenceCount = 0
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording   = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let url = tempFileURL else { return }
        tempFileURL = nil

        isProcessing = true
        Task {
            let result = await transcribe(fileURL: url, langCode: currentLangCode)
            recognizedText = result
            isProcessing   = false
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Answer Check

    func isCorrect(recognized: String, expected: String) -> Bool {
        let r = recognized.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let e = expected.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if r == e { return true }
        if r.contains(e) || e.contains(r) { return true }
        return levenshteinSimilarity(r, e) >= 0.78
    }

    // MARK: - Apple Speech

    private func transcribe(fileURL: URL, langCode: String) async -> String {
        let authorized: Bool = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        guard authorized,
              let recognizer = SFSpeechRecognizer(locale: Locale(identifier: speechLocale(langCode))),
              recognizer.isAvailable else { return "" }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }

        return await withCheckedContinuation { cont in
            var finished = false
            recognizer.recognitionTask(with: request) { result, error in
                guard !finished else { return }
                if let result, result.isFinal {
                    finished = true
                    cont.resume(returning: result.bestTranscription.formattedString)
                } else if error != nil {
                    finished = true
                    cont.resume(returning: "")
                }
            }
        }
    }

    // MARK: - Helpers

    private func speechLocale(_ code: String) -> String {
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

    private func levenshteinSimilarity(_ a: String, _ b: String) -> Double {
        let la = Array(a), lb = Array(b)
        if la.isEmpty && lb.isEmpty { return 1.0 }
        if la.isEmpty || lb.isEmpty { return 0.0 }
        var prev = Array(0...lb.count)
        for i in 1...la.count {
            var curr = [i] + Array(repeating: 0, count: lb.count)
            for j in 1...lb.count {
                curr[j] = la[i-1] == lb[j-1]
                    ? prev[j-1]
                    : 1 + min(prev[j-1], prev[j], curr[j-1])
            }
            prev = curr
        }
        return 1.0 - Double(prev[lb.count]) / Double(max(la.count, lb.count))
    }
}

