//
//  GameQuizView.swift
//  WordRemSwiftUI
//
//  Full-screen level quiz — daily 25-question limit, progress line, XP note.
//  Hearts / lives system removed. Replaced with a daily limit paywall popup.
//  "Paper & ink" design: the prompt is the hero; flat paper surfaces, hairline borders.
//

import SwiftUI
import AVFoundation

struct GameQuizView: View {

    let sessionType: QuizSessionType
    let title: String
    var preloadedQuestions: [GameQuestion] = []

    @EnvironmentObject var langManager: LanguageManager
    @StateObject private var vm = GameQuizViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var wordsLoaded = false
    @State private var loadAttempt = 0
    @State private var showPaywall = false
    @State private var showHintSheet = false
    @State private var hintText: String = ""
    @State private var isLoadingHint = false
    @State private var pendingAnswer: String? = nil   // seçildi ama henüz kontrol edilmedi
    @State private var submittedAnswer: String? = nil // kontrol edilen seçim (yanlışı işaretlemek için)
    @State private var showQuitAlert = false          // çıkış onay uyarısı
    @State private var talkLevel: UUID?               // seviye sonrası sesli pratik
    /// Tracks the last question index for which audio was auto-played, preventing
    /// re-triggers when the view re-renders on state transitions (.question → .answered).
    @State private var autoPlayedIndex: Int = -1

