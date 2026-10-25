//
//  AIEngine.swift
//  WordRemSwiftUI
//
//  Yapay zekâ özellikleri Apple'ın cihaz üstü modeliyle (Foundation Models, iOS 26+) çalışır:
//  ücretsiz, API anahtarı yok, internet gerekmez, veri cihazdan çıkmaz.
//  Apple Intelligence olmayan cihazlarda `isAvailable` false döner ve AI girişleri gizlenir.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum AIEngine {

    enum AIError: LocalizedError {
        case unavailable
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .unavailable:   return AL.s(.hcAIServiceError)
            case .emptyResponse: return AL.s(.hcAIEmptyResponse)
            }
        }
    }

    /// Cihazda Apple Intelligence modeli kullanılabilir mi
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    /// Tek seferlik istek. `history` önceki konuşma turları: role "user" | "assistant".
    static func complete(instructions: String,
                         prompt: String,
                         history: [(role: String, content: String)] = [],
                         temperature: Double = 0.7) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            var fullPrompt = prompt
            if !history.isEmpty {
                let transcript = history
                    .map { "\($0.role == "assistant" ? "Teacher" : "Student"): \($0.content)" }
                    .joined(separator: "\n")
                fullPrompt = "Conversation so far:\n\(transcript)\n\nStudent: \(prompt)"
            }
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: fullPrompt,
                                                     options: GenerationOptions(temperature: temperature))
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw AIError.emptyResponse }
            return text
        }
        #endif
        throw AIError.unavailable
    }

    /// Model cevabı bazen ```json … ``` içinde gelir; temizleyip Data döndürür
    static func jsonData(from text: String) -> Data? {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        if let start = s.firstIndex(where: { $0 == "{" || $0 == "[" }),
           let end = s.lastIndex(where: { $0 == "}" || $0 == "]" }), start <= end {
            s = String(s[start...end])
        }
        return s.data(using: .utf8)
    }
}
