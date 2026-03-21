//
//  GameQuizView.swift
//  WordRemSwiftUI
//
//  Full-screen gamified quiz — daily 25-question limit, progress bar, XP toast.
//  Hearts / lives system removed. Replaced with a daily limit paywall popup.
//

import SwiftUI
import AVFoundation

struct GameQuizView: View {

    let sessionType: QuizSessionType
    let title: String
    var preloadedQuestions: [GameQuestion] = []

    @StateObject private var vm = GameQuizViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var wordsLoaded = false
    @State private var showPaywall = false
    @State private var showHintSheet = false
    @State private var hintText: String = ""
    @State private var isLoadingHint = false
    @State private var pendingAnswer: String? = nil   // seçildi ama henüz kontrol edilmedi
    @State private var showConfetti = false           // doğru cevap konfeti
    @State private var showQuitAlert = false          // çıkış onay uyarısı
    /// Tracks the last question index for which audio was auto-played, preventing
    /// re-triggers when the view re-renders on state transitions (.question → .answered).
    @State private var autoPlayedIndex: Int = -1

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundStart.ignoresSafeArea()
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
                                showConfetti = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showConfetti = false
                                }
                                // Auto-play the correct answer
                                let langCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
                                let textToSpeak = vm.currentQuestion?.correctAnswer ?? ""
                                if !textToSpeak.isEmpty {
                                    TTSManager.shared.speak(textToSpeak, langCode: langCode)
                                }
                            }
                        }
                }
                // Konfeti
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

            case .dailyLimitReached:
                Group {
                    if let q = vm.currentQuestion ?? vm.questions.last {
                        questionView(q).blur(radius: 4)
                    } else {
                        AppTheme.Colors.backgroundStart
                    }
                }
                .overlay(DailyLimitOverlay(onPaywall: { showPaywall = true },
                                           onQuit: { dismiss() }))

            case .completed(let score, let stars, let xp):
                QuizResultView(
                    score: score,
                    stars: stars,
                    xpEarned: xp,
                    levelTitle: title
                ) {
                    dismiss()
                }
            }

            // XP Toast
            if vm.showXPToast {
                XPToastView(amount: vm.xpToast)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.spring(response: 0.4), value: vm.showXPToast)
            }
        }
        .task {
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
                switch sessionType {
                case .level(let lId):
                    words = try await SupabaseDataService.shared.fetchWords(levelId: lId)
                    if let courseId = words.isEmpty ? nil : (try? await SupabaseDataService.shared.fetchCourseId(forLevel: lId)) {
                        sentences = (try? await SupabaseDataService.shared.fetchSentences(courseId: courseId)) ?? []
                    }
                case .mistakes:
                    let ids = MistakesManager.shared.mistakeUUIDs
                    words = try await SupabaseDataService.shared.fetchWords(byIds: ids)
                case .aiGenerated: return   // already handled above
                }
                vm.setup(sessionType: sessionType, words: words, sentences: sentences, levelTitle: title)
            } catch {
                print("❌ Failed to load words: \(error)")
                vm.state = .dailyLimitReached
            }
        }
        .sheet(isPresented: $showPaywall) {
            OnboardingPaywallView {
                showPaywall = false
                // Premium aktivasyonundan sonra quiz'i sıfırla
                if DailyLimitManager.shared.isPremium {
                    vm.setup(sessionType: sessionType,
                             words: vm.questions.compactMap { $0.sentence == nil ? $0.word : nil },
                             sentences: vm.questions.compactMap { $0.sentence },
                             levelTitle: title)
                }
            }
        }
        .sheet(isPresented: $showHintSheet) {
            HintSheetView(hintText: hintText, hintsRemaining: HintManager.shared.hintsRemaining)
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text(AL.s(.gameLoading))
                .font(.custom("Feather-Bold", size: 15))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
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
        default:
            standardQuestionView(question)
        }
    }

    @ViewBuilder
    private func standardQuestionView(_ question: GameQuestion) -> some View {
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        let isMulti = question.mode == .multipleChoice && !question.options.isEmpty
        let answered: Bool = { if case .answered = vm.state { return true }; return false }()

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 24)
            wordCard(question)
            Spacer(minLength: 20)
            Text(question.questionDirection == .targetToNative
                 ? AL.s(.gameWhatIsMeaning)
                 : "What is the \(languageDisplayName(targetLang)) word for this?")
                .font(.custom("Feather-Bold", size: 16))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer(minLength: 20)
            if isMulti {
                multipleChoiceGrid(question)
            } else {
                writingField
            }
            Spacer(minLength: 12)
        }
        // Kontrol Et butonu — multipleChoice için her zaman altta sabit
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isMulti && !answered {
                bottomCheckBar(onCheck: {
                    guard let chosen = pendingAnswer else { return }
                    vm.submitMultipleChoice(selected: chosen)
                    pendingAnswer = nil
                })
            }
        }
    }

    private func bottomCheckBar(onCheck: @escaping () -> Void) -> some View {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let label: String
        switch lang {
        case "tr": label = "Kontrol Et"
        case "de": label = "Überprüfen"
        case "fr": label = "Vérifier"
        case "es": label = "Comprobar"
        case "it": label = "Controlla"
        case "ru": label = "Проверить"
        default:   label = "Check"
        }
        let hasSelection = pendingAnswer != nil
        return VStack(spacing: 0) {
            Divider().opacity(0.15)
            Button(action: onCheck) {
                Text(label)
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        hasSelection
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color(hex: "#cbd5e1")),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .disabled(!hasSelection)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            .animation(.spring(response: 0.3), value: hasSelection)
        }
    }

    // MARK: - Listening View
    @ViewBuilder
    private func listeningView(_ question: GameQuestion) -> some View {
        let answered = { () -> Bool in
            if case .answered = vm.state { return true }
            return false
        }()
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 24)

            // Listening card with built-in loading state and auto-play
            ListeningCardContent(term: question.word.term, langCode: targetLang)

            Spacer(minLength: 24)

            // Options grid (same as multipleChoice, but answer = translation)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    OptionButton(text: option, correctAnswer: question.correctAnswer, isAnswered: answered) {
                        if !answered { vm.submitListening(selected: option) }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 32)
        }
    }

    // MARK: - Speaking View
    @ViewBuilder
    private func speakingView(_ question: GameQuestion) -> some View {
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 24)

            // Word card – shows the target-language word the user needs to say
            VStack(spacing: 10) {
                // 🗣 Say this word label
                Text(AL.s(.gameSpeakPrompt))
                    .font(.custom("Feather-Bold", size: 12))
                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(AppTheme.Colors.primaryOrange.opacity(0.1), in: Capsule())

                // Target word – large & prominent (this is the word to say!)
                Text(question.word.term)
                    .font(.custom("Feather-Bold", size: 42))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                if let phonetic = question.word.phonetic {
                    Text("/\(phonetic)/")
                        .font(.custom("Feather-Bold", size: 15))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                HStack(spacing: 10) {
                    // Language badge
                    Text("🗣 \(languageDisplayName(targetLang))")
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.primaryOrange.opacity(0.1), in: Capsule())

                    // Audio replay
                    Button {
                        TTSManager.shared.speak(question.word.term, langCode: targetLang)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.Colors.primaryOrange)
                            .padding(9)
                            .background(AppTheme.Colors.primaryOrange.opacity(0.12), in: Circle())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: AppTheme.Shadows.cardColor, radius: 16, y: 8)
            )
            .padding(.horizontal, 24)
            .onAppear {
                // Önceki sorunun TTS'ini durdur (doğru cevap seslendirmesi bitmemiş olabilir)
                // Kullanıcı play butonuna basana kadar TTS başlamaz
                TTSManager.shared.stop()
            }

            Spacer(minLength: 20)

            // Mic area
            SpeakingMicButton(
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

            Spacer(minLength: 32)
        }
    }

    // MARK: - Fill in the Blank View
    @ViewBuilder
    private func fillInTheBlankView(_ question: GameQuestion) -> some View {
        let answered = { () -> Bool in
            if case .answered = vm.state { return true }; return false
        }()

        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 24)

            // Gap sentence card + hint button
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Text("Fill in the blank")
                        .font(.custom("Feather-Bold", size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    // Path format: "_____ → Good morning" → show "Translate: Good morning"
                    // AI format: "She ___ to school" → show sentence with gap
                    let parts = question.gapSentence.components(separatedBy: " → ")
                    if parts.count == 2 && question.gapSentence.hasPrefix("_") {
                        // Path word question
                        VStack(spacing: 4) {
                            Text("Translate:")
                                .font(.custom("Feather-Bold", size: 13))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            Text(parts[1])
                                .font(.custom("Feather-Bold", size: 30))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        // AI sentence with gap
                        Text(question.gapSentence)
                            .font(.custom("Feather-Bold", size: 22))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 56)

                // Hint button
                if HintManager.shared.canUseHint {
                    Button { triggerHint(for: question) } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#f59e0b").opacity(0.15))
                                .frame(width: 36, height: 36)
                            if isLoadingHint {
                                ProgressView().scaleEffect(0.7).tint(Color(hex: "#f59e0b"))
                            } else {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(hex: "#f59e0b"))
                            }
                        }
                    }
                    .disabled(isLoadingHint)
                    .padding(12)
                } else {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.inputBorder.opacity(0.4))
                            .frame(width: 36, height: 36)
                        Image(systemName: "lightbulb.slash.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    .padding(12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: AppTheme.Shadows.cardColor, radius: 16, y: 8)
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 24)

            // Word options — seç → Kontrol Et
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(question.sentenceWords, id: \.self) { wordOption in
                        let isSelected = !answered && pendingAnswer == wordOption
                        Button {
                            if !answered {
                                withAnimation(.spring(response: 0.25)) { pendingAnswer = wordOption }
                            }
                        } label: {
                            Text(wordOption)
                                .font(.custom("Feather-Bold", size: 14))
                                .foregroundStyle(
                                    answered
                                        ? (wordOption == question.correctAnswer ? Color.green : Color.red)
                                        : (isSelected ? AppTheme.Colors.primaryOrange : AppTheme.Colors.textPrimary)
                                )
                                .padding(.vertical, 14)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            answered
                                                ? (wordOption == question.correctAnswer ? Color.green.opacity(0.1) : Color.red.opacity(0.08))
                                                : (isSelected ? AppTheme.Colors.primaryOrange.opacity(0.1) : Color.white)
                                        )
                                        .shadow(color: AppTheme.Shadows.cardColor, radius: (answered || isSelected) ? 0 : 6, y: (answered || isSelected) ? 0 : 3)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            answered
                                                ? (wordOption == question.correctAnswer ? Color.green : Color.red)
                                                : (isSelected ? AppTheme.Colors.primaryOrange : AppTheme.Colors.inputBorder),
                                            lineWidth: (answered || isSelected) ? 2 : 1
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(answered)
                        .animation(.spring(response: 0.25), value: isSelected)
                    }
                }
                .padding(.horizontal, 20)

            }
            .onChange(of: vm.currentIndex) { _ in pendingAnswer = nil }

            Spacer(minLength: 12)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !answered {
                bottomCheckBar(onCheck: {
                    guard let chosen = pendingAnswer else { return }
                    vm.submitFillInTheBlank(selected: chosen)
                    pendingAnswer = nil
                })
            }
        }
    }

    // MARK: - Sentence Builder View (Duolingo-style)
    @ViewBuilder
    private func sentenceBuilderView(_ question: GameQuestion) -> some View {
        let answered = { () -> Bool in
            if case .answered = vm.state { return true }; return false
        }()
        let targetLang = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"

        VStack(spacing: 0) {
            quizHeader
            SentenceBuilderContent(
                question: question,
                isAnswered: answered,
                targetLang: targetLang,
                onSubmit: { selected in
                    vm.submitSentenceBuilder(selectedWord: selected)
                }
            )
        }
    }

    // MARK: - Header  (kalpler kaldırıldı → kalan soru sayısı gösteriliyor)
    private var quizHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Quit
                Button { showQuitAlert = true } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(10)
                        .background(AppTheme.Colors.inputBorder.opacity(0.5), in: Circle())
                }
                .alert(AL.s(.gameQuitTitle), isPresented: $showQuitAlert) {
                    Button(AL.s(.gameQuitKeepGoing), role: .cancel) { }
                    Button(AL.s(.gameQuit), role: .destructive) { dismiss() }
                } message: {
                    Text(AL.s(.gameQuitMessage))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.Colors.inputBorder).frame(height: 8)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * CGFloat(vm.progress), height: 8)
                            .animation(.spring(response: 0.5), value: vm.progress)
                    }
                }
                .frame(height: 8)

                // Kalan günlük soru sayısı
                if !DailyLimitManager.shared.isPremium {
                    let remaining = DailyLimitManager.shared.questionsRemaining
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                        Text("\(remaining)")
                            .font(.custom("Feather-Bold", size: 13))
                    }
                    .foregroundStyle(remaining <= 5 ? Color.red : AppTheme.Colors.primaryOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (remaining <= 5 ? Color.red : AppTheme.Colors.primaryOrange).opacity(0.12),
                        in: Capsule()
                    )
                } else {
                    Image(systemName: "infinity")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#8b5cf6"))
                }
            }
            .padding(.horizontal, 20)

            Text(String(format: AL.s(.gameQuestionFormat), vm.currentIndex + 1, vm.totalCount))
                .font(.custom("Feather-Bold", size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Material.ultraThinMaterial)
    }

    // MARK: - Word Card
    private func wordCard(_ question: GameQuestion) -> some View {
        let targetLangCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN"
        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                // For nativeToTarget, also show a small target-lang label so user knows what to find
                if question.questionDirection == .nativeToTarget {
                    Text(languageDisplayName(targetLangCode) + " word?")
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(AppTheme.Colors.primaryOrange.opacity(0.1), in: Capsule())
                }

                Text(question.promptText)
                    .font(.custom("Feather-Bold", size: 32))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                // Phonetic only makes sense when showing the target-language word
                if question.questionDirection == .targetToNative,
                   let phonetic = question.word.phonetic {
                    Text("/\(phonetic)/")
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 56)  // extra padding for hint button space

            // Hint button top-right
            if HintManager.shared.canUseHint {
                Button {
                    triggerHint(for: question)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#f59e0b").opacity(0.15))
                            .frame(width: 36, height: 36)
                        if isLoadingHint {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(Color(hex: "#f59e0b"))
                        } else {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "#f59e0b"))
                        }
                    }
                }
                .disabled(isLoadingHint)
                .padding(12)
            } else {
                // Out of hints – greyed out
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.inputBorder.opacity(0.4))
                        .frame(width: 36, height: 36)
                    Image(systemName: "lightbulb.slash.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppTheme.Shadows.cardColor, radius: 16, y: 8)
        )
        .padding(.horizontal, 24)
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
                correctAnswer: question.correctAnswer
            )
            isLoadingHint = false
            showHintSheet = true
        }
    }

    private func languageDisplayName(_ code: String) -> String {
        switch code.uppercased() {
        case "EN": return "English"
        case "FR": return "French"
        case "DE": return "German"
        case "ES": return "Spanish"
        case "IT": return "Italian"
        case "RU": return "Russian"
        case "ZH": return "Chinese"
        case "TR": return "Turkish"
        case "JA": return "Japanese"
        case "KO": return "Korean"
        case "PT": return "Portuguese"
        default:   return code
        }
    }

    // MARK: - Multiple Choice Grid
    private func multipleChoiceGrid(_ question: GameQuestion) -> some View {
        let answered = { () -> Bool in
            if case .answered = vm.state { return true }
            return false
        }()
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(question.options, id: \.self) { option in
                OptionButton(
                    text: option,
                    correctAnswer: question.correctAnswer,
                    isAnswered: answered,
                    isSelected: !answered && pendingAnswer == option
                ) {
                    if !answered {
                        withAnimation(.spring(response: 0.25)) { pendingAnswer = option }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .onChange(of: vm.currentIndex) { _ in pendingAnswer = nil }
    }

    // MARK: - Writing Field
    private var writingField: some View {
        VStack(spacing: 12) {
            TextField(AL.s(.gameTypeTranslation), text: $vm.writingAnswer)
                .font(.custom("Feather-Bold", size: 16))
                .padding()
                .background(AppTheme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.inputBorder))
                .padding(.horizontal, 24)
            Button { vm.submitWriting() } label: {
                Text(AL.s(.gameCheck))
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .padding(.horizontal, 24)
            .disabled(vm.writingAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Feedback Overlay
    private func feedbackOverlay(isCorrect: Bool) -> some View {
        VStack {
            Spacer()
            FeedbackPanel(
                isCorrect: isCorrect,
                correctAnswer: vm.currentQuestion?.correctAnswer ?? "",
                onContinue: { vm.nextQuestion() }
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isCorrect)
    }
}

// MARK: - Feedback Panel
private struct FeedbackPanel: View {
    let isCorrect: Bool
    let correctAnswer: String
    let onContinue: () -> Void

    // Telefon diline göre tebrik / üzgün mesajları
    private var titleText: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        if isCorrect {
            switch lang {
            case "tr": return ["Mükemmel! 🎉", "Harika! ✨", "Bravo! 🔥", "Süper! 🌟"].randomElement()!
            case "de": return ["Ausgezeichnet! 🎉", "Super! ✨", "Toll gemacht! 🔥", "Wunderbar! 🌟"].randomElement()!
            case "fr": return ["Excellent ! 🎉", "Parfait ! ✨", "Bravo ! 🔥", "Super ! 🌟"].randomElement()!
            case "es": return ["¡Excelente! 🎉", "¡Perfecto! ✨", "¡Muy bien! 🔥", "¡Increíble! 🌟"].randomElement()!
            case "it": return ["Eccellente! 🎉", "Perfetto! ✨", "Bravo! 🔥", "Magnifico! 🌟"].randomElement()!
            case "ru": return ["Отлично! 🎉", "Прекрасно! ✨", "Молодец! 🔥", "Супер! 🌟"].randomElement()!
            default:   return ["Well done! 🎉", "Excellent! ✨", "Perfect! 🔥", "Amazing! 🌟"].randomElement()!
            }
        } else {
            switch lang {
            case "tr": return "Neredeyse! 💪"
            case "de": return "Fast richtig! 💪"
            case "fr": return "Presque ! 💪"
            case "es": return "¡Casi! 💪"
            case "it": return "Quasi! 💪"
            case "ru": return "Почти! 💪"
            default:   return "Not quite! 💪"
            }
        }
    }

    private var subtitleText: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        if isCorrect { return "" }
        switch lang {
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
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        switch lang {
        case "tr": return "Devam Et"
        case "de": return "Weiter"
        case "fr": return "Continuer"
        case "es": return "Continuar"
        case "it": return "Continua"
        case "ru": return "Продолжить"
        default:   return "Continue"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top accent bar
            Rectangle()
                .fill(isCorrect ? Color.green : Color(hex: "#ef4444"))
                .frame(height: 3)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isCorrect ? Color.green.opacity(0.15) : Color(hex: "#ef4444").opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(isCorrect ? Color.green : Color(hex: "#ef4444"))
                    }

                    Text(titleText)
                        .font(.custom("Feather-Bold", size: 18))
                        .foregroundStyle(isCorrect ? Color.green : Color(hex: "#ef4444"))

                    Spacer()
                }

                // Continue button
                Button(action: onContinue) {
                    Text(continueText)
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isCorrect
                                ? AnyShapeStyle(Color.green)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                    startPoint: .leading, endPoint: .trailing
                                )),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                isCorrect ? Color.green.opacity(0.06) : Color(hex: "#ef4444").opacity(0.06)
            )
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 16, y: -4)
    }
}

// MARK: - Listening Card Content (auto-plays with loading state)
private struct ListeningCardContent: View {
    let term: String
    let langCode: String

    @State private var isLoading: Bool

    init(term: String, langCode: String) {
        self.term    = term
        self.langCode = langCode
        // If audio is already cached (prefetched), start in ready state
        _isLoading = State(initialValue: !TTSManager.shared.isCached(term, langCode: langCode))
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.4), radius: 16, y: 8)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(AL.s(.gameListenPrompt))
                .font(.custom("Feather-Bold", size: 16))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 12) {
                // Play button — disabled while audio is loading
                Button {
                    TTSManager.shared.speak(term, langCode: langCode)
                } label: {
                    Group {
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white).scaleEffect(0.8)
                                Text("Yükleniyor...").font(.custom("Feather-Bold", size: 14))
                            }
                        } else {
                            Label(AL.s(.gameListenNormal), systemImage: "play.fill")
                                .font(.custom("Feather-Bold", size: 14))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: isLoading
                                ? [Color.gray.opacity(0.5), Color.gray.opacity(0.6)]
                                : [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                }
                .disabled(isLoading)

                Button {
                    TTSManager.shared.speakSlow(term, langCode: langCode)
                } label: {
                    Label(AL.s(.gameListenSlow), systemImage: "tortoise.fill")
                        .font(.custom("Feather-Bold", size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.inputBorder.opacity(0.4), in: Capsule())
                }
                .disabled(isLoading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppTheme.Shadows.cardColor, radius: 16, y: 8)
        )
        .padding(.horizontal, 24)
        .task {
            // Auto-play; if cached this returns instantly, otherwise waits for fetch
            await TTSManager.shared.speakAsync(term, langCode: langCode)
            isLoading = false
        }
    }
}