    var body: some View {
        ZStack {
            DS.Colors.paper.ignoresSafeArea()
                .hideKeyboardOnTap()

            switch vm.state {
            case .loading:
                loadingView

            case .question:
                if let question = vm.currentQuestion {
                    questionView(question)
                        // Doğru cevabı önceden önbelleğe al — tüm soru tipleri için
                        // Speaking sorularda da prefetch yapıyoruz (sadece cache; otomatik çalmıyoruz)
                        .task(id: vm.currentIndex) {
                            let langCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
                            let text = question.correctAnswer
                            guard !text.isEmpty else { return }
                            await TTSManager.shared.prefetchAsync(text, langCode: langCode)
                        }
                }

            case .answered(let isCorrect):
                if let question = vm.currentQuestion {
                    questionView(question)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            feedbackOverlay(isCorrect: isCorrect)
                        }
                        .onAppear {
                            if isCorrect {
                                // Konfeti yerine sakin bir başarı titreşimi
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                // Auto-play the correct answer
                                let langCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
                                let textToSpeak = vm.currentQuestion?.correctAnswer ?? ""
                                if !textToSpeak.isEmpty {
                                    TTSManager.shared.speak(textToSpeak, langCode: langCode)
                                }
                            }
                        }
                }

            case .dailyLimitReached:
                Group {
                    if let q = vm.currentQuestion ?? vm.questions.last {
                        questionView(q).blur(radius: 4)
                    } else {
                        DS.Colors.paper
                    }
                }
                .overlay(QuizDailyLimitOverlay(onPaywall: { showPaywall = true },
                                               onQuit: { dismiss() }))

            case .loadFailed:
                loadFailedView

            case .completed(let score, let stars, let xp):
                QuizResultView(
                    score: score,
                    stars: stars,
                    xpEarned: xp,
                    levelTitle: title,
                    onDone: { dismiss() },
                    onTalk: { if case .level(let id) = sessionType { talkLevel = id } }
                )
                .fullScreenCover(item: Binding(get: { talkLevel.map(TalkLevel.init) }, set: { talkLevel = $0?.id })) { item in
                    VoiceTutorView(mode: .levelReview(levelId: item.id))
                }
            }

            // XP note — sakin, küçük bir etiket
            if vm.showXPToast {
                QuizXPNote(amount: vm.xpToast)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: vm.showXPToast)
            }
        }
        .onChange(of: vm.currentIndex) { _ in
            pendingAnswer = nil
            submittedAnswer = nil
        }
        .task(id: loadAttempt) {
            guard !wordsLoaded else { return }
            wordsLoaded = true
            // .aiGenerated: sorular AIQuizView'dan preloadedQuestions olarak gelir
            if case .aiGenerated(let t) = sessionType {
                vm.setupAIQuiz(questions: preloadedQuestions, title: t)
                return
            }
            do {
                let words: [SBWord]
                var sentences: [SBSentence] = []
                var pool: [SBSentence] = []
                switch sessionType {
                case .level(let lId):
                    // Proficiency → max difficulty (kelimeler + cümleler)
                    // 0/1 beginner/elementary  → difficulty 1 (A1/A2)
                    // 2   intermediate          → difficulty 2 (B1)
                    // 3+  upper/advanced        → difficulty 3 (B2/C1)
                    let proficiency = UserDefaults.standard.integer(forKey: "selectedProficiencyLevel")
                    let maxDiff: Int
                    switch proficiency {
                    case 0, 1: maxDiff = 1
                    case 2:    maxDiff = 2
                    default:   maxDiff = 3
                    }

                    words = try await DataService.shared.fetchWords(levelId: lId, maxDifficulty: maxDiff)
                    if let courseId = words.isEmpty ? nil : (try? await DataService.shared.fetchCourseId(forLevel: lId)) {
                        // Seviyenin kendi cümleleri; çeldiriciler için kursun tüm cümleleri
                        pool = (try? await DataService.shared.fetchSentences(courseId: courseId, maxDifficulty: 3)) ?? []
                        sentences = pool.filter { $0.levelId == lId }
                    }
                case .mistakes:
                    let ids = MistakesManager.shared.mistakeUUIDs
                    words = try await DataService.shared.fetchWords(byIds: ids)
                    // Veritabanında karşılığı olmayan (eski/geçersiz) id'leri listeden temizle
                    let found = Set(words.map { $0.id })
                    let stale = Set(ids.filter { !found.contains($0) }.map { $0.uuidString })
                    MistakesManager.shared.removeMistakes(stale)
                case .aiGenerated: return   // already handled above
                }
                vm.setup(sessionType: sessionType, words: words, sentences: sentences, pool: pool, levelTitle: title)
            } catch {
                print("❌ Failed to load words: \(error)")
                vm.state = .loadFailed
            }
        }
        .sheet(isPresented: $showPaywall) {
            OnboardingPaywallView {
                showPaywall = false
                // Premium aktivasyonundan sonra quiz'i sıfırla
                if DailyLimitManager.shared.isPremium {
                    vm.setup(sessionType: sessionType,
                             words: uniqueWords(vm.questions.filter(\.tracksWord).map(\.word)),
                             sentences: Array(Set(vm.questions.compactMap { $0.sentence?.id })).compactMap { id in vm.questions.first { $0.sentence?.id == id }?.sentence },
                             levelTitle: title)
                }
            }
        }
        .sheet(isPresented: $showHintSheet) {
            QuizHintSheet(hintText: hintText, hintsRemaining: HintManager.shared.hintsRemaining)
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().tint(DS.Colors.inkSoft)
            Text(AL.s(.gameLoading))
                .font(DS.Font.ui(15, weight: .medium))
                .foregroundStyle(DS.Colors.muted)
        }
    }

    // MARK: - Load Failed
    private var loadFailedView: some View {
        VStack {
            Spacer()
            PaperCard(padding: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    QuizCircleIcon {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                    Text(AL.s(.loadFailedMessage))
                        .font(DS.Font.display(22, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 10) {
                        Button(AL.s(.paywallRetry)) {
                            vm.state = .loading
                            wordsLoaded = false
                            loadAttempt += 1
                        }
                        .buttonStyle(InkButtonStyle())
                        Button(AL.s(.gameQuit)) { dismiss() }
                            .buttonStyle(OutlineButtonStyle())
                    }
                    .padding(.top, 6)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .quizReadableWidth()
    }

    // MARK: - Question Screen
    @ViewBuilder
    private func questionView(_ question: GameQuestion) -> some View {
        switch question.mode {
        case .listening:
            listeningView(question)
        case .speaking:
            speakingView(question)
        case .fillInTheBlank:
            fillInTheBlankView(question)
        case .sentenceBuilder:
            sentenceBuilderView(question)
        case .introduce:
            introduceView(question)
        case .translateSentence:
            translateSentenceView(question)
        case .buildSentence:
            buildSentenceView(question)
        case .matchPairs:
            matchPairsView(question)
        default:
            standardQuestionView(question)
        }
    }

    private var isAnswered: Bool {
        if case .answered = vm.state { return true }
        return false
    }

    @ViewBuilder
    private func standardQuestionView(_ question: GameQuestion) -> some View {
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        let isMulti = question.mode == .multipleChoice && !question.options.isEmpty
        let answered = isAnswered

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 12)
            wordCard(question)
            Spacer(minLength: 16)
            // AI soruları kendi sorusunu taşıyor — altta ayrıca "anlamı nedir?" gerekmez
            if case .aiGenerated = sessionType {
                EmptyView()
            } else {
                Text(question.questionDirection == .targetToNative
                     ? AL.s(.gameWhatIsMeaning)
                     : AL.f(.quizWordForFmt, languageDisplayName(targetLang)))
                    .font(DS.Font.ui(16, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            }
            Spacer(minLength: 16)
            if isMulti {
                multipleChoiceGrid(question)
            } else {
                writingField
            }
            Spacer(minLength: 12)
        }
        .quizReadableWidth()
        // Kontrol Et butonu — multipleChoice için her zaman altta sabit
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isMulti && !answered {
                bottomCheckBar(onCheck: {
                    guard let chosen = pendingAnswer else { return }
                    submittedAnswer = chosen
                    vm.submitMultipleChoice(selected: chosen)
                    pendingAnswer = nil
                })
            }
        }
    }

    private func bottomCheckBar(onCheck: @escaping () -> Void) -> some View {
        let label = langManager.s(.gameCheck)
        let hasSelection = pendingAnswer != nil
        return VStack(spacing: 0) {
            Rectangle().fill(DS.Colors.line).frame(height: 1)
            Button(label, action: onCheck)
                .buttonStyle(InkButtonStyle(fill: hasSelection ? DS.Colors.ink : DS.Colors.line,
                                            foreground: hasSelection ? DS.Colors.paperRaised : DS.Colors.muted))
                .disabled(!hasSelection)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .quizReadableWidth()
                .animation(.easeOut(duration: 0.15), value: hasSelection)
        }
        .background(DS.Colors.paper.ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Listening View
    @ViewBuilder
    private func listeningView(_ question: GameQuestion) -> some View {
        let answered = isAnswered
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 12)

            // Listening card with built-in loading state and auto-play
            QuizListeningCard(term: question.word.term,
                              langCode: targetLang,
                              languageName: languageDisplayName(targetLang))

            Spacer(minLength: 20)

            // Options grid (same as multipleChoice, but answer = translation)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    QuizOptionChip(
                        text: option,
                        status: quizOptionStatus(option, correct: question.correctAnswer,
                                                 answered: answered, selected: nil,
                                                 submitted: submittedAnswer)
                    ) {
                        if !answered {
                            submittedAnswer = option
                            vm.submitListening(selected: option)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 28)
        }
        .quizReadableWidth()
    }

    // MARK: - Speaking View
    @ViewBuilder
    private func speakingView(_ question: GameQuestion) -> some View {
        let targetLang  = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        // word.term = target-language word (the word to say)
        // word.translation = native-language hint (what it means in user's language)
        let wordToSay   = question.word.term
        let nativeHint  = question.word.translation

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 12)

            // Word card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Eyebrow(text: AL.s(.gameSpeakPrompt))
                    Spacer(minLength: 12)
                    Button {
                        TTSManager.shared.speak(wordToSay, langCode: targetLang)
                    } label: {
                        QuizCircleIcon {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DS.Colors.ink)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // ── Word to say (TARGET language) ─────────────────
                QuizPromptText(text: wordToSay)

                // ── Phonetic ──────────────────────────────────────
                if let phonetic = question.word.pronunciation {
                    Text(phonetic)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(DS.Colors.muted)
                }

                Rectangle().fill(DS.Colors.line).frame(width: 32, height: 2)
                    .padding(.top, 4)

                // ── Native hint (meaning in user's language) ──────
                if !nativeHint.isEmpty {
                    Text(nativeHint)
                        .font(DS.Font.display(20, weight: .regular))
                        .foregroundStyle(DS.Colors.inkSoft)
                }

                // ── Language label ───────────────────────────────
                Text(languageDisplayName(targetLang))
                    .font(DS.Font.ui(13, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
            }
            .quizCardSurface()
            .padding(.horizontal, 24)
            .onAppear {
                TTSManager.shared.stop()
            }

            Spacer(minLength: 20)

            // Mic area
            QuizSpeakingMicButton(
                langCode: targetLang,
                questionIndex: vm.currentIndex,
                onResult: { recognized in
                    vm.submitSpeaking(recognized: recognized)
                },
                onMute: {
                    // 15 dakika sesli soru bastırma
                    let muteUntil = Date().addingTimeInterval(15 * 60)
                    UserDefaults.standard.set(muteUntil, forKey: "speakingMutedUntil")
                }
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 28)
        }
        .quizReadableWidth()
    }

    // MARK: - Fill in the Blank View
    @ViewBuilder
    private func fillInTheBlankView(_ question: GameQuestion) -> some View {
        let answered = isAnswered

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 12)

            // Gap sentence card + hint button
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Eyebrow(text: AL.s(.gameFillBlank))
                    Spacer(minLength: 12)
                    hintButton(for: question)
                }

                // Path format: "_____ → Good morning" → show "Translate: Good morning"
                // AI format: "She ___ to school" → show sentence with gap
                let parts = question.gapSentence.components(separatedBy: " → ")
                if question.gapSentence.contains("____") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(question.gapSentence)
                            .font(DS.Font.display(26, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(AL.f(.quizMeaningHint, question.displayedMeaning))
                            .font(DS.Font.ui(15, weight: .medium))
                            .foregroundStyle(DS.Colors.muted)
                    }
                } else if parts.count == 2 && question.gapSentence.hasPrefix("_") {
                    // Path word question
                    VStack(alignment: .leading, spacing: 6) {
                        Text(AL.s(.gameTranslateLabel))
                            .font(DS.Font.ui(14, weight: .medium))
                            .foregroundStyle(DS.Colors.muted)
                        QuizPromptText(text: parts[1])
                    }
                } else {
                    // AI sentence with gap — tappable words + TTS
                    let tgtCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en"
                    QuizAITappableWords(
                        sentence: question.gapSentence,
                        targetLangCode: tgtCode,
                        nativeLangCode: OL.nativeLangCode
                    )
                }
            }
            .quizCardSurface()
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            // Word options — seç → Kontrol Et
            // id: \.offset — aynı seçenek birden fazla kez gelirse crash olmaz
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(question.sentenceWords.enumerated()), id: \.offset) { _, wordOption in
                    QuizOptionChip(
                        text: wordOption,
                        status: quizOptionStatus(wordOption, correct: question.correctAnswer,
                                                 answered: answered, selected: pendingAnswer,
                                                 submitted: submittedAnswer)
                    ) {
                        if !answered {
                            withAnimation(.easeOut(duration: 0.15)) { pendingAnswer = wordOption }
                        }
                    }
                    .disabled(answered)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 12)
        }
        .quizReadableWidth()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !answered {
                bottomCheckBar(onCheck: {
                    guard let chosen = pendingAnswer else { return }
                    submittedAnswer = chosen
                    vm.submitFillInTheBlank(selected: chosen)
                    pendingAnswer = nil
                })
            }
        }
    }

    private func uniqueWords(_ words: [SBWord]) -> [SBWord] {
        var seen = Set<UUID>()
        return words.filter { seen.insert($0.id).inserted }
    }

    private var targetLangCode: String {
        UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
    }

    // MARK: - Yeni kelime kartı
    @ViewBuilder
    private func introduceView(_ question: GameQuestion) -> some View {
        let w = question.word
        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 12)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Eyebrow(text: AL.s(.hcNewWord), color: DS.Colors.accent)
                    Spacer()
                    Button { TTSManager.shared.speak(w.term, langCode: targetLangCode) } label: {
                        QuizCircleIcon {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DS.Colors.ink)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AL.s(.quizTapToHear))
                }
                Text(w.term)
                    .font(DS.Font.display(40, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let p = w.pronunciation, !p.isEmpty {
                    Text(p)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(DS.Colors.muted)
                }
                Rectangle().fill(DS.Colors.accent).frame(width: 32, height: 2)
                Text(question.displayedMeaning)
                    .font(DS.Font.display(24, weight: .regular))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                if let ex = w.exampleSentence, !ex.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: AL.s(.quizExample), color: DS.Colors.muted)
                        Button { TTSManager.shared.speak(ex, langCode: targetLangCode) } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Text(ex)
                                    .font(DS.Font.ui(17))
                                    .foregroundStyle(DS.Colors.ink)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                                Image(systemName: "speaker.wave.1")
                                    .font(.system(size: 13))
                                    .foregroundStyle(DS.Colors.muted)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                }
            }
            .quizCardSurface()
            .padding(.horizontal, 24)
            Spacer(minLength: 20)
        }
        .quizReadableWidth()
        .onAppear { TTSManager.shared.speak(w.term, langCode: targetLangCode) }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Rectangle().fill(DS.Colors.line).frame(height: 1)
                Button(AL.s(.quizGotIt)) { vm.continueAfterIntro() }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .quizReadableWidth()
            }
            .background(DS.Colors.paper.ignoresSafeArea(edges: .bottom))
        }
    }

    // MARK: - Cümle çevirisi
    @ViewBuilder
    private func translateSentenceView(_ question: GameQuestion) -> some View {
        let answered = isAnswered
        VStack(spacing: 0) {
            quizHeader
            QuizInstruction(eyebrow: AL.s(.hcTranslateSentence), title: AL.s(.quizTranslateSentence))
            QuizSentenceCard(text: question.promptText, langCode: targetLangCode)
            Spacer(minLength: 20)
            VStack(spacing: 10) {
                ForEach(question.options, id: \.self) { option in
                    QuizOptionChip(
                        text: option,
                        status: quizOptionStatus(option, correct: question.correctAnswer, answered: answered,
                                                 selected: pendingAnswer, submitted: submittedAnswer)
                    ) {
                        if !answered { withAnimation(.easeOut(duration: 0.15)) { pendingAnswer = option } }
                    }
                    .disabled(answered)
                }
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 12)
        }
        .quizReadableWidth()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !answered {
                bottomCheckBar(onCheck: {
                    guard let chosen = pendingAnswer else { return }
                    submittedAnswer = chosen
                    vm.submitMultipleChoice(selected: chosen)
                    pendingAnswer = nil
                })
            }
        }
    }

    // MARK: - Cümle kurma
    @ViewBuilder
    private func buildSentenceView(_ question: GameQuestion) -> some View {
        VStack(spacing: 0) {
            quizHeader
            QuizBuildSentenceContent(question: question, isAnswered: isAnswered, targetLang: targetLangCode) { tokens in
                vm.submitBuildSentence(tokens: tokens)
            }
            .id(question.id)
        }
        .quizReadableWidth()
    }

    // MARK: - Eşleştirme
    @ViewBuilder
    private func matchPairsView(_ question: GameQuestion) -> some View {
        VStack(spacing: 0) {
            quizHeader
            QuizMatchPairsContent(question: question, isAnswered: isAnswered, targetLang: targetLangCode) { mistakes in
                vm.submitMatch(mistakes: mistakes)
            }
            .id(question.id)
        }
        .quizReadableWidth()
    }

    // MARK: - Sentence Builder View
    @ViewBuilder
    private func sentenceBuilderView(_ question: GameQuestion) -> some View {
        let answered = isAnswered
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"

        VStack(spacing: 0) {
            quizHeader
            QuizSentenceBuilderContent(
                question: question,
                isAnswered: answered,
                targetLang: targetLang,
                onSubmit: { selected in
                    vm.submitSentenceBuilder(selectedWord: selected)
                }
            )
        }
        .quizReadableWidth()
    }

    // MARK: - Header  (close · progress line · n/total · daily remaining)
    private var quizHeader: some View {
        HStack(spacing: 16) {
            // Quit
            Button { showQuitAlert = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 36, height: 36)
            }
            .alert(AL.s(.gameQuitTitle), isPresented: $showQuitAlert) {
                Button(AL.s(.gameQuitKeepGoing), role: .cancel) { }
                Button(AL.s(.gameQuit), role: .destructive) { dismiss() }
            } message: {
                Text(AL.s(.gameQuitMessage))
            }

            // Progress line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Colors.line)
                    Capsule().fill(DS.Colors.ink)
                        .frame(width: geo.size.width * min(1, CGFloat(vm.progress)))
                        .animation(.easeOut(duration: 0.35), value: vm.progress)
                }
            }
            .frame(height: 4)

            Text("\(vm.currentIndex + 1)/\(vm.questions.count)")
                .font(DS.Font.ui(13, weight: .medium).monospacedDigit())
                .foregroundStyle(DS.Colors.muted)
                .accessibilityLabel(String(format: AL.s(.gameQuestionFormat), vm.currentIndex + 1, vm.questions.count))

            // Kalan günlük soru sayısı
            if !DailyLimitManager.shared.isPremium {
                let remaining = DailyLimitManager.shared.questionsRemaining
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("\(remaining)")
                        .font(DS.Font.ui(13, weight: .semibold).monospacedDigit())
                }
                .foregroundStyle(remaining <= 5 ? DS.Colors.danger : DS.Colors.muted)
            } else {
                Image(systemName: "infinity")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.slate)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Word Card
    private func wordCard(_ question: GameQuestion) -> some View {
        let targetLangCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        // AI fillInTheBlank → tıklanabilir kelimeler; diğer tüm modlar düz metin
        let isAIFill: Bool = {
            if case .aiGenerated = sessionType { return question.mode == .fillInTheBlank }
            return false
        }()
        let eyebrow: String = {
            if case .aiGenerated = sessionType { return title }
            // For nativeToTarget, show the target-lang label so user knows what to find
            if question.questionDirection == .nativeToTarget {
                return AL.f(.gameWordQuestionFormat, languageDisplayName(targetLangCode))
            }
            return languageDisplayName(targetLangCode)
        }()

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Eyebrow(text: eyebrow)
                Spacer(minLength: 12)
                hintButton(for: question)
            }

            if isAIFill {
                let tgtCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en"
                QuizAITappableWords(
                    sentence: question.promptText,
                    targetLangCode: tgtCode,
                    nativeLangCode: OL.nativeLangCode
                )
            } else {
                QuizPromptText(text: question.promptText)
            }

            // Phonetic only makes sense when showing the target-language word
            if question.questionDirection == .targetToNative,
               let phonetic = question.word.pronunciation {
                Text(phonetic)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(DS.Colors.muted)
            }
        }
        .quizCardSurface()
        .padding(.horizontal, 24)
    }

    // MARK: - Hint Button
    @ViewBuilder
    private func hintButton(for question: GameQuestion) -> some View {
        if HintManager.shared.canUseHint {
            Button {
                triggerHint(for: question)
            } label: {
                QuizCircleIcon {
                    if isLoadingHint {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(DS.Colors.inkSoft)
                    } else {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isLoadingHint)
        } else {
            // Out of hints – greyed out
            QuizCircleIcon {
                Image(systemName: "lightbulb.slash")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
            }
            .opacity(0.6)
        }
    }

    private func triggerHint(for question: GameQuestion) {
        guard HintManager.shared.canUseHint, !isLoadingHint else { return }
        HintManager.shared.useHint()
        isLoadingHint = true
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        Task {
            hintText = await HintManager.shared.fetchHint(
                term: question.word.term,
                targetLangCode: targetLang,
                options: question.options,
                correctAnswer: question.correctAnswer,
                example: question.sentence?.targetText ?? question.word.exampleSentence
            )
            isLoadingHint = false
            showHintSheet = true
        }
    }

    /// Dil adı kullanıcının ana dilinde ("İspanyolca", "Spanish"…)
    private func languageDisplayName(_ code: String) -> String {
        let name = Locale(identifier: OL.nativeLangCode).localizedString(forLanguageCode: code.lowercased()) ?? code
        return name.prefix(1).uppercased(with: Locale(identifier: OL.nativeLangCode)) + name.dropFirst()
    }

    // MARK: - Multiple Choice Grid
    private func multipleChoiceGrid(_ question: GameQuestion) -> some View {
        let answered = isAnswered
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(question.options, id: \.self) { option in
                QuizOptionChip(
                    text: option,
                    status: quizOptionStatus(option, correct: question.correctAnswer,
                                             answered: answered, selected: pendingAnswer,
                                             submitted: submittedAnswer)
                ) {
                    if !answered {
                        withAnimation(.easeOut(duration: 0.15)) { pendingAnswer = option }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Writing Field
    private var writingField: some View {
        let isEmpty = vm.writingAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(spacing: 12) {
            TextField(AL.s(.gameTypeTranslation), text: $vm.writingAnswer)
                .font(DS.Font.ui(17, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .tint(DS.Colors.accent)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.button).stroke(DS.Colors.line, lineWidth: 1))
            Button(AL.s(.gameCheck)) { vm.submitWriting() }
                .buttonStyle(InkButtonStyle(fill: isEmpty ? DS.Colors.line : DS.Colors.ink,
                                            foreground: isEmpty ? DS.Colors.muted : DS.Colors.paperRaised))
                .disabled(isEmpty)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Feedback Overlay
    private func feedbackOverlay(isCorrect: Bool) -> some View {
        QuizFeedbackPanel(
            isCorrect: isCorrect,
            correctAnswer: vm.currentQuestion?.correctAnswer ?? "",
            onContinue: { vm.nextQuestion() }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeOut(duration: 0.25), value: isCorrect)
    }
}

// MARK: - Layout helpers

private extension View {
    /// iPad'de okunabilir sütun genişliği
    func quizReadableWidth() -> some View {
        frame(maxWidth: 620).frame(maxWidth: .infinity)
    }

    /// Soru kartı yüzeyi: kâğıt, ince çizgi, gölgesiz
    func quizCardSurface() -> some View {
        padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(DS.Colors.line, lineWidth: 1))
    }
}

/// 40pt yuvarlak, 1pt çizgili ikon kabı (hoparlör, ipucu)
private struct QuizCircleIcon<Content: View>: View {
    var size: CGFloat = 40
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(width: size, height: size)
            .background(DS.Colors.paperRaised, in: Circle())
            .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            .contentShape(Circle())
    }
}

/// Kahraman metin: tek kelime büyük serif, cümle orta boy serif
private struct QuizPromptText: View {
    let text: String

    private var isShort: Bool {
        !text.trimmingCharacters(in: .whitespaces).contains(" ") || text.count <= 18
    }

    var body: some View {
        if isShort {
            Text(text)
                .font(DS.Font.display(44, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(DS.Font.display(26, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Option Chip

private enum QuizOptionStatus { case idle, selected, correct, wrong, dimmed }

private func quizOptionStatus(_ option: String, correct: String, answered: Bool,
                              selected: String?, submitted: String?) -> QuizOptionStatus {
    if answered {
        if option == correct { return .correct }
        if let submitted, option == submitted { return .wrong }
        return .dimmed
    }
    if let selected, option == selected { return .selected }
    return .idle
}

private struct QuizOptionChip: View {
    let text: String
    let status: QuizOptionStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(DS.Font.ui(17, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(fill, in: RoundedRectangle(cornerRadius: DS.Radius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.button)
                        .strokeBorder(border, lineWidth: borderWidth)
                )
                .opacity(status == .dimmed ? 0.5 : 1)
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.button))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: status)
    }

    private var fill: Color {
        switch status {
        case .correct: return DS.Colors.successSoft
        case .wrong:   return DS.Colors.dangerSoft
        default:       return DS.Colors.paperRaised
        }
    }
    private var border: Color {
        switch status {
        case .selected: return DS.Colors.ink
        case .correct:  return DS.Colors.success
        case .wrong:    return DS.Colors.danger
        default:        return DS.Colors.line
        }
    }
    private var borderWidth: CGFloat {
        switch status {
        case .idle, .dimmed: return 1
        default:             return 1.5
        }
    }
}

// MARK: - Feedback Panel
private struct QuizFeedbackPanel: View {
    let isCorrect: Bool
    let correctAnswer: String
    let onContinue: () -> Void

    @EnvironmentObject var langManager: LanguageManager

    private var titleText: String {
        let lang = langManager.currentLanguageCode
        if isCorrect {
            switch lang {
            case "tr": return ["Mükemmel!", "Harika!", "Bravo!", "Süper!"].randomElement()!
            case "de": return ["Ausgezeichnet!", "Super!", "Toll gemacht!", "Wunderbar!"].randomElement()!
            case "fr": return ["Excellent !", "Parfait !", "Bravo !", "Super !"].randomElement()!
            case "es": return ["¡Excelente!", "¡Perfecto!", "¡Muy bien!", "¡Increíble!"].randomElement()!
            case "it": return ["Eccellente!", "Perfetto!", "Bravo!", "Magnifico!"].randomElement()!
            case "ru": return ["Отлично!", "Прекрасно!", "Молодец!", "Супер!"].randomElement()!
            default:   return ["Well done!", "Excellent!", "Perfect!", "Amazing!"].randomElement()!
            }
        } else {
            return langManager.s(.gameNotQuite)
        }
    }

    private var subtitleText: String {
        guard !isCorrect else { return "" }
        switch langManager.currentLanguageCode {
        case "tr": return "Doğru cevap:"
        case "de": return "Richtige Antwort:"
        case "fr": return "Bonne réponse :"
        case "es": return "Respuesta correcta:"
        case "it": return "Risposta corretta:"
        case "ru": return "Правильный ответ:"
        default:   return "Correct answer:"
        }
    }

    private var continueText: String {
        langManager.s(.gameContinue)
    }

    private var tint: Color { isCorrect ? DS.Colors.success : DS.Colors.danger }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(tint.opacity(0.35)).frame(height: 1)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: isCorrect ? "checkmark" : "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(tint)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(tint.opacity(0.5), lineWidth: 1))
                    Text(titleText)
                        .font(DS.Font.display(24, weight: .bold))
                        .foregroundStyle(tint)
                    Spacer(minLength: 0)
                }

                if !isCorrect && !correctAnswer.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subtitleText)
                            .font(DS.Font.ui(14, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                        Text(correctAnswer)
                            .font(DS.Font.display(20, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button(continueText, action: onContinue)
                    .buttonStyle(InkButtonStyle(fill: tint))
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background((isCorrect ? DS.Colors.successSoft : DS.Colors.dangerSoft).ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Listening Card (auto-plays with loading state)
private struct QuizListeningCard: View {
    let term: String
    let langCode: String
    let languageName: String

    @State private var isLoading: Bool

    init(term: String, langCode: String, languageName: String) {
        self.term    = term
        self.langCode = langCode
        self.languageName = languageName
        // If audio is already cached (prefetched), start in ready state
        _isLoading = State(initialValue: !TTSManager.shared.isCached(term, langCode: langCode))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Eyebrow(text: languageName)

            HStack(alignment: .center, spacing: 18) {
                Button {
                    TTSManager.shared.speak(term, langCode: langCode)
                } label: {
                    ZStack {
                        Circle().fill(isLoading ? DS.Colors.paperSunken : DS.Colors.ink)
                            .frame(width: 76, height: 76)
                        if isLoading {
                            ProgressView().tint(DS.Colors.inkSoft)
                        } else {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(DS.Colors.paperRaised)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Text(AL.s(.gameListenPrompt))
                    .font(DS.Font.display(24, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                // Play button — disabled while audio is loading
                Button {
                    TTSManager.shared.speak(term, langCode: langCode)
                } label: {
                    Group {
                        if isLoading {
                            Text(AL.s(.gameLoadingAudio))
                        } else {
                            Label(AL.s(.gameListenNormal), systemImage: "play.fill")
                        }
                    }
                    .font(DS.Font.ui(14, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .overlay(Capsule().stroke(DS.Colors.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Button {
                    TTSManager.shared.speakSlow(term, langCode: langCode)
                } label: {
                    Label(AL.s(.gameListenSlow), systemImage: "tortoise")
                        .font(DS.Font.ui(14, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .overlay(Capsule().stroke(DS.Colors.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .opacity(isLoading ? 0.6 : 1)
        }
        .quizCardSurface()
        .padding(.horizontal, 24)
        .task {
            // Auto-play; if cached this returns instantly, otherwise waits for fetch
            await TTSManager.shared.speakAsync(term, langCode: langCode)
            isLoading = false
        }
    }
}

// MARK: - XP Note
private struct QuizXPNote: View {
    let amount: Int

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("+\(amount) XP")
                    .font(DS.Font.ui(13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(DS.Colors.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DS.Colors.paperRaised, in: Capsule())
                    .overlay(Capsule().stroke(DS.Colors.line, lineWidth: 1))
            }
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}

// MARK: - Hint Sheet
private struct QuizHintSheet: View {
    let hintText: String
    let hintsRemaining: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    QuizCircleIcon {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                    Text(AL.s(.gameHintTitle))
                        .font(DS.Font.display(26, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                }
                .padding(.top, 28)

                PaperCard {
                    Text(hintText)
                        .font(DS.Font.ui(17))
                        .foregroundStyle(DS.Colors.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Remaining hints counter
                Text(AL.f(.gameHintRemainingFormat, hintsRemaining))
                    .font(DS.Font.ui(14))
                    .foregroundStyle(DS.Colors.muted)

                Button(AL.s(.gameHintGotIt)) { dismiss() }
                    .buttonStyle(InkButtonStyle())
                    .padding(.top, 4)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .paperBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Speaking Mic Button
private struct QuizSpeakingMicButton: View {
    let langCode: String
    let questionIndex: Int          // yeni soru gelince metni sıfırlamak için
    let onResult: (String) -> Void
    let onMute: () -> Void          // 15 dk sesli soru kapatma

    @ObservedObject private var srm = SpeechRecognitionManager.shared
    @State private var permissionDenied = false
    @State private var showMuteAlert = false

    var body: some View {
        VStack(spacing: 14) {
            // Mic button
            Button {
                handleMicTap()
            } label: {
                ZStack {
                    Circle()
                        .fill(srm.isRecording ? DS.Colors.danger : DS.Colors.ink)
                        .frame(width: 76, height: 76)
                    Image(systemName: srm.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(DS.Colors.paperRaised)
                }
            }
            .buttonStyle(.plain)
            .animation(.easeOut(duration: 0.2), value: srm.isRecording)

            // Status / recognized text
            if srm.isRecording {
                Text(AL.s(.gameSpeakListening))
                    .font(DS.Font.ui(14, weight: .medium))
                    .foregroundStyle(DS.Colors.danger)
            } else if srm.isProcessing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8).tint(DS.Colors.inkSoft)
                    Text(AL.s(.quizAnalyzing))
                        .font(DS.Font.ui(14))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
            } else if !srm.recognizedText.isEmpty {
                Text(srm.recognizedText)
                    .font(DS.Font.display(20, weight: .medium))
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.button).stroke(DS.Colors.line, lineWidth: 1))
            } else if permissionDenied {
                Text(AL.s(.gameSpeakNoPermission))
                    .font(DS.Font.ui(14))
                    .foregroundStyle(DS.Colors.danger)
                    .multilineTextAlignment(.center)
            } else {
                Text(AL.s(.gameSpeakMicHint))
                    .font(DS.Font.ui(14))
                    .foregroundStyle(DS.Colors.muted)
                    .multilineTextAlignment(.center)
            }

            // Check button: show after Whisper returns recognized text
            if !srm.recognizedText.isEmpty && !srm.isProcessing {
                Button(AL.s(.gameCheck)) {
                    onResult(srm.recognizedText)
                }
                .buttonStyle(InkButtonStyle())
            }

            // "Microphone Unavailable" button → mute speaking questions for 15 min
            Button {
                showMuteAlert = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 12))
                    Text(AL.s(.gameSpeakCantSpeak))
                        .font(DS.Font.ui(13, weight: .medium))
                }
                .foregroundStyle(DS.Colors.muted)
            }
            .alert(AL.s(.hcMuteTitle), isPresented: $showMuteAlert) {
                Button(AL.s(.hcMuteConfirm)) {
                    onMute()
                }
                Button(AL.s(.hcCancel), role: .cancel) {}
            } message: {
                Text(AL.s(.hcMuteMessage))
            }
        }
        // Yeni soru gelince önceki tanınan metni sıfırla
        .onChange(of: questionIndex) { _ in
            srm.recognizedText = ""
        }
        // Auto-submit kaldırıldı: kullanıcı metni görür, isterse tekrar kaydeder
        // veya "Kontrol Et" butonuna basar.
    }

    private func handleMicTap() {
        if srm.isRecording {
            srm.stopRecording()
            // Do NOT call onResult here — Whisper processes async.
            // The Check button appears automatically when recognizedText is populated.
            return
        }

        switch srm.micPermission {
        case .undetermined:
            srm.requestMicPermission()
        case .granted:
            // Kayıt başlamadan önce TTS'i tamamen durdur
            TTSManager.shared.stop()
            try? srm.startRecording(langCode: langCode)
        default:
            permissionDenied = true
        }
    }
}

// MARK: - Daily Limit Overlay
private struct QuizDailyLimitOverlay: View {
    let onPaywall: () -> Void
    let onQuit: () -> Void

    @State private var countdown: String = DailyLimitManager.shared.countdownString
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            DS.Colors.ink.opacity(0.35).ignoresSafeArea()

            PaperCard(padding: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: AL.s(.dailyLimitResetsIn), color: DS.Colors.muted)
                    Text(countdown)
                        .font(DS.Font.display(40, weight: .bold).monospacedDigit())
                        .foregroundStyle(DS.Colors.ink)
                        .padding(.top, 6)

                    Rectangle().fill(DS.Colors.line).frame(height: 1)
                        .padding(.vertical, 18)

                    Text(AL.s(.dailyLimitTitle))
                        .font(DS.Font.display(26, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AL.s(.dailyLimitSubtitle))
                        .font(DS.Font.ui(16))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    VStack(spacing: 10) {
                        // Pro → Paywall
                        Button(action: onPaywall) {
                            Label(AL.s(.dailyLimitGetPro), systemImage: "crown")
                        }
                        .buttonStyle(InkButtonStyle(fill: DS.Colors.slate))

                        // Kapat
                        Button(AL.s(.dailyLimitClose), action: onQuit)
                            .buttonStyle(OutlineButtonStyle())
                    }
                    .padding(.top, 22)
                }
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 24)
        }
        .onReceive(timer) { _ in
            countdown = DailyLimitManager.shared.countdownString
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Sentence Builder Content (chip builder)
// MARK: ═══════════════════════════════════════════════════════════

private struct QuizSentenceBuilderContent: View {
    let question: GameQuestion
    let isAnswered: Bool
    let targetLang: String
    let onSubmit: (String) -> Void

    @State private var selectedChip: String? = nil
    @State private var tooltipWordIndex: Int? = nil

    /// The sentence to display. DB sentence takes priority over word's example sentence.
    private var sentence: String {
        question.sentence?.targetText
            ?? question.word.exampleSentence
            ?? question.word.description
            ?? question.word.term
    }

    /// The key word highlighted inside the sentence.
    private var sentenceKeyWord: String {
        question.sentence?.keyWord ?? question.word.term
    }

    /// Native meaning of the KEY word — shown as tooltip when that word is tapped.
    private var keyMeaning: String {
        question.sentence?.keyWordNative
            ?? question.word.displayTranslation(phoneCode: OL.nativeLangCode)
    }

    /// Chips available in the bank (hide the currently selected one).
    private var availableChips: [String] {
        question.sentenceWords.filter { $0 != selectedChip }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Instruction ───────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: AL.s(.quizWordInContextEyebrow), color: DS.Colors.slate)
                Text(AL.f(.quizWordInContext, sentenceKeyWord))
                    .font(DS.Font.display(26, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)

            // ── Sentence card ──────────────────────────────────────
            HStack(alignment: .top, spacing: 12) {
                QuizSentenceTappableWords(
                    sentence: sentence,
                    keyWord: sentenceKeyWord,
                    keyMeaning: keyMeaning,
                    tooltipIndex: $tooltipWordIndex,
                    targetLang: targetLang
                )
                Spacer(minLength: 0)
                Button {
                    TTSManager.shared.speak(sentence, langCode: targetLang)
                } label: {
                    QuizCircleIcon {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.ink)
                    }
                }
                .buttonStyle(.plain)
            }
            .quizCardSurface()
            .padding(.horizontal, 24)

            // ── Answer zone ───────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                if let chip = selectedChip {
                    QuizSentenceChip(word: chip, style: .selected)
                        .onTapGesture {
                            guard !isAnswered else { return }
                            withAnimation(.easeOut(duration: 0.2)) { selectedChip = nil }
                        }
                } else {
                    Capsule()
                        .fill(DS.Colors.line)
                        .frame(width: 64, height: 3)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .strokeBorder(
                        selectedChip != nil ? DS.Colors.inkSoft.opacity(0.5) : DS.Colors.line,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .animation(.easeOut(duration: 0.2), value: selectedChip)

            Spacer(minLength: 16)
            Rectangle().fill(DS.Colors.line).frame(height: 1).padding(.horizontal, 24)
            Spacer(minLength: 16)

            // ── Word bank ──────────────────────────────────────────
            // id: \.offset — aynı kelime (the, a, is…) birden fazla geçerse crash olmaz
            OBFlowLayout(spacing: 10) {
                ForEach(Array(availableChips.enumerated()), id: \.offset) { _, chip in
                    QuizSentenceChip(word: chip, style: .bank)
                        .opacity(isAnswered ? 0.5 : 1.0)
                        .onTapGesture {
                            guard !isAnswered else { return }
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedChip = chip
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .animation(.easeOut(duration: 0.2), value: availableChips.count)

            Spacer(minLength: 20)

            // ── Check button ───────────────────────────────────────
            if let answer = selectedChip, !isAnswered {
                Button(AL.s(.gameCheck)) { onSubmit(answer) }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.opacity)
            } else {
                Spacer(minLength: 78)
            }
        }
        .animation(.easeOut(duration: 0.2), value: selectedChip)
    }
}

// MARK: - AI Tappable Sentence Words (on-the-fly OpenAI translation + TTS)

/// AI tarafından üretilen cümlelerdeki kelimelere tıklanınca
/// OpenAI üzerinden çeviri alır ve TTS ile seslendiriri.
private struct QuizAITappableWords: View {
    let sentence: String
    let targetLangCode: String      // hedef dil kodu, ör. "en"
    let nativeLangCode: String      // ana dil kodu, ör. "tr"

    /// word (lowercase, punctuation stripped) → translation
    @State private var translations: [String: String] = [:]
    /// Şu an çevirisi yüklenen kelime
    @State private var loadingWord: String? = nil
    /// Tooltip gösterilen kelime (index üzerinden değil, clean key üzerinden)
    @State private var activeWord: String? = nil

    private var tokens: [String] {
        sentence.components(separatedBy: " ").filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            OBFlowLayout(spacing: 6) {
                ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                    let isGap = token == "___"
                    let clean = token
                        .trimmingCharacters(in: .punctuationCharacters)
                        .lowercased()
                    let isActive  = activeWord == clean

                    if isGap {
                        // boşluk — dokunulamaz
                        Text("______")
                            .font(DS.Font.display(24, weight: .semibold))
                            .foregroundStyle(DS.Colors.accent)
                    } else {
                        Text(token)
                            .font(DS.Font.display(24, weight: .medium))
                            .foregroundStyle(isActive ? DS.Colors.accent : DS.Colors.ink)
                            .padding(.horizontal, 2)
                            .background(
                                isActive ? DS.Colors.accentSoft : Color.clear,
                                in: RoundedRectangle(cornerRadius: 5)
                            )
                            // Her kelime daima altı çizili — kullanıcı tıklanabilir olduğunu anlar
                            .underline(true, color: isActive ? DS.Colors.accent : DS.Colors.line)
                            .onTapGesture {
                                handleTap(token: token, clean: clean)
                            }
                    }
                }
            }

            // Tooltip strip
            if let key = activeWord {
                HStack(spacing: 8) {
                    Text(key)
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)

                    Text("—")
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.muted)

                    if let meaning = translations[key] {
                        Text(meaning)
                            .font(DS.Font.ui(15))
                            .foregroundStyle(DS.Colors.ink)
                    } else {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(DS.Colors.inkSoft)
                    }

                    Spacer()

                    Button {
                        TTSManager.shared.speak(key, langCode: targetLangCode)
                    } label: {
                        Image(systemName: "speaker.wave.1")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 10))
                .transition(.opacity)
            }
        }
        .task { await preTranslateAll() }
    }

    /// Ekran açıldığında tüm kelimeleri paralel olarak çevirir — tıklamada anında gelir.
    private func preTranslateAll() async {
        let code  = targetLangCode
        let nCode = nativeLangCode
        let uniqueCleans = Set(
            tokens
                .filter { $0 != "___" }
                .map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        )
        // uniquingKeysWith: aynı kelime cümlede birden fazla geçerse (the, a, is…) crash olmaz
        let rawByClean: [String: String] = Dictionary(
            tokens
                .filter { $0 != "___" }
                .map { ($0.trimmingCharacters(in: .punctuationCharacters).lowercased(),
                        $0.trimmingCharacters(in: .punctuationCharacters)) },
            uniquingKeysWith: { first, _ in first }
        )
        await withTaskGroup(of: (String, String?).self) { group in
            for clean in uniqueCleans {
                guard translations[clean] == nil else { continue }
                let raw = rawByClean[clean] ?? clean
                group.addTask {
                    let t = await OpenAIQuizService.shared.translateWord(
                        raw, targetLangCode: code, nativeLangCode: nCode
                    )
                    return (clean, t)
                }
            }
            for await (clean, translation) in group {
                if let t = translation {
                    translations[clean] = t
                }
            }
        }
    }

    private func handleTap(token: String, clean: String) {
        // TTS — hemen çal
        TTSManager.shared.speak(token.trimmingCharacters(in: .punctuationCharacters),
                                langCode: targetLangCode)

        // Aynı kelimeye tekrar basıldıysa tooltip'i kapat
        if activeWord == clean {
            withAnimation(.easeOut(duration: 0.2)) { activeWord = nil }
            return
        }

        withAnimation(.easeOut(duration: 0.2)) { activeWord = clean }

        // Zaten çevrilmişse tekrar fetch etme
        guard translations[clean] == nil else { return }

        loadingWord = clean
        Task {
            let result = await OpenAIQuizService.shared.translateWord(
                token.trimmingCharacters(in: .punctuationCharacters),
                targetLangCode: targetLangCode,
                nativeLangCode: nativeLangCode
            )
            await MainActor.run {
                loadingWord = nil
                if let result {
                    translations[clean] = result
                } else {
                    translations[clean] = "—"
                }
            }
        }
    }
}

// MARK: - Tappable Sentence Words (flow layout + tooltip)

private struct QuizSentenceTappableWords: View {
    let sentence: String
    let keyWord: String
    let keyMeaning: String
    @Binding var tooltipIndex: Int?
    let targetLang: String

    /// Anahtar kelime cümle içinde (noktalama dahil edilmeden) vurgulanır; her dilde çalışır (boşluksuz ZH/JA dahil).
    /// Anlamı göstermez — cevabı vermemek için.
    private var attributed: AttributedString {
        var a = AttributedString(sentence)
        a.font = DS.Font.display(24, weight: .regular)
        a.foregroundColor = DS.Colors.ink
        var searchStart = a.startIndex
        while let r = a[searchStart...].range(of: keyWord, options: [.caseInsensitive, .diacriticInsensitive]) {
            a[r].foregroundColor = DS.Colors.accent
            a[r].font = DS.Font.display(24, weight: .semibold)
            a[r].underlineStyle = .single
            searchStart = r.upperBound
        }
        return a
    }

    var body: some View {
        Text(attributed)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture { TTSManager.shared.speak(sentence, langCode: targetLang) }
    }
}

// MARK: - Sentence Chip

private struct QuizSentenceChip: View {
    enum Style { case bank, selected }
    let word: String
    let style: Style

    var body: some View {
        Text(word)
            .font(DS.Font.ui(17, weight: .medium))
            .foregroundStyle(DS.Colors.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style == .selected ? DS.Colors.ink : DS.Colors.line,
                                  lineWidth: style == .selected ? 1.5 : 1)
            )
    }
}

// MARK: - Shared pieces for sentence questions
private struct QuizInstruction: View {
    let eyebrow: String?
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow { Eyebrow(text: eyebrow, color: DS.Colors.slate) }
            Text(title)
                .font(DS.Font.display(26, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

private struct QuizSentenceCard: View {
    let text: String
    let langCode: String?
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(text)
                .font(DS.Font.display(24, weight: .regular))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let langCode {
                Button { TTSManager.shared.speak(text, langCode: langCode) } label: {
                    QuizCircleIcon {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.ink)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .quizCardSurface()
        .padding(.horizontal, 24)
        .onAppear { if let langCode { TTSManager.shared.speak(text, langCode: langCode) } }
    }
}

// MARK: - Build Sentence
private struct QuizBuildSentenceContent: View {
    let question: GameQuestion
    let isAnswered: Bool
    let targetLang: String
    let onSubmit: ([String]) -> Void

    /// Seçilen kutucukların bankadaki indeksleri (aynı kelime iki kez olabilir)
    @State private var picked: [Int] = []

    var body: some View {
        VStack(spacing: 0) {
            QuizInstruction(eyebrow: AL.s(.quizBuildSentence), title: question.promptText)

            OBFlowLayout(spacing: 8) {
                ForEach(picked, id: \.self) { idx in
                    QuizSentenceChip(word: question.sentenceWords[idx], style: .selected)
                        .onTapGesture {
                            guard !isAnswered else { return }
                            withAnimation(.easeOut(duration: 0.15)) { picked.removeAll { $0 == idx } }
                        }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .strokeBorder(DS.Colors.line, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            OBFlowLayout(spacing: 10) {
                ForEach(Array(question.sentenceWords.enumerated()), id: \.offset) { idx, word in
                    let used = picked.contains(idx)
                    QuizSentenceChip(word: word, style: .bank)
                        .opacity(used ? 0 : (isAnswered ? 0.5 : 1))
                        .onTapGesture {
                            guard !isAnswered, !used else { return }
                            withAnimation(.easeOut(duration: 0.15)) { picked.append(idx) }
                            TTSManager.shared.speak(word, langCode: targetLang)
                        }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            if !isAnswered {
                Button(AL.s(.gameCheck)) { onSubmit(picked.map { question.sentenceWords[$0] }) }
                    .buttonStyle(InkButtonStyle(fill: picked.isEmpty ? DS.Colors.line : DS.Colors.ink,
                                                foreground: picked.isEmpty ? DS.Colors.muted : DS.Colors.paperRaised))
                    .disabled(picked.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            } else {
                Spacer(minLength: 78)
            }
        }
    }
}

// MARK: - Match Pairs
private struct QuizMatchPairsContent: View {
    let question: GameQuestion
    let isAnswered: Bool
    let targetLang: String
    let onFinish: (Int) -> Void

    @State private var left: [String] = []
    @State private var right: [String] = []
    @State private var selectedLeft: String?
    @State private var selectedRight: String?
    @State private var matched: Set<String> = []      // eşleşen terimler
    @State private var wrongFlash: Set<String> = []
    @State private var mistakes = 0

    private func meaning(of term: String) -> String? { question.pairs.first { $0.term == term }?.meaning }

    var body: some View {
        VStack(spacing: 0) {
            QuizInstruction(eyebrow: nil, title: AL.s(.quizMatchPairs))
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 10) {
                    ForEach(left, id: \.self) { term in
                        tile(term, done: matched.contains(term), selected: selectedLeft == term) {
                            selectedLeft = term
                            TTSManager.shared.speak(term, langCode: targetLang)
                            check()
                        }
                    }
                }
                VStack(spacing: 10) {
                    ForEach(right, id: \.self) { m in
                        let done = matched.contains { meaning(of: $0) == m }
                        tile(m, done: done, selected: selectedRight == m) {
                            selectedRight = m
                            check()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 24)
        }
        .onAppear {
            left = question.pairs.map(\.term).shuffled()
            right = question.pairs.map(\.meaning).shuffled()
        }
    }

    private func tile(_ text: String, done: Bool, selected: Bool, action: @escaping () -> Void) -> some View {
        let wrong = wrongFlash.contains(text)
        return Button(action: action) {
            Text(text)
                .font(DS.Font.ui(16, weight: .medium))
                .foregroundStyle(done ? DS.Colors.muted : DS.Colors.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 8)
                .background(wrong ? DS.Colors.dangerSoft : (done ? DS.Colors.successSoft : DS.Colors.paperRaised),
                            in: RoundedRectangle(cornerRadius: DS.Radius.button))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.button)
                    .strokeBorder(wrong ? DS.Colors.danger : (selected ? DS.Colors.ink : DS.Colors.line),
                                  lineWidth: selected || wrong ? 1.5 : 1))
                .opacity(done ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(done || isAnswered)
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    private func check() {
        guard let l = selectedLeft, let r = selectedRight else { return }
        if meaning(of: l) == r {
            matched.insert(l)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if matched.count == question.pairs.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onFinish(mistakes) }
            }
        } else {
            mistakes += 1
            wrongFlash = [l, r]
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { wrongFlash = [] }
        }
        selectedLeft = nil
        selectedRight = nil
    }
}

/// fullScreenCover(item:) için
private struct TalkLevel: Identifiable { let id: UUID }
