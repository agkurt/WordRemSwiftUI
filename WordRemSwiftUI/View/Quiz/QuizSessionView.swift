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
    @State private var startedAt = Date()
    @State private var tracked = false

    private func trackEnd(_ action: String) {
        guard !tracked else { return }
        tracked = true
        let r = viewModel.quizResult
        Track.practice(action, type: mode.rawValue, wordCount: wordInfos.count, correct: r.score, total: r.total,
                       duration: Date().timeIntervalSince(startedAt), entryPoint: "words")
    }

    var body: some View {
        ZStack {
            DS.Colors.paper.ignoresSafeArea()

            if case .finished = viewModel.state {
                // Auto-open result
                Color.clear.onAppear { showResult = true; trackEnd("complete") }
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
                    // Her soru bir çentik (defter cetveli gibi)
                    let parts = max(1, min(viewModel.questions.count, 20))
                    HStack(spacing: 3) {
                        ForEach(0..<parts, id: \.self) { i in
                            Capsule()
                                .fill(Double(i) < min(1, viewModel.progress) * Double(parts) ? DS.Colors.accent : DS.Colors.line)
                                .frame(height: 4)
                        }
                    }
                    .animation(.easeOut(duration: 0.35), value: viewModel.progress)
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
                            QuizQuestionCard(question: question, modeTitle: mode.title)

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
                                Button(viewModel.isLastQuestion ? AL.s(.quizSeeResults) : AL.s(.quizNextQuestion)) {
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
            startedAt = Date()
            Track.practice("start", type: mode.rawValue, wordCount: wordInfos.count, entryPoint: "words")
        }
        .onDisappear { trackEnd("exit") }
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

/// Seçenek harfi: a, b, c, d…
private func choiceLetter(_ i: Int) -> String {
    let letters = Array("abcdefgh")
    return i < letters.count ? String(letters[i]) : "\(i + 1)"
}

/// Kırmızı kalemle atılmış çarpı
private struct PenCross: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let sx = r.width / 24, sy = r.height / 24
        p.move(to: CGPoint(x: r.minX + 4 * sx, y: r.minY + 4 * sy))
        p.addQuadCurve(to: CGPoint(x: r.minX + 20 * sx, y: r.minY + 21 * sy),
                       control: CGPoint(x: r.minX + 11 * sx, y: r.minY + 11 * sy))
        p.move(to: CGPoint(x: r.minX + 20 * sx, y: r.minY + 3 * sy))
        p.addQuadCurve(to: CGPoint(x: r.minX + 3 * sx, y: r.minY + 20 * sy),
                       control: CGPoint(x: r.minX + 12 * sx, y: r.minY + 10 * sy))
        return p
    }
}

/// Cevap işareti: doğruya yeşil kalem tiki, yanlışa kırmızı kalem çarpısı (kalemle çizilir gibi)
private struct ChoiceMark: View {
    let status: QuizChoiceStatus
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            PenTick()
                .trim(from: 0, to: status == .correct ? 1 : 0)
                .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            PenCross()
                .trim(from: 0, to: status == .wrong ? 1 : 0)
                .stroke(DS.Colors.redPen, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .padding(size * 0.1)
        }
        .frame(width: size, height: size * 0.86)
        .animation(.easeOut(duration: 0.3), value: status)
        .accessibilityHidden(true)
    }
}

/// Seçenek metni: yanlış seçilen kırmızı kalemle üstü çizili
private func choiceText(_ s: String, status: QuizChoiceStatus, font: Font) -> some View {
    Text(s)
        .strikethrough(status == .wrong, color: DS.Colors.redPen)
        .font(font)
        .foregroundStyle(status == .wrong ? DS.Colors.inkSoft : DS.Colors.ink)
}

/// Fiş kartı biçimli kelime kutucuğu (boşluk doldurma, cümle kurma)
private struct ChoiceTile: View {
    let word: String
    let status: QuizChoiceStatus
    var fontSize: CGFloat = 17
    var minHeight: CGFloat = 52

