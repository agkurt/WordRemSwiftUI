//
//  GameQuizViewModel.swift
//  WordRemSwiftUI
//
//  Gamified quiz ViewModel for the Path module.
//  Manages 3-heart lives, XP award, and the complete_level RPC call.
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
        case outOfLives
        case completed(score: Int, stars: Int, xpEarned: Int)
    }

    // MARK: - Published
    @Published var questions: [GameQuestion]  = []
    @Published var currentIndex: Int          = 0
    @Published var lives: Int                 = 3
    @Published var score: Int                 = 0
    @Published var state: State               = .loading
    @Published var writingAnswer: String      = ""
    @Published var xpToast: Int               = 0
    @Published var showXPToast: Bool          = false
    @Published var isSaving: Bool             = false

    // MARK: - Inputs
    private(set) var sessionType: QuizSessionType = .level(UUID())
    private var sessionMistakes: Set<String> = []

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
    func setup(sessionType: QuizSessionType, words: [SBWord]) {
        self.sessionType = sessionType
        self.questions  = GameQuestion.generate(from: words)
        self.currentIndex = 0
        self.score      = 0
        self.lives      = 3
        self.writingAnswer = ""
        self.sessionMistakes = []
        self.state      = questions.isEmpty ? .outOfLives : .question
    }

    // MARK: - Answer: Multiple Choice
    func submitMultipleChoice(selected: String) {
        guard case .question = state, let q = currentQuestion else { return }
        let correct = selected == q.correctAnswer
        recordAnswer(isCorrect: correct)
    }

    // MARK: - Answer: True / False
    func submitTrueFalse(answer: Bool) {
        guard case .question = state, let q = currentQuestion else { return }
        let correct = answer == q.isCorrectPair
        recordAnswer(isCorrect: correct)
    }

    // MARK: - Answer: Writing
    func submitWriting() {
        guard case .question = state, let q = currentQuestion else { return }
        let normalizedUser    = writingAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        let normalizedCorrect = q.correctAnswer.lowercased()
        recordAnswer(isCorrect: normalizedUser == normalizedCorrect)
    }

    // MARK: - Core Record
    private func recordAnswer(isCorrect: Bool) {
        if isCorrect {
            score += 1
            showXPToastAnimation()
        } else {
            lives -= 1
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
        guard lives > 0 else {
            handleGameOverMistakes()
            state = .outOfLives
            return
        }
        if isLastQuestion {
            Task { await finishQuiz() }
        } else {
            currentIndex += 1
            state = .question
        }
    }

    private func handleGameOverMistakes() {
        switch sessionType {
        case .level(_):
            if !sessionMistakes.isEmpty {
                MistakesManager.shared.addMistakes(sessionMistakes)
                UserDefaults.standard.set(true, forKey: "justSavedMistakes")
            }
        case .mistakes:
            // Remove correctly answered words from the mistakes pool even if failed
            let answeredQuestions = questions.prefix(currentIndex + 1)
            let answeredWordIds = Set(answeredQuestions.map { $0.word.id.uuidString })
            let correctWordIds = answeredWordIds.subtracting(sessionMistakes)
            
            if !correctWordIds.isEmpty {
                MistakesManager.shared.removeMistakes(correctWordIds)
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
            // Remove correctly answered words from the mistakes pool
            let allWordIds = Set(questions.map { $0.word.id.uuidString })
            let correctWordIds = allWordIds.subtracting(sessionMistakes)
            
            if !correctWordIds.isEmpty {
                MistakesManager.shared.removeMistakes(correctWordIds)
            }
            
            if !MistakesManager.shared.hasMistakes {
                UserDefaults.standard.set(true, forKey: "justClearedMistakes")
            }
            state = .completed(score: scorePercent, stars: 3, xpEarned: score * 5)
        }
        
        isSaving = false
    }

    // MARK: - Restart
    func restart() {
        currentIndex = 0
        score        = 0
        lives        = 3
        writingAnswer = ""
        questions    = questions.shuffled()
        state        = .question
    }
}

// MARK: - GameQuestion model
struct GameQuestion: Identifiable {
    let id = UUID()
    let word: SBWord
    let mode: QuizMode
    let options: [String]       // For multipleChoice
    let correctAnswer: String
    let displayedMeaning: String
    let isCorrectPair: Bool     // For trueFalse

    static func generate(from words: [SBWord]) -> [GameQuestion] {
        let shuffled = words.shuffled()
        return shuffled.map { word in
            let correct = word.translation
            let wrong   = words.filter { $0.id != word.id }.map { $0.translation }.shuffled()

            let options: [String]
            if words.count >= 4 {
                options = (Array(wrong.prefix(3)) + [correct]).shuffled()
            } else {
                options = []
            }

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
