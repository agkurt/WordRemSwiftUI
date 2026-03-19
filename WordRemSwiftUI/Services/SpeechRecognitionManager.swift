//
//  SpeechRecognitionManager.swift
//  WordRemSwiftUI
//
//  Ses tanıma — AVAudioRecorder ile kayıt alır, OpenAI Whisper API ile
//  hedef dile özgü transkripsiyon yapar. Cihaz diline bağlı olmadığından
//  Fransızca söylenen kelimeyi Türkçeye çevirmez.
//

import Foundation
import AVFoundation

@MainActor
final class SpeechRecognitionManager: ObservableObject {

    static let shared = SpeechRecognitionManager()

    @Published var recognizedText: String = ""
    @Published var isRecording: Bool      = false
    @Published var isProcessing: Bool     = false   // true while Whisper API call is in flight
    @Published var micPermission: AVAudioSession.RecordPermission = AVAudioSession.sharedInstance().recordPermission

    private var audioRecorder: AVAudioRecorder?
    private var tempFileURL: URL?
    private var currentLangCode: String = "EN"

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
            AVSampleRateKey:          16000,          // Whisper prefers 16 kHz
            AVNumberOfChannelsKey:    1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        isRecording = true
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording   = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let url = tempFileURL else { return }
        tempFileURL = nil

        isProcessing = true
        Task {
            let result = await transcribeWithWhisper(fileURL: url, langCode: currentLangCode)
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

    // MARK: - Whisper API

    private func transcribeWithWhisper(fileURL: URL, langCode: String) async -> String {
        let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.setValue("Bearer \(APIKey.geminiApi)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let audioData = try? Data(contentsOf: fileURL) else { return "" }

        var body = Data()
        let iso = whisperISO(langCode)

        body.appendField("model", value: "whisper-1", boundary: boundary)
        body.appendField("language", value: iso, boundary: boundary)
        body.appendField("response_format", value: "text", boundary: boundary)
        body.appendFilePart(name: "file", filename: "speech.m4a",
                            mimeType: "audio/m4a", data: audioData, boundary: boundary)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        req.httpBody = body

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              let text = String(data: data, encoding: .utf8) else {
            return ""
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    private func whisperISO(_ code: String) -> String {
        switch code.uppercased() {
        case "FR": return "fr"
        case "DE": return "de"
        case "ES": return "es"
        case "IT": return "it"
        case "RU": return "ru"
        case "ZH": return "zh"
        case "TR": return "tr"
        case "JA": return "ja"
        case "KO": return "ko"
        case "PT": return "pt"
        default:   return "en"
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

// MARK: - Multipart helpers

private extension Data {
    mutating func appendField(_ name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendFilePart(name: String, filename: String,
                                  mimeType: String, data fileData: Data, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(fileData)
        append("\r\n".data(using: .utf8)!)
    }
}
