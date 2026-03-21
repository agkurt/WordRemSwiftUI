//
//  AIQuizViewModel.swift
//  WordRemSwiftUI
//
//  Orchestrates: topic selection → question count → OpenAI call → quiz launch.
//

import SwiftUI

enum AIQuizState {
    case selectTopic
    case selectCount(topic: AIQuizTopic)
    case loading(topic: AIQuizTopic, count: Int)
    case ready(questions: [GameQuestion], title: String)
    case error(String)
}

@MainActor
final class AIQuizViewModel: ObservableObject {

    @Published var state: AIQuizState = .selectTopic
    @Published var selectedCountIndex: Int = 1   // default = 10 questions

    let questionCounts = [5, 10, 15, 20]

    var selectedTopic: AIQuizTopic? {
        if case .selectCount(let t) = state { return t }
        if case .loading(let t, _) = state { return t }
        return nil
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    func selectTopic(_ topic: AIQuizTopic) {
        withAnimation(.spring(response: 0.35)) {
            state = .selectCount(topic: topic)
        }
    }

    func backToTopics() {
        withAnimation(.spring(response: 0.35)) {
            state = .selectTopic
        }
    }

    func startGeneration(topic: AIQuizTopic) {
        let count = questionCounts[selectedCountIndex]
        state = .loading(topic: topic, count: count)

        // Kısa kodu ("en", "de"…) tam dil adına çevir
        let rawCode    = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en"
        let targetLang = OpenAIQuizService.shared.fullLangName(for: rawCode)
        let nativeCode = OL.nativeLangCode
        let nativeLang = Locale.current.localizedString(forLanguageCode: nativeCode) ?? "English"

        Task {
            do {
                let questions = try await OpenAIQuizService.shared.generateQuestions(
                    topic: topic,
                    count: count,
                    targetLang: targetLang,
                    nativeLang: nativeLang,
                    langCode: rawCode
                )
                state = .ready(questions: questions, title: topic.rawValue)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func reset() {
        selectedCountIndex = 1
        state = .selectTopic
    }
}

