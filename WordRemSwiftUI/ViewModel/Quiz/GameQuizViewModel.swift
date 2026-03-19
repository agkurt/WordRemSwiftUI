//
//  GameQuizViewModel.swift
//  WordRemSwiftUI
//
//  Gamified quiz ViewModel for the Path module.
//  Manages daily 25-question limit, XP award, and the complete_level RPC call.
//  Lives / hearts system removed — replaced with daily question limit.
//

import SwiftUI
import Speech

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
    func setup(sessionType: QuizSessionType, words: [SBWord], sentences: [SBSentence] = [], levelTitle: String = "") {
        self.sessionType    = sessionType
        self.levelTitle     = levelTitle
        self.targetLangCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        self.questions      = GameQuestion.generate(from: words, sentences: sentences)
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

        // Prefetch audio for all listening/speaking questions so they play instantly
        let audioWords = questions
            .filter { $0.mode == .listening || $0.mode == .speaking }
            .map { $0.word.term }
        let lang = targetLangCode
        Task.detached(priority: .background) {
            for word in audioWords {
                await TTSManager.shared.prefetchAsync(word, langCode: lang)
            }
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

    // MARK: - Answer: Speaking
    func submitSpeaking(recognized: String) {
        guard case .question = state, let q = currentQuestion else { return }
        let correct = SpeechRecognitionManager.shared.isCorrect(
            recognized: recognized,
            expected: q.word.term
        )
        recordAnswer(isCorrect: correct)
    }

    // MARK: - Answer: Listening (same tap logic as multipleChoice)
    func submitListening(selected: String) {
        guard case .question = state, let q = currentQuestion else { return }
        recordAnswer(isCorrect: selected == q.correctAnswer)
    }

    // MARK: - Answer: Fill in the Blank
    func submitFillInTheBlank(selected: String) {
        guard case .question = state, let q = currentQuestion else { return }
        recordAnswer(isCorrect: selected == q.word.term)
    }

    // MARK: - Answer: Sentence Builder
    func submitSentenceBuilder(selectedWord: String) {
        guard case .question = state, let q = currentQuestion else { return }
        // correctAnswer = nativeMeaning for sentenceBuilder (targetToNative direction)
        recordAnswer(isCorrect: selectedWord.lowercased() == q.correctAnswer.lowercased())
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

// MARK: - Question direction
enum QuestionDirection: Equatable {
    case targetToNative  // show target-lang word → pick native translation (classic)
    case nativeToTarget  // show native meaning   → pick target-lang word  (new)
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
    var questionDirection: QuestionDirection = .targetToNative
    /// Text shown in the word-card (target term OR native meaning depending on direction)
    var promptText: String = ""
    var sentenceWords: [String] = []   // for sentenceBuilder / fillInTheBlank: scrambled word choices
    var gapSentence: String     = ""   // for fillInTheBlank: "_____ → native meaning"
    /// Set when this is a DB sentence question (sentenceBuilder from sentences table)
    var sentence: SBSentence?   = nil

    static func generate(from words: [SBWord], sentences: [SBSentence] = []) -> [GameQuestion] {
        let phoneCode   = OL.phoneCode
        let shuffled    = words.shuffled()
        let canMulti    = words.count >= 4
        let canListen   = canMulti
        let canSpeak    = words.count >= 1
        let canFill     = words.count >= 4
        let canSentence = words.count >= 2

        let wordQuestions: [GameQuestion] = shuffled.enumerated().map { index, word in
            let nativeMeaning = word.displayTranslation(phoneCode: phoneCode)
            let wrongNative   = words.filter { $0.id != word.id }
                                     .map { $0.displayTranslation(phoneCode: phoneCode) }
                                     .shuffled()
            let wrongTerms    = words.filter { $0.id != word.id }
                                     .map { $0.term }
                                     .shuffled()

            // ── mode selection ───────────────────────────────────────────
            let shouldBeFill     = canFill && index % 6 == 5
            let shouldBeSentence = canSentence && index % 8 == 7 && !shouldBeFill

            let finalMode: QuizMode
            if canListen && index % 5 == 4 {
                finalMode = .listening
            } else if canSpeak && index % 7 == 6 {
                finalMode = .speaking
            } else if shouldBeFill {
                finalMode = .fillInTheBlank
            } else if shouldBeSentence {
                finalMode = .sentenceBuilder
            } else if canMulti {
                finalMode = .multipleChoice
            } else {
                finalMode = .writing
            }
            // ─────────────────────────────────────────────────────────────

            // ── question direction (only for multipleChoice & writing) ───
            let canFlipDirection = (finalMode == .multipleChoice || finalMode == .writing) && canMulti
            let direction: QuestionDirection = canFlipDirection && Bool.random()
                ? .nativeToTarget
                : .targetToNative
            // ─────────────────────────────────────────────────────────────

            // ── build options & correctAnswer based on direction ─────────
            let finalCorrect: String
            let finalOptions: [String]
            let finalPrompt:  String

            if direction == .nativeToTarget {
                // Card shows native meaning → user picks target-lang word
                finalPrompt   = nativeMeaning
                finalCorrect  = word.term
                finalOptions  = canMulti
                    ? (Array(wrongTerms.prefix(3)) + [word.term]).shuffled()
                    : []
            } else {
                // Card shows target word → user picks native translation
                finalPrompt   = word.term
                finalCorrect  = nativeMeaning
                finalOptions  = canMulti
                    ? (Array(wrongNative.prefix(3)) + [nativeMeaning]).shuffled()
                    : []
            }
            // ─────────────────────────────────────────────────────────────

            // trueFalse display pair (always targetToNative logic)
            let showWrong = Bool.random() && !wrongNative.isEmpty
            let display   = showWrong ? (wrongNative.first ?? nativeMeaning) : nativeMeaning

            // sentenceWords:
            //  • sentenceBuilder → native chips (user picks the correct native meaning)
            //  • fillInTheBlank  → target terms (user picks the correct target word)
            let sentenceBuilderChips = (Array(wrongNative.prefix(3)) + [nativeMeaning])
                .filter { !$0.isEmpty }.shuffled()
            let fillBlankChips = (Array(wrongTerms.prefix(3)) + [word.term])
                .filter { !$0.isEmpty }.shuffled()

            var q = GameQuestion(
                word: word,
                mode: finalMode,
                options: finalOptions,
                correctAnswer: finalCorrect,
                displayedMeaning: display,
                isCorrectPair: !showWrong
            )
            q.questionDirection = direction
            q.promptText  = finalPrompt
            q.sentenceWords = (finalMode == .sentenceBuilder) ? sentenceBuilderChips : fillBlankChips
            q.gapSentence = "_____ → \(nativeMeaning)"
            return q
        }

        // ── Append DB sentence questions (one per sentence) ──────────────
        // Each sentence question shows the full target-lang sentence and the user
        // picks the correct key-word meaning from word chips.
        let allNative = words.map { $0.displayTranslation(phoneCode: phoneCode) }
        let sentenceQuestions: [GameQuestion] = sentences.compactMap { sentence in
            guard let keyWord = sentence.keyWord,
                  let keyNative = sentence.keyWordNative,
                  !keyWord.isEmpty, !keyNative.isEmpty else { return nil }

            // Distractors: random native meanings from the word pool (excluding keyNative)
            let distractors = allNative.filter { $0 != keyNative }.shuffled().prefix(3)
            let chips = (Array(distractors) + [keyNative]).shuffled()

            // Use a placeholder SBWord (term = keyWord, translation = keyNative)
            let placeholder = SBWord(
                id: UUID(), sourceLangId: 1, targetLangId: 2,
                term: keyWord, translation: keyNative,
                phonetic: nil, description: nil,
                exampleSentence: sentence.targetText,
                difficulty: sentence.difficulty,
                translations: nil
            )
            var q = GameQuestion(
                word: placeholder,
                mode: .sentenceBuilder,
                options: [],
                correctAnswer: keyNative,
                displayedMeaning: keyNative,
                isCorrectPair: true
            )
            q.questionDirection = .targetToNative
            q.promptText    = sentence.targetText   // full sentence shown to user
            q.sentenceWords = chips
            q.sentence      = sentence
            return q
        }

        // Interleave sentence questions evenly throughout the word questions
        var result = wordQuestions
        let step = max(1, result.count / max(1, sentenceQuestions.count))
        for (i, sq) in sentenceQuestions.enumerated() {
            let insertAt = min((i + 1) * step, result.count)
            result.insert(sq, at: insertAt)
        }
        return result
    }
}
