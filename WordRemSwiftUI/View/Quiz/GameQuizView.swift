//
//  GameQuizView.swift
//  WordRemSwiftUI
//
//  Full-screen gamified quiz — daily 25-question limit, progress bar, XP toast.
//  Hearts / lives system removed. Replaced with a daily limit paywall popup.
//

import SwiftUI

struct GameQuizView: View {

    let sessionType: QuizSessionType
    let title: String

    @StateObject private var vm = GameQuizViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var wordsLoaded = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundStart.ignoresSafeArea()

            switch vm.state {
            case .loading:
                loadingView

            case .question:
                if let question = vm.currentQuestion {
                    questionView(question)
                }

            case .answered(let isCorrect):
                if let question = vm.currentQuestion {
                    questionView(question)
                        .overlay(feedbackOverlay(isCorrect: isCorrect))
                }

            case .dailyLimitReached:
                questionView(vm.currentQuestion ?? vm.questions.first.map { _ in vm.questions[max(0, vm.currentIndex - 1)] } ?? vm.questions.first!)
                    .blur(radius: 4)
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
            do {
                let words: [SBWord]
                switch sessionType {
                case .level(let lId):
                    words = try await SupabaseDataService.shared.fetchWords(levelId: lId)
                case .mistakes:
                    let ids = MistakesManager.shared.mistakeUUIDs
                    words = try await SupabaseDataService.shared.fetchWords(byIds: ids)
                }
                vm.setup(sessionType: sessionType, words: words, levelTitle: title)
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
                             words: vm.questions.map { $0.word },
                             levelTitle: title)
                }
            }
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text(AL.s(.gameLoading))
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    // MARK: - Question Screen
    @ViewBuilder
    private func questionView(_ question: GameQuestion) -> some View {
        VStack(spacing: 0) {
            quizHeader
            Spacer(minLength: 24)
            wordCard(question)
            Spacer(minLength: 20)
            Text(AL.s(.gameWhatIsMeaning))
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 24)
            Spacer(minLength: 20)
            if question.mode == .multipleChoice && !question.options.isEmpty {
                multipleChoiceGrid(question)
            } else {
                writingField
            }
            Spacer(minLength: 32)
        }
    }

    // MARK: - Header  (kalpler kaldırıldı → kalan soru sayısı gösteriliyor)
    private var quizHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Quit
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(10)
                        .background(AppTheme.Colors.inputBorder.opacity(0.5), in: Circle())
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
                            .font(.custom("Poppins-SemiBold", size: 13))
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
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Material.ultraThinMaterial)
    }

    // MARK: - Word Card
    private func wordCard(_ question: GameQuestion) -> some View {
        VStack(spacing: 8) {
            Text(question.word.term)
                .font(.custom("Poppins-Bold", size: 32))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            if let phonetic = question.word.phonetic {
                Text("/\(phonetic)/")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
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
    }

    // MARK: - Multiple Choice Grid
    private func multipleChoiceGrid(_ question: GameQuestion) -> some View {
        let answered = { () -> Bool in
            if case .answered = vm.state { return true }
            return false
        }()
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(question.options, id: \.self) { option in
                OptionButton(text: option, correctAnswer: question.correctAnswer, isAnswered: answered) {
                    if !answered { vm.submitMultipleChoice(selected: option) }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Writing Field
    private var writingField: some View {
        VStack(spacing: 12) {
            TextField(AL.s(.gameTypeTranslation), text: $vm.writingAnswer)
                .font(.custom("Poppins-Regular", size: 16))
                .padding()
                .background(AppTheme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.inputBorder))
                .padding(.horizontal, 24)
            Button { vm.submitWriting() } label: {
                Text(AL.s(.gameCheck))
                    .font(.custom("Poppins-SemiBold", size: 16))
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
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                Text(isCorrect ? AL.s(.gameCorrect) : AL.s(.gameNotQuite))
                    .font(.custom("Poppins-SemiBold", size: 17))
                Spacer()
                Button(AL.s(.gameContinue)) { vm.nextQuestion() }
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isCorrect ? Color.green : AppTheme.Colors.primaryOrange, in: Capsule())
            }
            .foregroundStyle(isCorrect ? Color.green : Color.red)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(isCorrect ? Color.green.opacity(0.12) : Color.red.opacity(0.09))
            )
        }
        .transition(.move(edge: .bottom))
        .animation(.spring(response: 0.4), value: true)
    }
}

// MARK: - Option Button
private struct OptionButton: View {
    let text: String
    let correctAnswer: String
    let isAnswered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundStyle(isAnswered ? answerTextColor : AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isAnswered ? answerBgColor : Color.white)
                        .shadow(color: AppTheme.Shadows.cardColor,
                                radius: isAnswered ? 0 : 6, y: isAnswered ? 0 : 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isAnswered ? answerBorderColor : AppTheme.Colors.inputBorder,
                                lineWidth: isAnswered ? 2 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3), value: isAnswered)
    }

    private var isCorrect: Bool      { text == correctAnswer }
    private var answerBgColor: Color { isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.08) }
    private var answerBorderColor: Color { isCorrect ? Color.green : Color.red }
    private var answerTextColor: Color   { isCorrect ? Color.green : Color.red }
}

// MARK: - XP Toast
private struct XPToastView: View {
    let amount: Int
    var body: some View {
        VStack {
            Text("+\(amount) XP")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundStyle(AppTheme.Colors.primaryOrange)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.12), in: Capsule())
                .shadow(color: AppTheme.Shadows.vibrantColor, radius: 10, y: 4)
            Spacer()
        }
        .padding(.top, 120)
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
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundStyle(.white)

                    Text(AL.s(.dailyLimitSubtitle))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)

                // ── Geri sayım ─────────────────────────────────────────
                VStack(spacing: 6) {
                    Text(AL.s(.dailyLimitResetsIn))
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundStyle(.white.opacity(0.6))

                    Text(countdown)
                        .font(.custom("Poppins-Bold", size: 36))
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
                                .font(.custom("Poppins-Bold", size: 16))
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
                            .font(.custom("Poppins-Medium", size: 15))
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