// MARK: - Option Button
private struct OptionButton: View {
    let text: String
    let correctAnswer: String
    let isAnswered: Bool
    var isSelected: Bool = false   // seçildi ama henüz kontrol edilmedi
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("Feather-Bold", size: 14))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(bgColor)
                        .shadow(color: AppTheme.Shadows.cardColor,
                                radius: (isAnswered || isSelected) ? 0 : 6,
                                y: (isAnswered || isSelected) ? 0 : 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: (isAnswered || isSelected) ? 2 : 1)
                )
                .scaleEffect(isSelected && !isAnswered ? 1.03 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.25), value: isSelected)
        .animation(.spring(response: 0.3), value: isAnswered)
    }

    private var isCorrect: Bool { text == correctAnswer }

    private var textColor: Color {
        if isAnswered { return isCorrect ? Color.green : Color.red }
        if isSelected { return AppTheme.Colors.primaryOrange }
        return AppTheme.Colors.textPrimary
    }
    private var bgColor: Color {
        if isAnswered { return isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.08) }
        if isSelected { return AppTheme.Colors.primaryOrange.opacity(0.1) }
        return Color.white
    }
    private var borderColor: Color {
        if isAnswered { return isCorrect ? Color.green : Color.red }
        if isSelected { return AppTheme.Colors.primaryOrange }
        return AppTheme.Colors.inputBorder
    }
}

