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
    let mode: String          // "multipleChoice" | "writing" | "fillInTheBlank"
    let question: String      // gösterilecek soru/cümle
    let options: [String]     // boş ise writing
    let correct_answer: String
    let explanation: String
}

private struct AIQuestionList: Decodable {
    let questions: [AIRawQuestion]
}

// MARK: - Service

final class OpenAIQuizService {

    static let shared = OpenAIQuizService()
    private init() {}

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var apiKey: String {
        // Önce Info.plist'ten, sonra UserDefaults'tan
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !key.isEmpty { return key }
        return UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }

    /// Verilen konu ve soru sayısı için GameQuestion dizisi üretir.
    func generateQuestions(
        topic: AIQuizTopic,
        count: Int,
        targetLang: String,
        nativeLang: String
    ) async throws -> [GameQuestion] {

        let prompt = buildPrompt(topic: topic, count: count,
                                 targetLang: targetLang, nativeLang: nativeLang)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = OAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OAIMessage(role: "system", content: systemPrompt(nativeLang: nativeLang)),
                OAIMessage(role: "user",   content: prompt)
            ],
            response_format: OAIResponseFormat(type: "json_object"),
            temperature: 0.7
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let raw = String(data: data, encoding: .utf8) ?? "unknown"
            throw URLError(.badServerResponse, userInfo: ["detail": raw])
        }

        let oaiResp  = try JSONDecoder().decode(OAIResponse.self, from: data)
        guard let content = oaiResp.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }

        let list = try JSONDecoder().decode(AIQuestionList.self, from: jsonData)
        return list.questions.map { convert($0, topic: topic) }
    }

    // MARK: - Prompt Builder

    private func systemPrompt(nativeLang: String) -> String {
        """
        You are an expert language teacher. Generate quiz questions for language learners.
        Always respond with valid JSON only. The native language of the learner is \(nativeLang).
        """
    }

    private func buildPrompt(topic: AIQuizTopic, count: Int,
                             targetLang: String, nativeLang: String) -> String {
        """
        Generate exactly \(count) \(targetLang) grammar quiz questions about: \(topic.promptDescription)

        The learner's native language is \(nativeLang). Mix the following modes:
        - "multipleChoice": Show a sentence/question, provide 4 options, one is correct.
        - "writing": Show a sentence with a blank or instruction, learner writes the answer.
        - "fillInTheBlank": Sentence with ___ gap, provide 4 word options.

        Return ONLY this JSON structure:
        {
          "questions": [
            {
              "mode": "multipleChoice",
              "question": "She ___ to school every day.",
              "options": ["go", "goes", "going", "gone"],
              "correct_answer": "goes",
              "explanation": "3. tekil şahıs için -s eki kullanılır."
            }
          ]
        }

        Rules:
        - questions and options must be in \(targetLang)
        - explanations must be in \(nativeLang)
        - Make questions varied and educational
        - Difficulty: beginner to intermediate
        """
    }

    // MARK: - Convert AIRawQuestion → GameQuestion

    private func convert(_ raw: AIRawQuestion, topic: AIQuizTopic) -> GameQuestion {
        let placeholder = SBWord(
            id: UUID(), sourceLangId: 1, targetLangId: 2,
            term: raw.question,
            translation: raw.correct_answer,
            phonetic: nil,
            description: raw.explanation,
            exampleSentence: nil,
            difficulty: 1,
            translations: nil
        )

        let mode: QuizMode
        switch raw.mode {
        case "writing":        mode = .writing
        case "fillInTheBlank": mode = .fillInTheBlank
        default:               mode = .multipleChoice
        }

        var q = GameQuestion(
            word: placeholder,
            mode: mode,
            options: raw.options,
            correctAnswer: raw.correct_answer,
            displayedMeaning: raw.correct_answer,
            isCorrectPair: true
        )
        q.questionDirection = .targetToNative
        q.promptText        = raw.question
        q.sentenceWords     = raw.options.shuffled()
        q.gapSentence       = raw.question

        return q
    }
}
