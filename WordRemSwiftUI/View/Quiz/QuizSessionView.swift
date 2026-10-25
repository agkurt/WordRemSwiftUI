//
//  QuizSessionView.swift
//  WordRemSwiftUI
//

import SwiftUI
import AVFoundation

struct QuizSessionView: View {

    let wordInfos: [WordInfo]
    let mode: QuizMode
    let cardId: String
    let cardName: String
    var targetLang: String = "EN"

    @StateObject private var viewModel = QuizViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false

    var body: some View {
        ZStack {
            DS.Colors.paper.ignoresSafeArea()

            if case .finished = viewModel.state {
                // Auto-open result
                Color.clear.onAppear { showResult = true }
            }

            VStack(spacing: 0) {
                // MARK: Top Bar
                HStack(spacing: 16) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .frame(width: 36, height: 36)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(DS.Colors.line)
                            Capsule().fill(DS.Colors.ink)
                                .frame(width: geo.size.width * min(1, viewModel.progress))
                                .animation(.easeOut(duration: 0.35), value: viewModel.progress)
                        }
                    }
                    .frame(height: 4)
                    Text("\(viewModel.currentIndex + 1)/\(viewModel.questions.count)")
                        .font(DS.Font.ui(13, weight: .medium).monospacedDigit())
                        .foregroundStyle(DS.Colors.muted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // MARK: Question Content
                if let question = viewModel.currentQuestion {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            QuizQuestionCard(question: question, modeTitle: mode.rawValue)

                            // Feedback banner
                            if case .answered(let isCorrect) = viewModel.state {
                                QuizFeedbackBanner(isCorrect: isCorrect,
                                                   correctAnswer: question.correctAnswer)
                                    .transition(.opacity)
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

                            case .listening:
                                ListeningModeInput(
                                    wordToPlay: question.wordInfo.names,
                                    langCode: targetLang,
                                    options: question.options,
                                    correctAnswer: question.correctAnswer,
                                    state: viewModel.state
                                ) { selected in
                                    withAnimation { viewModel.submitMultipleChoice(selected: selected) }
                                }

                            case .speaking:
                                // Speaking fallback: write the pronunciation / translation
                                WritingInput(
                                    text: $viewModel.writingAnswer,
                                    state: viewModel.state,
                                    onSubmit: {
                                        withAnimation { viewModel.submitWriting() }
                                    }
                                )

                            case .fillInTheBlank:
                                FillInTheBlankInput(
                                    gapSentence: question.gapSentence,
                                    sentenceWords: question.sentenceWords,
                                    correctAnswer: question.correctAnswer,
                                    state: viewModel.state
                                ) { selected in
                                    withAnimation { viewModel.submitFillInTheBlank(selected: selected) }
                                }

                            case .sentenceBuilder:
                                SentenceBuilderInput(
                                    sentenceWords: question.sentenceWords,
                                    correctAnswer: question.correctAnswer,
                                    state: viewModel.state
                                ) { selected in
                                    withAnimation { viewModel.submitSentenceBuilder(selectedWord: selected) }
                                }
                            case .introduce, .translateSentence, .buildSentence, .matchPairs:
                                EmptyView()   // ders akışına özel modlar, deste quizinde kullanılmaz
                            }

                            // Next button
                            if case .answered = viewModel.state {
                                Button(viewModel.isLastQuestion ? "See Results" : "Next Question") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.nextQuestion()
                                    }
                                }
                                .buttonStyle(InkButtonStyle())
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
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

// MARK: - Shared answer styling

private enum QuizChoiceStatus { case idle, correct, wrong, dimmed }

private func quizChoiceStatus(_ option: String, correct: String, answered: Bool, picked: String?) -> QuizChoiceStatus {
    guard answered else { return .idle }
    if option == correct { return .correct }
    if let picked, option == picked { return .wrong }
    return .dimmed
}

private extension View {
    /// paperRaised yüzey, 1pt çizgi; cevaptan sonra başarı/hata tonu
    func quizChoiceSurface(_ status: QuizChoiceStatus, radius: CGFloat = DS.Radius.button) -> some View {
        let fill: Color = status == .correct ? DS.Colors.successSoft
            : status == .wrong ? DS.Colors.dangerSoft : DS.Colors.paperRaised
        let border: Color = status == .correct ? DS.Colors.success
            : status == .wrong ? DS.Colors.danger : DS.Colors.line
        let width: CGFloat = (status == .correct || status == .wrong) ? 1.5 : 1
        return self
            .background(fill, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: width))
            .opacity(status == .dimmed ? 0.5 : 1)
            .contentShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Question Card
private struct QuizQuestionCard: View {
    let question: QuizQuestion
    let modeTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: modeTitle)

            Text("What is the meaning of")
                .font(DS.Font.ui(15, weight: .medium))
                .foregroundStyle(DS.Colors.muted)

            Text(question.wordInfo.names)
                .font(DS.Font.display(question.wordInfo.names.contains(" ") ? 28 : 44, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.5)

            if !question.wordInfo.descriptions.isEmpty {
                Text(question.wordInfo.descriptions)
                    .font(DS.Font.display(17, weight: .regular).italic())
                    .foregroundStyle(DS.Colors.inkSoft)
                    .lineLimit(2)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(DS.Colors.line, lineWidth: 1))
    }
}

// MARK: - Multiple Choice
private struct MultipleChoiceOptions: View {
    let options: [String]
    let correctAnswer: String
    let state: QuizViewModel.QuizState
    let onSelect: (String) -> Void

    @State private var picked: String? = nil

    var isAnswered: Bool {
        if case .answered = state { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                OptionRow(
                    option: option,
                    status: quizChoiceStatus(option, correct: correctAnswer, answered: isAnswered, picked: picked),
                    onSelect: {
                        picked = option
                        onSelect(option)
                    }
                )
                .disabled(isAnswered)
                .animation(.easeOut(duration: 0.15), value: isAnswered)
            }
        }
        .onChange(of: options) { _ in picked = nil }
    }
}

private struct OptionRow: View {
    let option: String
    let status: QuizChoiceStatus
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(option)
                    .font(DS.Font.ui(17, weight: .medium))
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if status == .correct {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Colors.success)
                } else if status == .wrong {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Colors.danger)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .quizChoiceSurface(status)
        }
        .buttonStyle(.plain)
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
        HStack(spacing: 12) {
            TFButton(title: "True", icon: "checkmark", tint: DS.Colors.success, disabled: isAnswered) {
                onAnswer(true)
            }
            TFButton(title: "False", icon: "xmark", tint: DS.Colors.danger, disabled: isAnswered) {
                onAnswer(false)
            }
        }
    }
}

