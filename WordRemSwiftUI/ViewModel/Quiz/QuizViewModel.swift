//
//  QuizViewModel.swift
//  WordRemSwiftUI
//

import SwiftUI

@MainActor
final class QuizViewModel: ObservableObject {

    // MARK: - State
    enum QuizState {
        case idle
        case active
        case answered(isCorrect: Bool)
        case finished
    }

    // MARK: - Published
    @Published var questions: [QuizQuestion] = []
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var state: QuizState = .idle
    @Published var writingAnswer: String = ""
    @Published var answerRecords: [QuizAnswerRecord] = []
    @Published var isSaving: Bool = false

    // MARK: - Inputs
    private(set) var cardId: String = ""
    private(set) var mode: QuizMode = .multipleChoice
    private(set) var allWordInfos: [WordInfo] = []

    // MARK: - Computed
    var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    var isLastQuestion: Bool {
        currentIndex >= questions.count - 1
    }

    var quizResult: QuizResult {
        QuizResult(
            cardId: cardId,
            mode: mode.rawValue,
            score: score,
            total: questions.count,
            date: Date()
        )
    }

    // MARK: - Setup
    func setup(wordInfos: [WordInfo], mode: QuizMode, cardId: String) {
        self.allWordInfos = wordInfos
        self.mode = mode
        self.cardId = cardId
        self.questions = generateQuestions(from: wordInfos, mode: mode)
        self.currentIndex = 0
        self.score = 0
        self.answerRecords = []
        self.writingAnswer = ""
        self.state = .active
    }

    // MARK: - Question Generation
    private func generateQuestions(from wordInfos: [WordInfo], mode: QuizMode) -> [QuizQuestion] {
        let shuffled = wordInfos.shuffled()
        return shuffled.map { wordInfo in
            makeQuestion(for: wordInfo, allWords: wordInfos, mode: mode)
        }
    }

    private func makeQuestion(for wordInfo: WordInfo, allWords: [WordInfo], mode: QuizMode) -> QuizQuestion {
        let correct = wordInfo.means

        // Build wrong options from other cards' means
        let wrong = allWords
            .filter { $0.id != wordInfo.id }
            .map { $0.means }
            .shuffled()

        let options: [String]
        if mode == .multipleChoice || mode == .listening {
            let wrongOptions = Array(wrong.prefix(3))
            options = (wrongOptions + [correct]).shuffled()
        } else {
            options = []
        }

        // True/False: 50% chance to show wrong meaning
        let showWrong = Bool.random() && !wrong.isEmpty
        let displayedMeaning: String
        let isCorrectPair: Bool
        if mode == .trueFalse && showWrong {
            displayedMeaning = wrong.first ?? correct
            isCorrectPair = false
        } else {
            displayedMeaning = correct
            isCorrectPair = true
        }

        // Fill in the Blank / Sentence Builder: scrambled word choices from other cards' means
        let scrambledWords: [String]
        if mode == .fillInTheBlank || mode == .sentenceBuilder {
            let wrongMeans = allWords.filter { $0.id != wordInfo.id }.map { $0.means }.shuffled()
            scrambledWords = (Array(wrongMeans.prefix(3)) + [correct]).filter { !$0.isEmpty }.shuffled()
        } else {
            scrambledWords = []
        }
        let gapSentence = (mode == .fillInTheBlank || mode == .sentenceBuilder)
            ? "\(wordInfo.names) → _____"
            : ""

        var q = QuizQuestion(
            wordInfo: wordInfo,
            mode: mode,
            options: options,
            correctAnswer: correct,
            displayedMeaning: displayedMeaning,
            isCorrectPair: isCorrectPair
        )
        q.sentenceWords = scrambledWords
        q.gapSentence   = gapSentence
        return q
    }

    // MARK: - Answer Handling
    func submitMultipleChoice(selected: String) {
        guard case .active = state,
              let question = currentQuestion else { return }

        let isCorrect = selected == question.correctAnswer
        recordAnswer(question: question, userAnswer: selected, isCorrect: isCorrect)
    }

    func submitTrueFalse(answer: Bool) {
        guard case .active = state,
              let question = currentQuestion else { return }

        let isCorrect = answer == question.isCorrectPair
        let userAnswer = answer ? "True" : "False"
        recordAnswer(question: question, userAnswer: userAnswer, isCorrect: isCorrect)
    }

    func submitWriting() {
        guard case .active = state,
              let question = currentQuestion else { return }

        let normalizedUser = writingAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        let normalizedCorrect = question.correctAnswer.lowercased()
        let isCorrect = normalizedUser == normalizedCorrect
        recordAnswer(question: question, userAnswer: writingAnswer, isCorrect: isCorrect)
    }

    func submitFillInTheBlank(selected: String) {
        guard case .active = state,
              let question = currentQuestion else { return }
        let isCorrect = selected == question.correctAnswer
        recordAnswer(question: question, userAnswer: selected, isCorrect: isCorrect)
    }

    func submitSentenceBuilder(selectedWord: String) {
        guard case .active = state,
              let question = currentQuestion else { return }
        let isCorrect = selectedWord == question.correctAnswer
        recordAnswer(question: question, userAnswer: selectedWord, isCorrect: isCorrect)
    }

    private func recordAnswer(question: QuizQuestion, userAnswer: String, isCorrect: Bool) {
        if isCorrect { score += 1 }
        answerRecords.append(QuizAnswerRecord(
            question: question,
            userAnswer: userAnswer,
            isCorrect: isCorrect
        ))
        state = .answered(isCorrect: isCorrect)
    }

    // MARK: - Navigation
    func nextQuestion() {
        writingAnswer = ""
        if isLastQuestion {
            state = .finished
            Task { await saveResult() }
        } else {
            currentIndex += 1
            state = .active
        }
    }

    // MARK: - Persistence
    private func saveResult() async {
        isSaving = true
        do {
            try await FirebaseService.shared.saveQuizResult(
                cardId: cardId,
                mode: mode.rawValue,
                score: score,
                total: questions.count
            )
        } catch {
            print("⚠️ Failed to save quiz result: \(error)")
        }
        isSaving = false
    }

    // MARK: - Reset
    func restart() {
        setup(wordInfos: allWordInfos, mode: mode, cardId: cardId)
    }
}
