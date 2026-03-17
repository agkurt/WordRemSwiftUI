//
//  GameQuizView.swift
//  WordRemSwiftUI
//
//  Full-screen gamified quiz — 3 hearts, progress bar, XP toast,
//  card + 2×2 option grid. Loads words from Supabase for the given level.
//

import SwiftUI

struct GameQuizView: View {

    let sessionType: QuizSessionType
    let title: String

    @StateObject private var vm = GameQuizViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var wordsLoaded = false

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

            case .outOfLives:
                OutOfLivesView {
                    vm.restart()
                } onQuit: {
                    dismiss()
                }

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
                vm.setup(sessionType: sessionType, words: words)
            } catch {
                print("❌ Failed to load words: \(error)")
                vm.state = .outOfLives
            }
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Loading questions…")
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    // MARK: - Question Screen
    @ViewBuilder
    private func questionView(_ question: GameQuestion) -> some View {
        VStack(spacing: 0) {
            // ── Header bar ──────────────────────────────────────────
            quizHeader

            // ── Word Card ───────────────────────────────────────────
            Spacer(minLength: 24)

            wordCard(question)

            Spacer(minLength: 20)

            // ── Prompt ──────────────────────────────────────────────
            Text("What is the meaning of this word?")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 24)

            Spacer(minLength: 20)

            // ── Answer Options ──────────────────────────────────────
            if question.mode == .multipleChoice && !question.options.isEmpty {
                multipleChoiceGrid(question)
            } else {
                writingField
            }

            Spacer(minLength: 32)
        }
    }

    // MARK: - Header
    private var quizHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Quit button
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

                // Hearts
                HStack(spacing: 3) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < vm.lives ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(i < vm.lives ? Color.red : AppTheme.Colors.inputBorder)
                            .animation(.spring(response: 0.3), value: vm.lives)
                    }
                }
            }
            .padding(.horizontal, 20)

            Text("Question \(vm.currentIndex + 1) / \(vm.totalCount)")
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
                OptionButton(
                    text: option,
                    correctAnswer: question.correctAnswer,
                    isAnswered: answered
                ) {
                    if !answered {
                        vm.submitMultipleChoice(selected: option)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Writing Field
    private var writingField: some View {
        VStack(spacing: 12) {
            TextField("Type the translation…", text: $vm.writingAnswer)
                .font(.custom("Poppins-Regular", size: 16))
                .padding()
                .background(AppTheme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.inputBorder))
                .padding(.horizontal, 24)

            Button {
                vm.submitWriting()
            } label: {
                Text("Check")
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
                Text(isCorrect ? "Correct! 🎉" : "Not quite…")
                    .font(.custom("Poppins-SemiBold", size: 17))
                Spacer()
                Button("Continue") { vm.nextQuestion() }
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isCorrect ? Color.green : AppTheme.Colors.primaryOrange,
                                in: Capsule())
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

    private var isCorrect: Bool { text == correctAnswer }
    private var answerBgColor: Color {
        isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.08)
    }
    private var answerBorderColor: Color {
        isCorrect ? Color.green : Color.red
    }
    private var answerTextColor: Color {
        isCorrect ? Color.green : Color.red
    }
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

// MARK: - Out of Lives
private struct OutOfLivesView: View {
    let onRetry: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Text("💔")
                .font(.system(size: 72))

            Text("Out of Lives!")
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text("Don't give up — try again!")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.custom("Poppins-SemiBold", size: 17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }

                Button(action: onQuit) {
                    Text("Quit")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(40)
    }
}