private struct TFButton: View {
    let title: String
    let icon: String
    let tint: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(DS.Font.display(20, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.button).stroke(DS.Colors.line, lineWidth: 1))
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
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

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 12) {
            TextField("Type the meaning...", text: $text)
                .font(DS.Font.ui(17, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .tint(DS.Colors.accent)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.button).stroke(DS.Colors.line, lineWidth: 1))
                .disabled(isAnswered)
                .autocorrectionDisabled()
                .autocapitalization(.none)

            if !isAnswered {
                Button("Check Answer") {
                    UIApplication.shared.hideKeyboard()
                    onSubmit()
                }
                .buttonStyle(InkButtonStyle(fill: isEmpty ? DS.Colors.line : DS.Colors.ink,
                                            foreground: isEmpty ? DS.Colors.muted : DS.Colors.paperRaised))
                .disabled(isEmpty)
            }
        }
    }
}

// MARK: - Listening Mode Input
private struct ListeningModeInput: View {
    let wordToPlay: String
    let langCode: String
    let options: [String]
    let correctAnswer: String
    let state: QuizViewModel.QuizState
    let onSelect: (String) -> Void

    @State private var picked: String? = nil

    var isAnswered: Bool {
        if case .answered = state { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Audio buttons
            HStack(spacing: 10) {
                Button {
                    TTSManager.shared.speak(wordToPlay, langCode: langCode)
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .font(DS.Font.ui(14, weight: .semibold))
                        .foregroundStyle(DS.Colors.paperRaised)
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .background(DS.Colors.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                Button {
                    TTSManager.shared.speakSlow(wordToPlay, langCode: langCode)
                } label: {
                    Label("Slow", systemImage: "tortoise")
                        .font(DS.Font.ui(14, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .overlay(Capsule().stroke(DS.Colors.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Options
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    OptionRow(
                        option: option,
                        status: quizChoiceStatus(option, correct: correctAnswer, answered: isAnswered, picked: picked),
                        onSelect: {
                            picked = option
                            onSelect(option)
                        }
                    )
                    .disabled(isAnswered)
                    .animation(.easeOut(duration: 0.15), value: isAnswered)
                }
            }
        }
        .onChange(of: options) { _ in picked = nil }
        .onAppear {
            TTSManager.shared.speak(wordToPlay, langCode: langCode)
        }
    }
}

// MARK: - Fill in the Blank
private struct FillInTheBlankInput: View {
    let gapSentence: String
    let sentenceWords: [String]
    let correctAnswer: String
    let state: QuizViewModel.QuizState
    let onSelect: (String) -> Void

    @State private var picked: String? = nil

    var isAnswered: Bool {
        if case .answered = state { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 14) {
            // Gap sentence
            Text(gapSentence)
                .font(DS.Font.display(24, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: DS.Radius.card))

            // Word options grid (2 columns)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(sentenceWords, id: \.self) { word in
                    Button {
                        picked = word
                        onSelect(word)
                    } label: {
                        Text(word)
                            .font(DS.Font.ui(17, weight: .medium))
                            .foregroundStyle(DS.Colors.ink)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .quizChoiceSurface(quizChoiceStatus(word, correct: correctAnswer,
                                                                answered: isAnswered, picked: picked))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnswered)
                }
            }
        }
        .onChange(of: sentenceWords) { _ in picked = nil }
    }
}

// MARK: - Sentence Builder
private struct SentenceBuilderInput: View {
    let sentenceWords: [String]
    let correctAnswer: String
    let state: QuizViewModel.QuizState
    let onSelect: (String) -> Void

    @State private var picked: String? = nil

    var isAnswered: Bool {
        if case .answered = state { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Tap the correct translation", color: DS.Colors.muted)

            // Word chips (flexible grid)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)],
                      spacing: 10) {
                ForEach(sentenceWords, id: \.self) { word in
                    Button {
                        picked = word
                        onSelect(word)
                    } label: {
                        Text(word)
                            .font(DS.Font.ui(16, weight: .medium))
                            .foregroundStyle(DS.Colors.ink)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 6)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .quizChoiceSurface(quizChoiceStatus(word, correct: correctAnswer,
                                                                answered: isAnswered, picked: picked),
                                               radius: 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnswered)
                }
            }
        }
        .onChange(of: sentenceWords) { _ in picked = nil }
    }
}

// MARK: - Feedback Banner
private struct QuizFeedbackBanner: View {
    let isCorrect: Bool
    let correctAnswer: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCorrect ? "checkmark" : "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isCorrect ? DS.Colors.success : DS.Colors.danger)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke((isCorrect ? DS.Colors.success : DS.Colors.danger).opacity(0.5), lineWidth: 1))
            VStack(alignment: .leading, spacing: 4) {
                Text(isCorrect ? "Correct!" : "Not quite...")
                    .font(DS.Font.display(20, weight: .bold))
                    .foregroundStyle(isCorrect ? DS.Colors.success : DS.Colors.danger)
                if !isCorrect {
                    Text("Answer: \(correctAnswer)")
                        .font(DS.Font.ui(16, weight: .medium))
                        .foregroundStyle(DS.Colors.ink)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(isCorrect ? DS.Colors.successSoft : DS.Colors.dangerSoft,
                    in: RoundedRectangle(cornerRadius: DS.Radius.button))
    }
}