// MARK: - XP Toast
private struct XPToastView: View {
    let amount: Int
    @State private var scale: CGFloat = 0.5
    @State private var offsetY: CGFloat = 20

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#f59e0b"), Color(hex: "#f97316")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("+\(amount) XP")
                    .font(.custom("Feather-Bold", size: 17))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#f97316"), Color(hex: "#f59e0b")],
                    startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .shadow(color: Color(hex: "#f97316").opacity(0.45), radius: 12, y: 6)
            .scaleEffect(scale)
            .offset(y: offsetY)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0; offsetY = 0
                }
            }
            Spacer()
        }
        .padding(.top, 110)
    }
}

// MARK: - Confetti View
private struct ConfettiView: View {
    let particles: [ConfettiParticle] = (0..<26).map { _ in ConfettiParticle() }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                ConfettiPiece(particle: p)
            }
        }
        .ignoresSafeArea()
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat      = CGFloat.random(in: 0.1...0.9)
    let color: Color    = [Color(hex: "#f97316"), Color(hex: "#6366f1"), Color(hex: "#10b981"),
                           Color(hex: "#f59e0b"), Color(hex: "#ec4899"), Color(hex: "#3b82f6")].randomElement()!
    let size: CGFloat   = CGFloat.random(in: 7...14)
    let isCircle: Bool  = Bool.random()
    let delay: Double   = Double.random(in: 0...0.3)
    let endY: CGFloat   = CGFloat.random(in: 0.4...0.85)
    let rotation: Double = Double.random(in: 0...360)
}

private struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var animating = false

    var body: some View {
        GeometryReader { geo in
            Group {
                if particle.isCircle {
                    Circle().fill(particle.color).frame(width: particle.size, height: particle.size)
                } else {
                    Rectangle().fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 0.5)
                        .rotationEffect(.degrees(particle.rotation + (animating ? 360 : 0)))
                }
            }
            .position(
                x: geo.size.width * particle.x,
                y: animating ? geo.size.height * particle.endY : geo.size.height * 0.15
            )
            .opacity(animating ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.0).delay(particle.delay)
                ) { animating = true }
            }
        }
    }
}

// MARK: - Hint Sheet
private struct HintSheetView: View {
    let hintText: String
    let hintsRemaining: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#f59e0b").opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(hex: "#f59e0b"))
                    }
                    .padding(.top, 16)

                    Text("İpucu")
                        .font(.custom("Feather-Bold", size: 22))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text(hintText)
                        .font(.custom("Feather-Bold", size: 15))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#f59e0b").opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "#f59e0b").opacity(0.3), lineWidth: 1.5)
                                )
                        )
                        .padding(.horizontal, 20)

                    // Remaining hints counter
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#f59e0b"))
                        Text("\(hintsRemaining) ipucu kaldı")
                            .font(.custom("Feather-Bold", size: 13))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Anladım, Devam Et")
                            .font(.custom("Feather-Bold", size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Speaking Mic Button
private struct SpeakingMicButton: View {
    let langCode: String
    let questionIndex: Int          // yeni soru gelince metni sıfırlamak için
    let onResult: (String) -> Void
    let onMute: () -> Void          // 15 dk sesli soru kapatma

    @ObservedObject private var srm = SpeechRecognitionManager.shared
    @State private var permissionDenied = false
    @State private var showMuteAlert = false

    private let micColor = Color(hex: "#8b5cf6")

    var body: some View {
        VStack(spacing: 16) {
            // Mic button
            Button {
                handleMicTap()
            } label: {
                ZStack {
                    Circle()
                        .fill(srm.isRecording
                              ? LinearGradient(colors: [Color.red.opacity(0.8), Color.red],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                              : LinearGradient(colors: [micColor, Color(hex: "#7c3aed")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 90, height: 90)
                        .shadow(color: (srm.isRecording ? Color.red : micColor).opacity(0.4),
                                radius: 16, y: 8)
                        .scaleEffect(srm.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                   value: srm.isRecording)

                    Image(systemName: srm.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            // Status / recognized text
            if srm.isRecording {
                Text(AL.s(.gameSpeakListening))
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(Color.red)
            } else if srm.isProcessing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8).tint(AppTheme.Colors.primaryOrange)
                    Text("Analiz ediliyor...")
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                }
            } else if !srm.recognizedText.isEmpty {
                Text(srm.recognizedText)
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 10))
            } else if permissionDenied {
                Text(AL.s(.gameSpeakNoPermission))
                    .font(.custom("Feather-Bold", size: 13))
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
            } else {
                Text(AL.s(.gameSpeakMicHint))
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            // Check button: show after Whisper returns recognized text
            if !srm.recognizedText.isEmpty && !srm.isProcessing {
                Button {
                    onResult(srm.recognizedText)
                } label: {
                    Text(AL.s(.gameCheck))
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
            }

            // "Microphone Unavailable" button → mute speaking questions for 15 min
            Button {
                showMuteAlert = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 12))
                    Text(AL.s(.gameSpeakCantSpeak))
                        .font(.custom("Feather-Bold", size: 13))
                }
                .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .alert("🔇 Sessiz Mod", isPresented: $showMuteAlert) {
                Button("15 dk Sessiz Devam") {
                    onMute()
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Önümüzdeki 15 dakika boyunca sesli soru sorulmayacak, diğer soru tipleriyle devam edeceğiz.")
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
private struct DailyLimitOverlay: View {
    let onPaywall: () -> Void
    let onQuit: () -> Void

    @State private var countdown: String = DailyLimitManager.shared.countdownString
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let proColor     = Color(hex: "#8b5cf6")
    private let proColorDark = Color(hex: "#7c3aed")

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── İkon + Başlık ──────────────────────────────────────
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [proColor, proColorDark],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Text("⚡️")
                            .font(.system(size: 36))
                    }

                    Text(AL.s(.dailyLimitTitle))
                        .font(.custom("Feather-Bold", size: 22))
                        .foregroundStyle(.white)

                    Text(AL.s(.dailyLimitSubtitle))
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)

                // ── Geri sayım ─────────────────────────────────────────
                VStack(spacing: 6) {
                    Text(AL.s(.dailyLimitResetsIn))
                        .font(.custom("Feather-Bold", size: 13))
                        .foregroundStyle(.white.opacity(0.6))

                    Text(countdown)
                        .font(.custom("Feather-Bold", size: 36))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // ── Butonlar ────────────────────────────────────────────
                VStack(spacing: 12) {
                    // Pro → Paywall
                    Button(action: onPaywall) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 15))
                            Text(AL.s(.dailyLimitGetPro))
                                .font(.custom("Feather-Bold", size: 16))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [proColor, proColorDark],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: proColor.opacity(0.4), radius: 12, y: 6)
                    }

                    // Kapat
                    Button(action: onQuit) {
                        Text(AL.s(.dailyLimitClose))
                            .font(.custom("Feather-Bold", size: 15))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "#1a1a2e"))
                    .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
            )
            .padding(.horizontal, 20)
        }
        .onReceive(timer) { _ in
            countdown = DailyLimitManager.shared.countdownString
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Sentence Builder Content (Duolingo-style chip builder)
// MARK: ═══════════════════════════════════════════════════════════

private struct SentenceBuilderContent: View {
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
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YENİ KELİME")
                        .font(.custom("Feather-Bold", size: 11))
                        .foregroundStyle(Color(hex: "#8b5cf6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#8b5cf6").opacity(0.1), in: Capsule())
                    Text("Aşağıdaki cümleyi çevir")
                        .font(.custom("Feather-Bold", size: 22))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)

            // ── Sentence card — Duolingo style: mascot + speech bubble ──
            HStack(alignment: .bottom, spacing: 0) {
                // Maskot (sol)
                MascotAnimationView(width: 80, height: 80)
                    .offset(y: 8)

                // Speech bubble (sağ)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        // Tappable sentence words
                        SentenceTappableWords(
                            sentence: sentence,
                            keyWord: sentenceKeyWord,
                            keyMeaning: keyMeaning,
                            tooltipIndex: $tooltipWordIndex,
                            targetLang: targetLang
                        )
                        Spacer(minLength: 0)
                        // Speaker button
                        Button {
                            TTSManager.shared.speak(sentence, langCode: targetLang)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.blue)
                                .padding(8)
                                .background(Color.blue.opacity(0.1), in: Circle())
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#e2e8f0"), lineWidth: 1.5)
                )
                // Speech bubble tail (sol kenara üçgen)
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#e2e8f0"))
                        .rotationEffect(.degrees(-90))
                        .offset(x: -7, y: -14)
                }
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            // ── Answer zone ───────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                if let chip = selectedChip {
                    SentenceChipBubble(word: chip, style: .selected)
                        .onTapGesture {
                            guard !isAnswered else { return }
                            withAnimation(.spring(response: 0.3)) { selectedChip = nil }
                        }
                } else {
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.Colors.inputBorder)
                                .frame(width: 44, height: 4)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        selectedChip != nil
                            ? AppTheme.Colors.primaryOrange.opacity(0.5)
                            : AppTheme.Colors.inputBorder,
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .animation(.spring(response: 0.3), value: selectedChip)

            Spacer(minLength: 16)
            Divider().padding(.horizontal, 20)
            Spacer(minLength: 16)

            // ── Word bank ──────────────────────────────────────────
            OBFlowLayout(spacing: 10) {
                ForEach(availableChips, id: \.self) { chip in
                    SentenceChipBubble(word: chip, style: .bank)
                        .opacity(isAnswered ? 0.5 : 1.0)
                        .onTapGesture {
                            guard !isAnswered else { return }
                            withAnimation(.spring(response: 0.3)) {
                                selectedChip = chip
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .animation(.spring(response: 0.3), value: availableChips.count)

            Spacer(minLength: 20)

            // ── Check button ───────────────────────────────────────
            if let answer = selectedChip, !isAnswered {
                Button { onSubmit(answer) } label: {
                    Text(AL.s(.gameCheck))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Spacer(minLength: 84)
            }
        }
        .animation(.spring(response: 0.35), value: selectedChip)
    }
}

// MARK: - Tappable Sentence Words (flow layout + tooltip)

private struct SentenceTappableWords: View {
    let sentence: String
    let keyWord: String
    let keyMeaning: String
    @Binding var tooltipIndex: Int?
    let targetLang: String

    private var words: [String] {
        sentence.components(separatedBy: " ").filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Words in a wrapping flow
            OBFlowLayout(spacing: 6) {
                ForEach(Array(words.enumerated()), id: \.offset) { idx, word in
                    let clean = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                    let isKey = clean.contains(keyWord.lowercased()) || keyWord.lowercased().contains(clean)

                    Text(word)
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(isKey ? AppTheme.Colors.primaryOrange : Color(hex: "#1e293b"))
                        .padding(.horizontal, isKey ? 6 : 2)
                        .padding(.vertical, isKey ? 3 : 0)
                        .background(
                            isKey
                            ? AppTheme.Colors.primaryOrange.opacity(0.12)
                            : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .underline(isKey, color: AppTheme.Colors.primaryOrange.opacity(0.6))
                        .onTapGesture {
                            if isKey {
                                withAnimation(.spring(response: 0.3)) {
                                    tooltipIndex = tooltipIndex == idx ? nil : idx
                                }
                            } else {
                                // Play pronunciation for other words
                                TTSManager.shared.speak(
                                    word.trimmingCharacters(in: .punctuationCharacters),
                                    langCode: targetLang
                                )
                            }
                        }
                }
            }

            // Tooltip strip (shown below sentence when key word tapped)
            if tooltipIndex != nil {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)

                    Text(keyWord)
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)

                    Text("=")
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Text(keyMeaning)
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Spacer()

                    Button {
                        TTSManager.shared.speak(keyWord, langCode: targetLang)
                    } label: {
                        Image(systemName: "speaker.wave.1.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.blue)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#f0f9ff"), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.Colors.primaryOrange.opacity(0.3), lineWidth: 1)
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Sentence Chip Bubble

private struct SentenceChipBubble: View {
    enum Style { case bank, selected }
    let word: String
    let style: Style

    var body: some View {
        Text(word)
            .font(.custom("Feather-Bold", size: 16))
            .foregroundStyle(style == .selected
                ? AppTheme.Colors.primaryOrange
                : Color(hex: "#1e293b"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                style == .selected
                ? AppTheme.Colors.primaryOrange.opacity(0.08)
                : Color.white
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        style == .selected
                        ? AppTheme.Colors.primaryOrange
                        : Color(hex: "#cbd5e1"),
                        lineWidth: style == .selected ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(style == .selected ? 0 : 0.05), radius: 2, y: 2)
    }
}