    var body: some View {
        choiceText(word, status: status, font: DS.Font.display(fontSize, weight: .medium))
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(status == .correct ? DS.Colors.successSoft : DS.Colors.paperRaised,
                        in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .strokeBorder(status == .correct ? DS.Colors.success : DS.Colors.line, lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                if status == .correct || status == .wrong {
                    ChoiceMark(status: status, size: 16).padding(5)
                }
            }
            .opacity(status == .dimmed ? 0.5 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Question Card
private struct QuizQuestionCard: View {
    let question: QuizQuestion
    let modeTitle: String

    var body: some View {
        // Fiş kartı: üstte terrakota çizgi, altında açık mavi satırlar
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: modeTitle, color: DS.Colors.accentText)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.accent).frame(height: 2).padding(.horizontal, -24) }

            Text(AL.s(.quizMeaningOf))
                .font(.system(size: 16, design: .serif).italic())
                .foregroundStyle(DS.Colors.muted)

            Text(question.wordInfo.names)
                .font(DS.Font.display(question.wordInfo.names.contains(" ") ? 28 : 44, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.5)

            if !question.wordInfo.descriptions.isEmpty {
                Text(question.wordInfo.descriptions)
                    .font(DS.Font.display(17, weight: .regular).italic())
                    .foregroundStyle(DS.Colors.slate)
                    .lineLimit(2)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .top) {
                DS.Colors.paperRaised
                RuledLines(pitch: 36, color: DS.Colors.cardRule).padding(.top, 58)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Colors.line, lineWidth: 1))
        .rotationEffect(.degrees(-0.8))
        .shadow(color: Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.08), radius: 12, y: 8)
        .padding(.vertical, 4)
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
        // Çizgili defter satırları
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                OptionRow(
                    option: option,
                    letter: choiceLetter(index),
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
        .overlay(alignment: .top) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
        .onChange(of: options) { _ in picked = nil }
    }
}

/// Defter satırı: solda harf (cevaptan sonra kalem işareti), doğru satır yeşil zemin, yanlış üstü çizili
private struct OptionRow: View {
    let option: String
    let letter: String
    let status: QuizChoiceStatus
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Text(letter)
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .opacity(status == .correct || status == .wrong ? 0 : 1)
                    ChoiceMark(status: status)
                }
                .frame(width: 28)
                choiceText(option, status: status, font: DS.Font.display(19, weight: .medium))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(minHeight: 58)
            .background(status == .correct ? DS.Colors.successSoft : .clear)
            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
            .opacity(status == .dimmed ? 0.5 : 1)
            .contentShape(Rectangle())
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
            TFButton(title: AL.s(.quizTrue), isTrue: true, disabled: isAnswered) {
                onAnswer(true)
            }
            TFButton(title: AL.s(.quizFalse), isTrue: false, disabled: isAnswered) {
                onAnswer(false)
            }
        }
    }
}

