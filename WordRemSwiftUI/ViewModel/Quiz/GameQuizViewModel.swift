//
//  GameQuizViewModel.swift
//  WordRemSwiftUI
//
//  Gamified quiz ViewModel for the Path module.
//  Manages daily 25-question limit, XP award, and the complete_level RPC call.
//  Lives / hearts system removed — replaced with daily question limit.
//

import SwiftUI

enum QuizSessionType: Equatable {
    case level(UUID)
    case mistakes
}

@MainActor
final class GameQuizViewModel: ObservableObject {

    // MARK: - State Machine
    enum State {
        case loading
        case question
        case answered(isCorrect: Bool)
        case dailyLimitReached                              // replaces outOfLives
        case completed(score: Int, stars: Int, xpEarned: Int)
    }

    // MARK: - Published
    @Published var questions: [GameQuestion]  = []
    @Published var currentIndex: Int          = 0
    @Published var score: Int                 = 0
    @Published var state: State               = .loading
    @Published var writingAnswer: String      = ""
    @Published var xpToast: Int               = 0
    @Published var showXPToast: Bool          = false
    @Published var isSaving: Bool             = false

    // MARK: - Inputs
    private(set) var sessionType: QuizSessionType = .level(UUID())
    private var sessionMistakes: Set<String> = []
    private var levelTitle: String = ""
    private var targetLangCode: String = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"

    // MARK: - Computed
    var currentQuestion: GameQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    var isLastQuestion: Bool { currentIndex >= questions.count - 1 }

    var correctCount: Int { score }
    var totalCount: Int   { questions.count }

    var scorePercent: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalCount)) * 100)
    }

    // MARK: - Setup
    func setup(sessionType: QuizSessionType, words: [SBWord], levelTitle: String = "") {
        self.sessionType    = sessionType
        self.levelTitle     = levelTitle
        self.targetLangCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        self.questions      = GameQuestion.generate(from: words)
        self.currentIndex   = 0
        self.score          = 0
        self.writingAnswer  = ""
        self.sessionMistakes = []

        if questions.isEmpty {
            self.state = .dailyLimitReached
        } else if !DailyLimitManager.shared.canAskQuestion {
            self.state = .dailyLimitReached
        } else {
            self.state = .question
        }
    }

    // MARK: - Answer: Multiple Choice
    func submitMultipleChoice(selected: String) {
        guard case .question = state, let q = currentQuestion else { return }
        recordAnswer(isCorrect: selected == q.correctAnswer)
    }

    // MARK: - Answer: True / False
    func submitTrueFalse(answer: Bool) {
        guard case .question = state, let q = currentQuestion else { return }
        recordAnswer(isCorrect: answer == q.isCorrectPair)
    }

    // MARK: - Answer: Writing
    func submitWriting() {
        guard case .question = state, let q = currentQuestion else { return }
        let user    = writingAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        let correct = q.correctAnswer.lowercased()
        recordAnswer(isCorrect: user == correct)
    }

    // MARK: - Core Record
    private func recordAnswer(isCorrect: Bool) {
        // Günlük soru hakkını kullan
        DailyLimitManager.shared.recordQuestion()

        if isCorrect {
            score += 1
            showXPToastAnimation()
        } else {
            if let q = currentQuestion {
                sessionMistakes.insert(q.word.id.uuidString)
            }
        }
        state = .answered(isCorrect: isCorrect)
    }

    private func showXPToastAnimation() {
        xpToast = 10
        showXPToast = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showXPToast = false
        }
    }

    // MARK: - Navigation
    func nextQuestion() {
        writingAnswer = ""

        if isLastQuestion {
            Task { await finishQuiz() }
            return
        }

        // Günlük limit doldu mu?
        if !DailyLimitManager.shared.canAskQuestion {
            handleGameOverMistakes()
            state = .dailyLimitReached
            return
        }

        currentIndex += 1
        state = .question
    }

    private func handleGameOverMistakes() {
        switch sessionType {
        case .level(_):
            if !sessionMistakes.isEmpty {
                MistakesManager.shared.addMistakes(sessionMistakes)
                UserDefaults.standard.set(true, forKey: "justSavedMistakes")
            }
        case .mistakes:
            let answeredIds  = Set(questions.prefix(currentIndex + 1).map { $0.word.id.uuidString })
            let correctIds   = answeredIds.subtracting(sessionMistakes)
            if !correctIds.isEmpty {
                MistakesManager.shared.removeMistakes(correctIds)
            }
        }
    }

    // MARK: - Finish & Save
    private func finishQuiz() async {
        isSaving = true

        switch sessionType {
        case .level(let levelId):
            if !sessionMistakes.isEmpty {
                MistakesManager.shared.addMistakes(sessionMistakes)
                UserDefaults.standard.set(true, forKey: "justSavedMistakes")
                let mistakesCopy = sessionMistakes
                let titleCopy    = levelTitle
                let langCopy     = targetLangCode
                Task.detached(priority: .background) {
                    await PathMistakesDeckService.shared.createDeckFromMistakes(
                        mistakeWordIds: mistakesCopy,
                        levelTitle: titleCopy,
                        targetLangCode: langCopy
                    )
                }
            }

            do {
                let response = try await SupabaseDataService.shared.completeLevel(
                    levelId: levelId,
                    score: scorePercent,
                    quizMode: "multipleChoice"
                )
                if response.success {
                    UserDefaults.standard.set(true, forKey: "justCompletedLevel")
                    state = .completed(
                        score: scorePercent,
                        stars: response.stars ?? 1,
                        xpEarned: response.xpEarned ?? 0
                    )
                } else {
                    state = .completed(score: scorePercent, stars: 0, xpEarned: 0)
                }
            } catch {
                print("⚠️ completeLevel error: \(error)")
                state = .completed(score: scorePercent, stars: 0, xpEarned: 0)
            }

        case .mistakes:
            let allIds     = Set(questions.map { $0.word.id.uuidString })
            let correctIds = allIds.subtracting(sessionMistakes)
            if !correctIds.isEmpty { MistakesManager.shared.removeMistakes(correctIds) }
            if !MistakesManager.shared.hasMistakes {
                UserDefaults.standard.set(true, forKey: "justClearedMistakes")
            }
            state = .completed(score: scorePercent, stars: 3, xpEarned: score * 5)
        }

        isSaving = false
    }
}

// MARK: - GameQuestion model
struct GameQuestion: Identifiable {
    let id = UUID()
    let word: SBWord
    let mode: QuizMode
    let options: [String]
    let correctAnswer: String
    let displayedMeaning: String
    let isCorrectPair: Bool

    static func generate(from words: [SBWord]) -> [GameQuestion] {
        let phoneCode = OL.phoneCode
        let shuffled  = words.shuffled()
        return shuffled.map { word in
            let correct = word.displayTranslation(phoneCode: phoneCode)
            let wrong   = words.filter { $0.id != word.id }
                               .map { $0.displayTranslation(phoneCode: phoneCode) }
                               .shuffled()
            let options: [String] = words.count >= 4
                ? (Array(wrong.prefix(3)) + [correct]).shuffled()
                : []

            let showWrong = Bool.random() && !wrong.isEmpty
            let display   = showWrong ? (wrong.first ?? correct) : correct

            return GameQuestion(
                word: word,
                mode: words.count >= 4 ? .multipleChoice : .writing,
                options: options,
                correctAnswer: correct,
                displayedMeaning: display,
                isCorrectPair: !showWrong
            )
        }
    }
}
