//
//  OpenAIQuizService.swift
//  WordRemSwiftUI
//
//  OpenAI chat/completions kullanarak gramer konularında quiz soruları üretir.
//  Model: gpt-4o-mini  |  Response format: JSON
//

import Foundation

// MARK: - OpenAI Response Models

private struct OAIRequest: Encodable {
    let model: String
    let messages: [OAIMessage]
    let response_format: OAIResponseFormat
    let temperature: Double
}

private struct OAIMessage: Encodable {
    let role: String
    let content: String
}

private struct OAIResponseFormat: Encodable {
    let type: String          // "json_object"
}

private struct OAIResponse: Decodable {
    let choices: [OAIChoice]
}

private struct OAIChoice: Decodable {
    let message: OAIChoiceMessage
}

private struct OAIChoiceMessage: Decodable {
    let content: String
}

// MARK: - AI Question Model (JSON parse için)

struct AIRawQuestion: Decodable {
    let mode: String
    let question: String
    let options: [String]?        // writing modunda null/eksik gelebilir
    let correct_answer: String?   // writing modunda eksik gelebilir
    let explanation: String?
    let instruction: String?      // writing modunda kullanılır
}

private struct AIQuestionList: Decodable {
    let questions: [AIRawQuestion]
}

// MARK: - Service

final class OpenAIQuizService {