/// Fiş kartı: üstte kalemle tik ya da çarpı, altında serif başlık
private struct TFButton: View {
    let title: String
    let isTrue: Bool
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Group {
                    if isTrue {
                        PenTick()
                            .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    } else {
                        PenCross()
                            .stroke(DS.Colors.redPen, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            .padding(2)
                    }
                }
                .frame(width: 26, height: 22)
                Text(title)
                    .font(DS.Font.display(21, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background {
                ZStack(alignment: .top) {
                    DS.Colors.paperRaised
                    Rectangle().fill(DS.Colors.accent).frame(height: 2).padding(.top, 14)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Colors.line, lineWidth: 1))
            .rotationEffect(.degrees(isTrue ? -1 : 1))
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
            // Defter satırına yazılır: kutu yok, altında mürekkep çizgi
            TextField(AL.s(.quizTypeMeaning), text: $text)
                .font(DS.Font.display(22, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .tint(DS.Colors.accent)
                .padding(.horizontal, 4)
                .frame(height: 56)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(isAnswered ? DS.Colors.line : DS.Colors.inkSoft).frame(height: 1.5)
                }
                .padding(.bottom, 8)
                .disabled(isAnswered)
                .autocorrectionDisabled()
                .autocapitalization(.none)

            if !isAnswered {
                Button(AL.s(.quizCheckAnswer)) {
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
            HStack(spacing: 14) {
                // Mühür biçimli çal düğmesi
                Button {
                    TTSManager.shared.speak(wordToPlay, langCode: langCode)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(DS.Colors.paperRaised)
                            Circle().strokeBorder(DS.Colors.ink, lineWidth: 2)
                            Circle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                .foregroundStyle(DS.Colors.ink)
                                .padding(5)
                            Image(systemName: "play.fill")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(DS.Colors.ink)
                                .offset(x: 1.5)
                        }
                        .frame(width: 54, height: 54)
                        Text(AL.s(.quizPlay))
                            .font(DS.Font.ui(15, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 8)
                // Yavaş: kâğıt üstünde altı çizili terrakota bağlantı
                Button {
                    TTSManager.shared.speakSlow(wordToPlay, langCode: langCode)
                } label: {
                    Label(AL.s(.quizSlow), systemImage: "tortoise")
                        .font(DS.Font.ui(14, weight: .semibold))
                        .foregroundStyle(DS.Colors.accentText)
                        .padding(.vertical, 6)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(DS.Colors.accentText.opacity(0.5)).frame(height: 1)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Options: çizgili defter satırları
            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    OptionRow(
                        option: option,
                        letter: choiceLetter(index),
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
            .overlay(alignment: .top) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
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
            // Boşluklu cümle: açık mavi çizgili fiş kartında
            Text(gapSentence)
                .font(DS.Font.display(24, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .lineSpacing(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background {
                    ZStack(alignment: .top) {
                        DS.Colors.paperRaised
                        RuledLines(pitch: 36, color: DS.Colors.cardRule).padding(.top, 18)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Colors.line, lineWidth: 1))

            // Word options grid (2 columns)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(sentenceWords, id: \.self) { word in
                    Button {
                        picked = word
                        onSelect(word)
                    } label: {
                        ChoiceTile(word: word,
                                   status: quizChoiceStatus(word, correct: correctAnswer,
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
            Eyebrow(text: AL.s(.quizTapTranslation), color: DS.Colors.muted)

            // Kelime fişleri (esnek ızgara)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)],
                      spacing: 10) {
                ForEach(sentenceWords, id: \.self) { word in
                    Button {
                        picked = word
                        onSelect(word)
                    } label: {
                        ChoiceTile(word: word,
                                   status: quizChoiceStatus(word, correct: correctAnswer,
                                                            answered: isAnswered, picked: picked),
                                   fontSize: 16, minHeight: 46)
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
/// Öğretmen notu: doğruysa yeşil kalem tiki, yanlışsa kenarda kırmızı kalem çizgisi ve doğru cevap
private struct QuizFeedbackBanner: View {
    let isCorrect: Bool
    let correctAnswer: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if isCorrect {
                    PenTick()
                        .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                } else {
                    PenCross()
                        .stroke(DS.Colors.redPen, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .padding(2)
                }
            }
            .frame(width: 26, height: 22)
            .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(isCorrect ? AL.s(.quizCorrectBang) : AL.s(.quizNotQuite))
                    .font(DS.Font.display(20, weight: .bold).italic())
                    .foregroundStyle(isCorrect ? DS.Colors.success : DS.Colors.redPen)
                if !isCorrect {
                    Text(AL.f(.quizAnswerFmt, correctAnswer))
                        .font(DS.Font.display(18, weight: .medium))
                        .foregroundStyle(DS.Colors.ink)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(isCorrect ? DS.Colors.successSoft : DS.Colors.note,
                    in: RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .leading) {
            // Yanlışta öğretmenin kırmızı kalem kenar çizgisi
            if !isCorrect {
                Rectangle().fill(DS.Colors.redPen).frame(width: 2.5).padding(.vertical, 10)
            }
        }
    }
}
