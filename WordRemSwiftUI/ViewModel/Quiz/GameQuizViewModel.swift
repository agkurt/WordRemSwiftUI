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
    case aiGenerated(title: String)
}

@MainActor
final class GameQuizViewModel: ObservableObject {

    // MARK: - State Machine
    enum State {
        case loading
        case question
        case answered(isCorrect: Bool)
        case dailyLimitReached                              // replaces outOfLives
        case loadFailed                                     // ağ hatası / boş seviye — paywall değil
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
    private var startedAt = Date()
    private var practiceType: String {
        switch sessionType {
        case .level: return "path_level"
        case .mistakes: return "mistakes"
        case .aiGenerated: return "ai_quiz"
        }
    }
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
    /// Yeni kelime kartları puana dahil değil
    var totalCount: Int   { questions.filter(\.isScored).count }

    var scorePercent: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalCount)) * 100)
    }

    // MARK: - Setup
    func setup(sessionType: QuizSessionType, words: [SBWord], sentences: [SBSentence] = [],
               pool: [SBSentence] = [], levelTitle: String = "") {
        self.sessionType    = sessionType
        self.levelTitle     = levelTitle
        startedAt = Date()
        Track.practice("start", type: practiceType, wordCount: words.count, entryPoint: "practice")
        self.targetLangCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        let proficiency     = UserDefaults.standard.integer(forKey: "selectedProficiencyLevel")
        var isLevel = false
        if case .level = sessionType { isLevel = true }
        self.questions      = GameQuestion.generate(from: words, sentences: sentences, pool: pool.isEmpty ? sentences : pool,
                                                    proficiency: proficiency, introduceNew: isLevel)
        self.currentIndex   = 0
        self.score          = 0
        self.writingAnswer  = ""
        self.sessionMistakes = []
        #if DEBUG
        // Ekran kontrolü için: `-QuizStartMode "Match Pairs"` o tipteki ilk soruyu başa alır
        if let raw = UserDefaults.standard.string(forKey: "QuizStartMode"),
           let i = questions.firstIndex(where: { $0.mode.rawValue == raw }) {
            questions.insert(questions.remove(at: i), at: 0)
        }
        #endif

        if questions.isEmpty {
            self.state = .loadFailed
        } else if !DailyLimitManager.shared.canAskQuestion {
            self.state = .dailyLimitReached
        } else {
            self.state = .question
        }

        // Prefetch audio for all listening/speaking questions so they play instantly
        let audioWords = questions
            .filter { $0.mode == .listening || $0.mode == .speaking || $0.mode == .introduce }
            .map { $0.word.term }
        let lang = targetLangCode
        Task.detached(priority: .background) {
            for word in audioWords {
                await TTSManager.shared.prefetchAsync(word, langCode: lang)
            }
        }
    }

    // MARK: - Setup: AI Generated Quiz
    func setupAIQuiz(questions: [GameQuestion], title: String) {
        self.sessionType     = .aiGenerated(title: title)
        self.levelTitle      = title
        startedAt = Date()
        Track.practice("start", type: "ai_quiz", wordCount: questions.count, entryPoint: "ai_quiz")
        self.targetLangCode  = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        self.questions       = questions
        self.currentIndex    = 0
        self.score           = 0
        self.writingAnswer   = ""
        self.sessionMistakes = []
        self.state           = questions.isEmpty ? .completed(score: 0, stars: 0, xpEarned: 0) : .question
    }

    // MARK: - Answer: Multiple Choice
    func submitMultipleChoice(selected: String) {
        guard case .question = state, let q = currentQuestion else { return }
        recordAnswer(isCorrect: selected.trimmingCharacters(in: .whitespaces) == q.correctAnswer.trimmingCharacters(in: .whitespaces))
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
        // correctAnswer for speaking = word.term (target language word to pronounce)
        let correct = SpeechRecognitionManager.shared.isCorrect(
            recognized: recognized,
            expected: q.correctAnswer
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
        // correctAnswer is now always word.term for fillInTheBlank (fixed in generate())
        recordAnswer(isCorrect: selected.trimmingCharacters(in: .whitespaces) == q.correctAnswer.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Answer: Sentence Builder
    func submitSentenceBuilder(selectedWord: String) {
        guard case .question = state, let q = currentQuestion else { return }
        // correctAnswer = nativeMeaning for sentenceBuilder (targetToNative direction)
        recordAnswer(isCorrect: selectedWord.lowercased() == q.correctAnswer.lowercased())
    }

    // MARK: - Answer: Build Sentence (noktalama ve büyük/küçük harf önemsiz)
    func submitBuildSentence(tokens: [String]) {
        guard case .question = state, let q = currentQuestion else { return }
        let norm = { (a: [String]) in a.map { $0.lowercased() }.joined(separator: " ") }
        recordAnswer(isCorrect: norm(tokens) == norm(q.answerTokens))
    }

    // MARK: - Answer: Match Pairs (en fazla 1 hata ile geçer)
    func submitMatch(mistakes: Int) {
        guard case .question = state else { return }
        recordAnswer(isCorrect: mistakes <= 1)
    }

    // MARK: - Yeni kelime kartı → devam (günlük hak harcamaz, puanlanmaz)
    func continueAfterIntro() {
        guard case .question = state else { return }
        nextQuestion()
    }

    // MARK: - Core Record
    private func recordAnswer(isCorrect: Bool) {
        // Günlük soru hakkını kullan
        DailyLimitManager.shared.recordQuestion()
        StudyStreak.record()

        if isCorrect {
            score += 1
            showXPToastAnimation()
            // Mistakes quiz: remove correctly answered word immediately so count updates live
            if case .mistakes = sessionType, let q = currentQuestion {
                MistakesManager.shared.removeMistakes([q.word.id.uuidString])
            }
            // Widget "Günün Kelimesi" için öğrenilen kelimeyi kaydet (seviye + hatalar quizleri)
            if let q = currentQuestion, q.tracksWord, isWordSession {
                let native = OL.nativeLangCode
                LearnedWordsStore.add([LearnedWord(
                    id: q.word.id.uuidString,
                    term: q.word.term,
                    meaning: q.word.displayTranslation(phoneCode: native),
                    phonetic: q.word.pronunciation,
                    languageCode: targetLangCode.uppercased(),
                    learnedAt: Date()
                )], nativeLangCode: native)
                Task { @MainActor in ReviewScheduler.shared.reload() }
            }
        } else {
            // Cümle sorularının word.id'si geçici bir UUID — hatalar listesine yazma (asla temizlenemez)
            if let q = currentQuestion, q.tracksWord {
                sessionMistakes.insert(q.word.id.uuidString)
            }
        }
        state = .answered(isCorrect: isCorrect)
    }

    /// Gerçek kelime içeren oturumlar (AI quiz'in sentetik soruları hariç)
    private var isWordSession: Bool {
        switch sessionType {
        case .level, .mistakes: return true
        default:                return false
        }
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

        // Önceki kelimenin sesi yeni soruya taşmasın
        TTSManager.shared.stop()
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
        case .aiGenerated:
            break   // AI quiz doesn't track mistakes
        }
    }

    // MARK: - Finish & Save
    private func finishQuiz() async {
        isSaving = true
        Track.practice("complete", type: practiceType, wordCount: questions.count, correct: correctCount,
                       total: questions.count, duration: Date().timeIntervalSince(startedAt), entryPoint: "practice")

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

            // quiz_attempts kaydet (arka planda)
            if let uid = Optional(UserStore.shared.userId) {
                let attempts: [SBQuizAttemptInsert] = questions.filter(\.isScored).map { q in
                    let isCorrect = !sessionMistakes.contains(q.word.id.uuidString)
                    return SBQuizAttemptInsert(
                        userId: uid,
                        levelId: levelId,
                        wordId: q.word.id,
                        quizMode: q.mode.rawValue,
                        userAnswer: nil,
                        correctAnswer: q.correctAnswer,
                        isCorrect: isCorrect,
                        responseMs: nil
                    )
                }
                Task.detached(priority: .background) {
                    try? await DataService.shared.saveQuizAttempts(attempts)
                }
            }

            do {
                let response = try await DataService.shared.completeLevel(
                    levelId: levelId,
                    score: scorePercent,
                    quizMode: "multipleChoice"
                )
                // Kolaylaştırılmış geçiş: sunucu onayı VEYA %50+ doğruluk oranı yeterli
                let isLevelPassed = response.success || scorePercent >= 50
                if isLevelPassed {
                    UserDefaults.standard.set(true, forKey: "justCompletedLevel")
                    // If server didn't unlock next level (e.g. old RPC / score below server threshold),
                    // apply client-side fallback so the path map always reflects the result.
                    if !response.success {
                        await DataService.shared.unlockNextLevelFallback(afterLevelId: levelId, score: scorePercent)
                    }
                }
                let earnedStars: Int
                if scorePercent >= 90 { earnedStars = 3 }
                else if scorePercent >= 70 { earnedStars = 2 }
                else if scorePercent >= 50 { earnedStars = 1 }
                else { earnedStars = response.stars ?? 0 }
                let finalStars = max(earnedStars, response.stars ?? 0)
                UserDefaults.standard.set(scorePercent, forKey: "lastCompletedScore")
                UserDefaults.standard.set(finalStars,   forKey: "lastCompletedStars")
                state = .completed(
                    score: scorePercent,
                    stars: finalStars,
                    xpEarned: response.xpEarned ?? max(score * 10, 0)
                )
                await triggerAchievementCheck()
            } catch {
                print("⚠️ completeLevel error: \(error)")
                // Hata durumunda bile %50+ ise geçti say
                if scorePercent >= 50 {
                    UserDefaults.standard.set(true, forKey: "justCompletedLevel")
                    // RPC tamamen başarısız — doğrudan DB'ye yaz
                    await DataService.shared.unlockNextLevelFallback(afterLevelId: levelId, score: scorePercent)
                }
                let fallbackStars = scorePercent >= 90 ? 3 : scorePercent >= 70 ? 2 : scorePercent >= 50 ? 1 : 0
                UserDefaults.standard.set(scorePercent,   forKey: "lastCompletedScore")
                UserDefaults.standard.set(fallbackStars,  forKey: "lastCompletedStars")
                state = .completed(score: scorePercent, stars: fallbackStars, xpEarned: score * 10)
                await triggerAchievementCheck()
            }

        case .mistakes:
            let allIds     = Set(questions.filter(\.tracksWord).map { $0.word.id.uuidString })
            let correctIds = allIds.subtracting(sessionMistakes)
            if !correctIds.isEmpty { MistakesManager.shared.removeMistakes(correctIds) }
            if !MistakesManager.shared.hasMistakes {
                UserDefaults.standard.set(true, forKey: "justClearedMistakes")
            }
            let mistakesXP = score * 5
            await DataService.shared.awardXP(mistakesXP)
            state = .completed(score: scorePercent, stars: 3, xpEarned: mistakesXP)
            await triggerAchievementCheck()

        case .aiGenerated(let title):
            let stars  = scorePercent >= 80 ? 3 : scorePercent >= 60 ? 2 : scorePercent >= 40 ? 1 : 0
            let aiXP   = score * 8
            await DataService.shared.awardXP(aiXP)
            state = .completed(score: scorePercent, stars: stars, xpEarned: aiXP)
            await triggerAchievementCheck()

            // Yanlış yapılan soruları Decks'e kaydet
            if !sessionMistakes.isEmpty {
                let wrongQs  = questions.filter { sessionMistakes.contains($0.word.id.uuidString) }
                let langCode = targetLangCode
                let topicTitle = title
                Task.detached(priority: .background) {
                    await PathMistakesDeckService.shared.createDeckFromAIMistakes(
                        questions: wrongQs,
                        topicTitle: topicTitle,
                        targetLangCode: langCode
                    )
                }
            }
        }

        isSaving = false
    }

    // MARK: - Achievement Check
    /// Fetches fresh user profile + stats and runs achievement unlock logic.
    private func triggerAchievementCheck() async {
        do {
            let user  = try await DataService.shared.fetchUserProfile()
            let stats = try await DataService.shared.fetchUserStats()
            if let user {
                await AchievementService.shared.checkAndUnlock(user: user, stats: stats)
            }
        } catch {
            print("⚠️ Achievement check failed: \(error)")
        }
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

    /// Eşleştirme sorusu için kelime–anlam çiftleri
    var pairs: [MatchPair] = []
    /// buildSentence: doğru sıradaki hedef dil kelimeleri
    var answerTokens: [String] = []

    struct MatchPair: Hashable {
        let term: String
        let meaning: String
    }

    func with(pairs: [MatchPair]) -> GameQuestion { var c = self; c.pairs = pairs; return c }

    /// Puanlanan soru mu (yeni kelime kartı puanlanmaz)
    var isScored: Bool { mode != .introduce }

    /// Bu soru tek bir gerçek kelimeyi mi ölçüyor (hatalar listesi / öğrenilen kelimeler için)
    var tracksWord: Bool {
        sentence == nil && [.multipleChoice, .listening, .fillInTheBlank, .speaking, .writing, .trueFalse].contains(mode)
    }

    // MARK: - Ders üretimi
    /// Duolingo tarzı ders akışı:
    ///  • yeni kelime kartı → hemen ardından o kelimenin alıştırması (araya bir sonraki kelime girer)
    ///  • alıştırma tipleri dönüşümlü: anlamını seç → dinle → ters yön → boşluk doldur
    ///  • her 5 kelimede bir eşleştirme turu
    ///  • sonda seviyenin cümleleri: kelimenin cümledeki anlamı, cümle çevirisi, cümle kurma
    /// `sentences` = bu seviyenin cümleleri, `pool` = çeldirici için kursun tüm cümleleri.
    static func generate(from words: [SBWord], sentences: [SBSentence] = [], pool: [SBSentence] = [],
                         proficiency: Int = 2, introduceNew: Bool = true) -> [GameQuestion] {
        guard !words.isEmpty else { return [] }
        let native  = OL.nativeLangCode
        let target  = (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN").uppercased()
        let known   = Set(LearnedWordsStore.load().map(\.id))
        let meaning = { (w: SBWord) in w.displayTranslation(phoneCode: native) }

        var steps: [GameQuestion] = []
        var practiceCounter = 0

        func practice(_ w: SBWord) -> GameQuestion {
            defer { practiceCounter += 1 }
            let kinds: [QuizMode] = [.multipleChoice, .listening, .multipleChoice, .fillInTheBlank]
            var kind = kinds[practiceCounter % kinds.count]
            let reverse = practiceCounter % kinds.count == 2
            if kind == .fillInTheBlank, gapSentence(for: w) == nil { kind = .multipleChoice }
            return question(for: w, mode: kind, reverse: reverse, in: words, native: native)
        }

        // 5'li gruplar: yeni kelime tanıtılır ve (seçili kelimelerde) HEMEN o kelime sorulur —
        // başka kelimeye geçmeden; grup sonunda tümünü pekiştiren eşleştirme. Kısa ve anlaşılır (~18 adım).
        let chunks = stride(from: 0, to: words.count, by: 5).map { Array(words[$0..<min($0 + 5, words.count)]) }
        for chunk in chunks {
            for (i, w) in chunk.enumerated() {
                let isNew = introduceNew && !known.contains(w.id.uuidString)
                if isNew { steps.append(introduce(w, native: native)) }
                // Yeni kelimelerde 1., 3. ve 5. kelime; bilinenlerde ilk 3 kelime sorulur (gerisini eşleştirme yoklar)
                let ask = isNew ? i % 2 == 0 : i < 3
                if ask { steps.append(practice(w)) }
            }
            if chunk.count >= 3 { steps.append(match(chunk, native: native)) }
        }

        // Cümleler
        let spaced = !["ZH", "JA"].contains(target)
        for (i, s) in sentences.prefix(2).enumerated() {
            if i == 0, let q = wordInContext(s, words: words, native: native) { steps.append(q) }
            if i % 2 == 1 && spaced, let q = buildSentence(s, pool: pool) {
                steps.append(q)
            } else if let q = translateSentence(s, pool: pool) {
                steps.append(q)
            }
        }
        return steps
    }

    // MARK: - Soru kurucuları
    private static func introduce(_ w: SBWord, native: String) -> GameQuestion {
        var q = GameQuestion(word: w, mode: .introduce, options: [], correctAnswer: w.term,
                             displayedMeaning: w.displayTranslation(phoneCode: native), isCorrectPair: true)
        q.promptText = w.term
        return q
    }

    private static func question(for w: SBWord, mode: QuizMode, reverse: Bool, in words: [SBWord], native: String) -> GameQuestion {
        let m = w.displayTranslation(phoneCode: native)
        let others = words.filter { $0.id != w.id }.shuffled()
        let wrongNative = Array(Set(others.map { $0.displayTranslation(phoneCode: native) }).subtracting([m])).shuffled()
        let wrongTerms  = Array(Set(others.map(\.term)).subtracting([w.term])).shuffled()

        var q: GameQuestion
        switch mode {
        case .fillInTheBlank:
            q = GameQuestion(word: w, mode: .fillInTheBlank, options: [], correctAnswer: w.term,
                             displayedMeaning: m, isCorrectPair: true)
            q.gapSentence   = gapSentence(for: w) ?? ""
            q.sentenceWords = (Array(wrongTerms.prefix(3)) + [w.term]).shuffled()
        case .listening:
            q = GameQuestion(word: w, mode: .listening, options: (Array(wrongNative.prefix(3)) + [m]).shuffled(),
                             correctAnswer: m, displayedMeaning: m, isCorrectPair: true)
        default:
            let options = reverse ? (Array(wrongTerms.prefix(3)) + [w.term]) : (Array(wrongNative.prefix(3)) + [m])
            q = GameQuestion(word: w, mode: .multipleChoice, options: options.shuffled(),
                             correctAnswer: reverse ? w.term : m, displayedMeaning: m, isCorrectPair: true)
            q.questionDirection = reverse ? .nativeToTarget : .targetToNative
        }
        q.promptText = (mode == .multipleChoice && reverse) ? m : w.term
        return q
    }

    /// Örnek cümlede kelimeyi "____" ile değiştirir (bulunamazsa nil)
    static func gapSentence(for w: SBWord) -> String? {
        guard let ex = w.exampleSentence, !ex.isEmpty,
              let r = ex.range(of: w.term, options: [.caseInsensitive, .diacriticInsensitive]) else { return nil }
        return ex.replacingCharacters(in: r, with: "____")
    }

    private static func match(_ chunk: [SBWord], native: String) -> GameQuestion {
        var q = GameQuestion(word: chunk[0], mode: .matchPairs, options: [], correctAnswer: "",
                             displayedMeaning: "", isCorrectPair: true)
        q.pairs = chunk.map { MatchPair(term: $0.term, meaning: $0.displayTranslation(phoneCode: native)) }
        return GameQuestion(word: q.word, mode: .matchPairs, options: [],
                            correctAnswer: q.pairs.map { "\($0.term) = \($0.meaning)" }.joined(separator: " · "),
                            displayedMeaning: "", isCorrectPair: true).with(pairs: q.pairs)
    }

    private static func placeholder(_ s: SBSentence, term: String, meaning: String) -> SBWord {
        SBWord(id: UUID(), sourceLangId: 1, targetLangId: 2, term: term, translation: meaning,
               phonetic: nil, description: nil, exampleSentence: s.targetText,
               difficulty: s.difficulty, translations: nil)
    }

    /// "Bu cümlede 'X' ne demek?" — anahtar kelimenin anlamını seç
    private static func wordInContext(_ s: SBSentence, words: [SBWord], native: String) -> GameQuestion? {
        guard let key = s.keyWord, let keyNative = s.keyWordNative, !key.isEmpty, !keyNative.isEmpty else { return nil }
        let distractors = Array(Set(words.map { $0.displayTranslation(phoneCode: native) }).subtracting([keyNative]))
            .shuffled().prefix(3)
        var q = GameQuestion(word: placeholder(s, term: key, meaning: keyNative), mode: .sentenceBuilder,
                             options: [], correctAnswer: keyNative, displayedMeaning: keyNative, isCorrectPair: true)
        q.promptText    = s.targetText
        q.sentenceWords = (Array(distractors) + [keyNative]).shuffled()
        q.sentence      = s
        return q
    }

    /// Cümlenin doğru çevirisini 3 seçenek arasından bul
    private static func translateSentence(_ s: SBSentence, pool: [SBSentence]) -> GameQuestion? {
        let correct = s.nativeText
        let wrong = Array(Set(pool.filter { $0.id != s.id }.map(\.nativeText)).subtracting([correct])).shuffled().prefix(2)
        guard !wrong.isEmpty else { return nil }
        var q = GameQuestion(word: placeholder(s, term: s.targetText, meaning: correct), mode: .translateSentence,
                             options: (Array(wrong) + [correct]).shuffled(), correctAnswer: correct,
                             displayedMeaning: correct, isCorrectPair: true)
        q.promptText = s.targetText
        q.sentence   = s
        return q
    }

    /// Ana dildeki cümleyi gösterir; kullanıcı hedef dil kelimelerini sırayla dizer
    private static func buildSentence(_ s: SBSentence, pool: [SBSentence]) -> GameQuestion? {
        let tokens = tokenize(s.targetText)
        guard tokens.count >= 3, tokens.count <= 10 else { return translateSentence(s, pool: pool) }
        let lower = Set(tokens.map { $0.lowercased() })
        let extra = Array(Set(pool.filter { $0.id != s.id }.flatMap { tokenize($0.targetText) })
            .filter { !lower.contains($0.lowercased()) }).shuffled().prefix(3)
        var q = GameQuestion(word: placeholder(s, term: s.targetText, meaning: s.nativeText), mode: .buildSentence,
                             options: [], correctAnswer: tokens.joined(separator: " "),
                             displayedMeaning: s.nativeText, isCorrectPair: true)
        q.promptText    = s.nativeText
        q.answerTokens  = tokens
        q.sentenceWords = (tokens + extra).shuffled()
        q.sentence      = s
        return q
    }

    /// Boşluklara göre böler, kelime başı/sonundaki noktalamayı atar ("¿Cómo" → "Cómo")
    static func tokenize(_ text: String) -> [String] {
        let punct = CharacterSet.punctuationCharacters.union(.symbols)
        return text.split(whereSeparator: \.isWhitespace)
            .map { String($0).trimmingCharacters(in: punct) }
            .filter { !$0.isEmpty }
    }
}

