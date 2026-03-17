//
//  QuizSessionView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct QuizSessionView: View {

    let wordInfos: [WordInfo]
    let mode: QuizMode
    let cardId: String
    let cardName: String

    @StateObject private var viewModel = QuizViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false

    var body: some View {
        ZStack {
            LinearBackgroundView()

            if case .finished = viewModel.state {
                // Auto-open result
                Color.clear.onAppear { showResult = true }
            }

            VStack(spacing: 0) {
                // MARK: Top Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(mode.rawValue)
                        .font(.custom("Poppins-SemiBold", size: 15))
                    Spacer()
                    Text("\(viewModel.currentIndex + 1)/\(viewModel.questions.count)")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // MARK: Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.inputBorder)
                            .frame(height: 6)
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "#f97316"), Color(hex: "#ea580c")],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * viewModel.progress, height: 6)
                            .animation(.spring(response: 0.5), value: viewModel.progress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // MARK: Question Content
                if let question = viewModel.currentQuestion {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            QuizQuestionCard(question: question)

                            // Feedback banner
                            if case .answered(let isCorrect) = viewModel.state {
                                QuizFeedbackBanner(isCorrect: isCorrect,
                                                   correctAnswer: question.correctAnswer)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            // Mode-specific input
                            switch mode {
                            case .multipleChoice:
                                MultipleChoiceOptions(
                                    options: question.options,
                                    correctAnswer: question.correctAnswer,
                                    state: viewModel.state
                                ) { selected in
                                    withAnimation { viewModel.submitMultipleChoice(selected: selected) }
                                }

                            case .trueFalse:
                                TrueFalseButtons(state: viewModel.state) { answer in
                                    withAnimation { viewModel.submitTrueFalse(answer: answer) }
                                }

                            case .writing:
                                WritingInput(
                                    text: $viewModel.writingAnswer,
                                    state: viewModel.state,
                                    onSubmit: {
                                        withAnimation { viewModel.submitWriting() }
                                    }
                                )
                            }

                            // Next button
                            if case .answered = viewModel.state {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.nextQuestion()
                                    }
                                } label: {
                                    Text(viewModel.isLastQuestion ? "See Results" : "Next Question")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color(hex: "#f97316"))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            viewModel.setup(wordInfos: wordInfos, mode: mode, cardId: cardId)
        }
        .fullScreenCover(isPresented: $showResult) {
            QuizResultView(
                score: Int(viewModel.quizResult.percentage),
                stars: viewModel.quizResult.percentage >= 90 ? 3
                     : viewModel.quizResult.percentage >= 70 ? 2
                     : viewModel.quizResult.percentage >= 50 ? 1 : 0,
                xpEarned: 0,
                levelTitle: cardName,
                onDone: {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Question Card
private struct QuizQuestionCard: View {
    let question: QuizQuestion

    var body: some View {
        VStack(spacing: 12) {
            Text("What is the meaning of")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(.secondary)

            Text(question.wordInfo.names)
                .font(.custom("Poppins-SemiBold", size: 32))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if !question.wordInfo.descriptions.isEmpty {
                Text("\"\(question.wordInfo.descriptions)\"")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: AppTheme.Shadows.cardColor, radius: 12, y: 6)
                .overlay(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16)
                        .trim(from: 0.82, to: 1)
                        .frame(width: 120, height: 110)
                        .foregroundStyle(.orange.opacity(0.7))
                }
        )
        .padding(.top, 6)
    }
}

// MARK: - Multiple Choice
private struct MultipleChoiceOptions: View {
    let options: [String]
    let correctAnswer: String
    let state: QuizViewModel.QuizState
    let onSelect: (String) -> Void

    var isAnswered: Bool {
        if case .answered = state { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                OptionRow(
                    option: option,
                    isCorrect: option == correctAnswer,
                    isAnswered: isAnswered,
                    onSelect: { onSelect(option) }
                )
                .disabled(isAnswered)
                .animation(.easeInOut(duration: 0.2), value: isAnswered)
            }
        }
    }
}

private struct OptionRow: View {
    let option: String
    let isCorrect: Bool
    let isAnswered: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(option)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundStyle(isAnswered ? (isCorrect ? .white : .secondary) : .primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isAnswered {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(isCorrect ? .green : .red)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isAnswered
                          ? (isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.1))
                          : Color.white)
                    .shadow(color: isAnswered ? .clear : AppTheme.Shadows.softColor, radius: 4, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isAnswered && isCorrect ? Color.green : AppTheme.Colors.inputBorder, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - True / False
private struct TrueFalseButtons: View {
    let state: QuizViewModel.QuizState
    let onAnswer: (Bool) -> Void

    var isAnswered: Bool {
        if case .answered = state { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 14) {
            TFButton(title: "True", icon: "checkmark", color: .green, disabled: isAnswered) {
                onAnswer(true)
            }
            TFButton(title: "False", icon: "xmark", color: .red, disabled: isAnswered) {
                onAnswer(false)
            }
        }
    }
}

private struct TFButton: View {
    let title: String
    let icon: String
    let color: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 15))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(disabled ? Color.gray.opacity(0.3) : color.opacity(0.9))
                    .shadow(color: disabled ? .clear : color.opacity(0.3), radius: 6, y: 4)
            )
        }
        .disabled(disabled)
    }
}

// MARK: - Writing
private struct WritingInput: View {
    @Binding var text: String
    let state: QuizViewModel.QuizState
    let onSubmit: () -> Void

    var isAnswered: Bool {
        if case .answered = state { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField("Type the meaning...", text: $text)
                .font(.custom("Poppins-Regular", size: 16))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
                )
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.inputBorder))
                .disabled(isAnswered)
                .autocorrectionDisabled()
                .autocapitalization(.none)

            if !isAnswered {
                Button {
                    UIApplication.shared.hideKeyboard()
                    onSubmit()
                } label: {
                    Text("Check Answer")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            text.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray.opacity(0.4)
                                : Color(hex: "#f97316")
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

// MARK: - Feedback Banner
private struct QuizFeedbackBanner: View {
    let isCorrect: Bool
    let correctAnswer: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(isCorrect ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(isCorrect ? "Correct! 🎉" : "Not quite...")
                    .font(.custom("Poppins-SemiBold", size: 14))
                if !isCorrect {
                    Text("Answer: \(correctAnswer)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCorrect ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCorrect ? Color.green.opacity(0.4) : Color.orange.opacity(0.4), lineWidth: 1.5)
                )
        )
    }
}