    static let shared = OpenAIQuizService()
    private init() {}

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    // MARK: - API Key (ApiKey-Info.plist → GeminiApi key'inden okunur)
    private var apiKey: String { APIKey.geminiApi }
    var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Custom Errors
    enum OAIError: LocalizedError {
        case missingAPIKey
        case httpError(Int, String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "OpenAI API key eksik. Lütfen ayarlardan girin."
            case .httpError(let code, let msg):
                return "OpenAI hatası (\(code)): \(msg)"
            case .emptyResponse:
                return "Sunucu boş yanıt döndürdü."
            }
        }
    }

    /// Verilen konu ve soru sayısı için GameQuestion dizisi üretir.
    func generateQuestions(
        topic: AIQuizTopic,
        count: Int,
        targetLang: String,
        nativeLang: String,
        langCode: String = "en"
    ) async throws -> [GameQuestion] {

        guard hasAPIKey else { throw OAIError.missingAPIKey }

        let prompt = buildPrompt(topic: topic, count: count,
                                 targetLang: targetLang, nativeLang: nativeLang,
                                 langCode: langCode)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body = OAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OAIMessage(role: "system", content: systemPrompt(nativeLang: nativeLang, targetLang: targetLang)),
                OAIMessage(role: "user",   content: prompt)
            ],
            response_format: OAIResponseFormat(type: "json_object"),
            temperature: 0.7
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OAIError.emptyResponse
        }
        guard http.statusCode == 200 else {
            // OpenAI hata mesajını parse et
            let raw = String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
            let friendly: String
            switch http.statusCode {
            case 401: friendly = "Geçersiz API key. Lütfen doğru anahtarı girin."
            case 429: friendly = "Rate limit aşıldı. Birkaç saniye bekleyip tekrar deneyin."
            case 400: friendly = "Geçersiz istek: \(raw)"
            default:  friendly = "HTTP \(http.statusCode): \(raw)"
            }
            throw OAIError.httpError(http.statusCode, friendly)
        }

        let oaiResp = try JSONDecoder().decode(OAIResponse.self, from: data)
        guard let content = oaiResp.choices.first?.message.content else {
            throw OAIError.emptyResponse
        }

        // Debug: API'den gelen ham JSON'u logla
        print("📝 OpenAI raw content:\n\(content)")

        // Bazen model cevabı ```json ... ``` içinde sarıyor, temizle
        let cleaned = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw OAIError.emptyResponse
        }

        do {
            let list = try JSONDecoder().decode(AIQuestionList.self, from: jsonData)
            return list.questions.map { convert($0, topic: topic) }
        } catch {
            print("❌ JSON decode error: \(error)")
            print("❌ Raw cleaned JSON: \(cleaned)")
            throw error
        }
    }

    // MARK: - Language Code → Full Name
    private static let langNames: [String: String] = [
        "en": "English", "tr": "Turkish", "de": "German", "fr": "French",
        "es": "Spanish", "it": "Italian", "ru": "Russian", "ja": "Japanese",
        "ko": "Korean",  "zh": "Chinese", "pt": "Portuguese", "ar": "Arabic",
        "nl": "Dutch",   "pl": "Polish",  "sv": "Swedish",    "da": "Danish"
    ]

    func fullLangName(for code: String) -> String {
        Self.langNames[code.lowercased()]
            ?? Locale.current.localizedString(forLanguageCode: code)
            ?? code.uppercased()
    }

    // MARK: - Prompt Builder

    private func systemPrompt(nativeLang: String, targetLang: String) -> String {
        """
        You are a professional \(targetLang) language teacher.
        Your student's native language is \(nativeLang).
        You ONLY generate \(targetLang) exercises. Never mix other languages in questions or options.
        Always respond with valid JSON only — no markdown, no extra text.
        """
    }

    private func buildPrompt(topic: AIQuizTopic, count: Int,
                             targetLang: String, nativeLang: String,
                             langCode: String = "en") -> String {
        let topicDesc = topic.promptDescription(for: langCode)
        return """
        Generate exactly \(count) quiz questions to practice \(targetLang) \(topicDesc).

        STRICT RULES:
        - ALL questions and options MUST be written in \(targetLang) only
        - explanations MUST be in \(nativeLang)
        - Use ONLY these two modes: "multipleChoice" and "fillInTheBlank"
        - Every question MUST have exactly 4 options and a correct_answer
        - "multipleChoice": ask a direct grammar/vocabulary question in \(targetLang). The question field should be a clear, complete question sentence.
        - "fillInTheBlank": provide a \(targetLang) sentence with ___ where one word is missing, options are the 4 possible words.
        - Vary question types, difficulty from easy to medium
        - correct_answer must exactly match one of the options

        Return ONLY this JSON (no markdown):
        {
          "questions": [
            {
              "mode": "fillInTheBlank",
              "question": "She ___ to school every day.",
              "options": ["go", "goes", "going", "gone"],
              "correct_answer": "goes",
              "explanation": "Üçüncü tekil şahıs için fiil -s/-es takısı alır."
            },
            {
              "mode": "multipleChoice",
              "question": "Which sentence uses the correct form of 'have'?",
              "options": ["She have a car.", "She has a car.", "She haves a car.", "She is have a car."],
              "correct_answer": "She has a car.",
              "explanation": "Üçüncü tekil şahıs için 'have' yerine 'has' kullanılır."
            }
          ]
        }
        """
    }

    // MARK: - Convert AIRawQuestion → GameQuestion

    private func convert(_ raw: AIRawQuestion, topic: AIQuizTopic) -> GameQuestion {
        // writing modunda correct_answer gelmeyebilir → instruction'ı fallback kullan
        let answer = raw.correct_answer ?? raw.instruction ?? raw.question

        let placeholder = SBWord(
            id: UUID(), sourceLangId: 1, targetLangId: 2,
            term: raw.question,
            translation: answer,
            phonetic: nil,
            description: raw.explanation ?? raw.instruction,
            exampleSentence: nil,
            difficulty: 1,
            translations: nil
        )

        let mode: QuizMode = raw.mode == "fillInTheBlank" ? .fillInTheBlank : .multipleChoice

        var q = GameQuestion(
            word: placeholder,
            mode: mode,
            options: raw.options ?? [],
            correctAnswer: answer,
            displayedMeaning: answer,
            isCorrectPair: true
        )
        q.questionDirection = .targetToNative
        q.promptText        = raw.question
        q.sentenceWords     = raw.options?.shuffled() ?? [answer]
        q.gapSentence       = raw.question

        return q
    }
}
