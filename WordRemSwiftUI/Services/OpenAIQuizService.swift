//
//  OpenAIQuizService.swift
//  WordRemSwiftUI
//
//  Gramer quizi, sesli gramer sohbeti ve kelime çevirisi.
//  Apple'ın cihaz üstü modeliyle çalışır (AIEngine) — API anahtarı yok.
//

import Foundation

// MARK: - Prompt Models

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

    var hasAPIKey: Bool { AIEngine.isAvailable }

    /// Sistem mesajını talimat, son kullanıcı mesajını istem, aradakileri geçmiş olarak gönderir
    private func run(_ body: OAIRequest) async throws -> String {
        let instructions = body.messages.first { $0.role == "system" }?.content ?? ""
        let turns = body.messages.filter { $0.role != "system" }
        var prompt = turns.last?.content ?? ""
        if body.response_format.type == "json_object" {
            prompt += "\n\nReply with ONLY valid JSON, no markdown."
        }
        return try await AIEngine.complete(instructions: instructions, prompt: prompt,
                                           history: turns.dropLast().map { ($0.role, $0.content) },
                                           temperature: body.temperature)
    }

    /// Verilen konu ve soru sayısı için GameQuestion dizisi üretir.
    func generateQuestions(
        topic: AIQuizTopic,
        count: Int,
        targetLang: String,
        nativeLang: String,
        langCode: String = "en"
    ) async throws -> [GameQuestion] {

        guard hasAPIKey else { throw AIEngine.AIError.unavailable }

        let prompt = buildPrompt(topic: topic, count: count,
                                 targetLang: targetLang, nativeLang: nativeLang,
                                 langCode: langCode)

        let body = OAIRequest(
            model: "on-device",
            messages: [
                OAIMessage(role: "system", content: systemPrompt(nativeLang: nativeLang, targetLang: targetLang)),
                OAIMessage(role: "user",   content: prompt)
            ],
            response_format: OAIResponseFormat(type: "json_object"),
            temperature: 0.7
        )
        let content = try await run(body)

        // Debug: API'den gelen ham JSON'u logla
        print("📝 AI raw content:\n\(content)")

        // Bazen model cevabı ```json ... ``` içinde sarıyor, temizle
        let cleaned = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = AIEngine.jsonData(from: cleaned) else {
            throw AIEngine.AIError.emptyResponse
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

    // MARK: - Grammar Voice Intro

    /// Topic için yapılandırılmış, sesli ders açılışı üretir.
    /// Selamlama → kısa açıklama → örnek cümle → "şimdi sen söyle" pratiği ile biter.
    func generateGrammarIntro(topic: AIQuizTopic, targetLang: String, nativeLang: String) async -> String? {
        guard hasAPIKey else { return nil }

        let body = OAIRequest(
            model: "on-device",
            messages: [
                OAIMessage(role: "system", content: """
                    You are a brilliant, warm and funny \(targetLang) teacher. \
                    You're having a real spoken conversation — not a textbook lesson. \
                    The student's native language is \(nativeLang). Speak ONLY in \(nativeLang).

                    This is the very first message. Do this:
                    1. Say a warm, energetic greeting (1 sentence).
                    2. Introduce the topic '\(topic.rawValue)' — explain the core idea in simple, everyday language (2 sentences max).
                    3. Give ONE short \(targetLang) example sentence. Say it naturally, DO NOT add a \(nativeLang) translation in parentheses after it — trust the student.
                    4. Ask the student to try saying it back to you. Use a casual, friendly phrase — not "Haydi sen de söyle" every time. Vary it.

                    STRICT RULES:
                    - Max 5 sentences total.
                    - Plain spoken text ONLY — no bullet points, no parentheses with translations, no markdown.
                    - Sound like a real human teacher on a phone call, not a robot.
                    """),
                OAIMessage(role: "user",
                           content: "Start the lesson on '\(topic.rawValue)' for a \(targetLang) learner.")
            ],
            response_format: OAIResponseFormat(type: "text"),
            temperature: 0.7
        )
        return try? await run(body)
    }

    /// Kullanıcının sesli sorusuna kısa, doğal bir yanıt üretir.
    /// history: [(role: "user"|"assistant", content: String)]
    func continueGrammarChat(
        topic: AIQuizTopic,
        history: [(role: String, content: String)],
        userText: String,
        targetLang: String,
        nativeLang: String
    ) async -> String? {
        guard hasAPIKey else { return nil }

        var messages: [OAIMessage] = [
            OAIMessage(role: "system", content: """
                You are a brilliant, fun, human-like \(targetLang) teacher in a SPOKEN voice lesson about '\(topic.rawValue)'. \
                The student's native language is \(nativeLang).

                RESPONSE LANGUAGE:
                - ALWAYS respond in \(nativeLang) — even if the student writes in \(targetLang) or mixes languages.
                - The student's message may be in \(nativeLang), \(targetLang), or garbled (speech recognition errors). Understand their intent and respond in \(nativeLang).

                DEPTH — go beyond surface-level. For each topic, cover:
                - The core rule AND the common exceptions or edge cases
                - When native speakers actually use this form in real life (not just textbook usage)
                - Common mistakes learners make and why
                - Subtle differences (e.g. "I go" vs "I am going") when relevant
                - Real-world example sentences, not just "She eats an apple"

                EVALUATION — be smart and generous:
                - Speech recognition is IMPERFECT. If the student's text looks garbled, assume they tried.
                - If the attempt is close to correct, praise warmly and move on.
                - Only correct CLEAR and MEANINGFUL mistakes. Show the right form once — never lecture.
                - NEVER say the student is wrong if their input is short or unclear.

                VARIETY — CRITICAL: look at the FULL conversation history before every response.
                - Track exactly what you've already asked. NEVER repeat the same question type twice in a row.
                - Banned if used in the last 2 turns: asking to "create your own sentence", asking to "say this sentence", asking the same grammar point.
                - Rotate through: deep grammar explanation → concept question (answer in \(nativeLang)) → spot-the-error (give 2 sentences, ask which is wrong) → translation challenge (\(nativeLang)→\(targetLang)) → real-life usage ("when would you say this?") → asking the student a follow-up question about something they said.
                - If the student asks a question, answer it THOROUGHLY and with genuine enthusiasm, then pivot to a new exercise.

                STYLE:
                - Max 3–4 sentences. Spoken audio — tight, punchy, human.
                - NO bullet points, NO parentheses with translations, NO markdown.
                - Sound like a witty, warm real person. Use natural reactions: "Vay be!", "Tam yerine!", "Harika!", "Beklemiyordum bunu!"
                - If the student seems stuck or frustrated, drop everything and explain from scratch very simply.
                """)
        ]
        messages += history.map { OAIMessage(role: $0.role, content: $0.content) }
        messages.append(OAIMessage(role: "user", content: userText))

        let body = OAIRequest(
            model: "on-device",
            messages: messages,
            response_format: OAIResponseFormat(type: "text"),
            temperature: 0.7
        )

        return try? await run(body)
    }

    // MARK: - Word Translation (single word, lightweight call)

    /// Tapped kelimeyi native dile çevirir. Hata olursa nil döner.
    func translateWord(_ word: String, targetLangCode: String, nativeLangCode: String) async -> String? {
        guard hasAPIKey else { return nil }

        let targetName = fullLangName(for: targetLangCode)
        let nativeName = fullLangName(for: nativeLangCode)

        let body = OAIRequest(
            model: "on-device",
            messages: [
                OAIMessage(role: "system",
                           content: "You are a translator. Translate the given \(targetName) word/phrase into \(nativeName). Reply with ONLY the translation — one word or short phrase, no extra text."),
                OAIMessage(role: "user", content: word)
            ],
            response_format: OAIResponseFormat(type: "text"),
            temperature: 0.2
        )

        return try? await run(body)
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
            ?? Locale(identifier: OL.nativeLangCode).localizedString(forLanguageCode: code)
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
