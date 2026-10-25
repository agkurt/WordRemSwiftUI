//
//  OnboardingQuizView.swift
//  WordRemSwiftUI
//
//  Step 4 of Duolingo-style Onboarding.
//  A mini mock quiz to simulate the app's functionality.
//

import SwiftUI
import AVFoundation

struct OnboardingQuizView: View {
    @EnvironmentObject var langManager: LanguageManager
    let languageName: String
    let languageCode: String
    let proficiencyLevel: Int
    var learningInterest: String = ""
    var dailyGoalMinutes: Int = 10
    var nativeLangCode: String = OL.nativeLangCode   // NativeLanguageSelectionView'dan gelir
    @State private var navigateToPlan = false
    @State private var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    // Mock Data
    let questionText = "Aşağıdaki cümleyi çevir:"

    // Her dil için cümle — seçilen dile göre, her zaman
    var foreignSentence: String {
        switch languageCode.lowercased() {
        case "en":  return "I love learning languages."
        case "de":  return "Ich liebe es, Sprachen zu lernen."
        case "es":  return "Me encanta aprender idiomas."
        case "fr":  return "J'adore apprendre des langues."
        case "it":  return "Adoro imparare le lingue."
        case "ru":  return "Я люблю изучать языки."
        case "zh":  return "我喜欢学习语言。"
        default:    return "I love learning languages."
        }
    }

    // Telefon diline göre doğru cevap
    var correctWords: [String] { langManager.quizCorrectWords }

    // Ses için dil kodu — seçilen dil kodu üzerinden
    var voiceLanguageCode: String {
        switch languageCode.lowercased() {
        case "en":  return "en-US"
        case "de":  return "de-DE"
        case "es":  return "es-ES"
        case "fr":  return "fr-FR"
        case "it":  return "it-IT"
        case "ru":  return "ru-RU"
        case "zh":  return "zh-CN"
        default:    return "en-US"
        }
    }

    @State private var availableWords: [String]
    @State private var selectedWords: [String] = []

    init(languageName: String, languageCode: String = "en", proficiencyLevel: Int = 0,
         learningInterest: String = "", dailyGoalMinutes: Int = 10, nativeLangCode: String = OL.nativeLangCode) {
        self.languageName = languageName
        self.languageCode = languageCode
        self.proficiencyLevel = proficiencyLevel
        self.learningInterest = learningInterest
        self.dailyGoalMinutes = dailyGoalMinutes
        self.nativeLangCode = nativeLangCode
        let initialWords = OL.quizCorrectWords + OL.quizDecoyWords
        self._availableWords = State(initialValue: initialWords.shuffled())
    }
    
    @State private var checkStatus: QuizValidationStatus = .idle
    @State private var tappedWordIdx: Int? = nil  // tooltip için tıklanan kelime indexi

    enum QuizValidationStatus {
        case idle, correct, wrong
    }

    /// Kelime → çeviri eşleşmesi — seçilen dil kodu + kullanıcının anadili
    private var sentenceWordMeanings: [String: String] {
        // Anadil == öğrenilen dil → aynı dili "çevirmenin" anlamı yok, tooltip gösterme
        if nativeLangCode.lowercased() == languageCode.lowercased() { return [:] }

        let phone = nativeLangCode  // "tr", "en", "de" ...
        // Anadil Türkçe ise Türkçe çeviri, değilse İngilizce çeviri
        let isTR = phone == "tr"
        switch languageCode.lowercased() {
        case "en":
            return isTR
                ? ["I": "Ben", "love": "seviyorum", "learning": "öğrenmeyi", "languages": "dilleri"]
                : ["I": "I", "love": "love", "learning": "learning", "languages": "languages"]
        case "fr":
            return isTR
                ? ["J'adore": "Seviyorum", "apprendre": "öğrenmeyi", "des": "-", "langues": "dilleri"]
                : ["J'adore": "I love", "apprendre": "to learn", "des": "some", "langues": "languages"]
        case "de":
            return isTR
                ? ["Ich": "Ben", "liebe": "seviyorum", "Sprachen": "dilleri", "lernen": "öğrenmeyi"]
                : ["Ich": "I", "liebe": "love", "Sprachen": "languages", "lernen": "to learn"]
        case "es":
            return isTR
                ? ["Me": "Ben", "encanta": "seviyorum", "aprender": "öğrenmeyi", "idiomas": "dilleri"]
                : ["Me": "I", "encanta": "love", "aprender": "to learn", "idiomas": "languages"]
        case "it":
            return isTR
                ? ["Adoro": "Seviyorum", "imparare": "öğrenmeyi", "le": "-", "lingue": "dilleri"]
                : ["Adoro": "I love", "imparare": "to learn", "le": "the", "lingue": "languages"]
        case "ru":
            return isTR
                ? ["Я": "Ben", "люблю": "seviyorum", "изучать": "öğrenmeyi", "языки": "dilleri"]
                : ["Я": "I", "люблю": "love", "изучать": "to learn", "языки": "languages"]
        default:
            return [:]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            OBProgressBar(total: 4, filled: 4)

            // Question Section
            VStack(alignment: .leading, spacing: 20) {
                Text(langManager.s(.quizInstruction))
                    .font(DS.Font.display(28, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)

                // Sentence card
                HStack(alignment: .top, spacing: 14) {
                    // Speaker button
                    Button(action: { speakSentence() }) {
                        Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isSpeaking ? DS.Colors.paperRaised : DS.Colors.ink)
                            .frame(width: 40, height: 40)
                            .background(
                                isSpeaking ? DS.Colors.ink : DS.Colors.paperSunken,
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: isSpeaking)

                    VStack(alignment: .leading, spacing: 12) {
                        let words = foreignSentence.components(separatedBy: " ").filter { !$0.isEmpty }
                        OBFlowLayout(spacing: 6) {
                            ForEach(Array(words.enumerated()), id: \.offset) { idx, word in
                                let clean = word.trimmingCharacters(in: .punctuationCharacters)
                                let hasMeaning = sentenceWordMeanings[clean] != nil
                                let isTapped = tappedWordIdx == idx
                                let textColor: Color = isTapped ? DS.Colors.accentDeep : DS.Colors.ink
                                let bgColor: Color = (hasMeaning && isTapped) ? DS.Colors.accentSoft : .clear

                                Text(word)
                                    .font(DS.Font.display(24, weight: .medium))
                                    .foregroundStyle(textColor)
                                    .padding(.horizontal, hasMeaning ? 4 : 0)
                                    .padding(.vertical, hasMeaning ? 1 : 0)
                                    .background(bgColor, in: RoundedRectangle(cornerRadius: 5))
                                    .underline(hasMeaning, pattern: .dot, color: DS.Colors.muted)
                                    .onTapGesture {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            tappedWordIdx = tappedWordIdx == idx ? nil : idx
                                        }
                                        // Tıklanan kelimeyi seslendir
                                        let utterance = AVSpeechUtterance(string: clean)
                                        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguageCode)
                                        utterance.rate = 0.4
                                        synthesizer.speak(utterance)
                                    }
                            }
                        }

                        // Tooltip (tıklanan kelimenin çevirisi)
                        if let idx = tappedWordIdx,
                           idx < words.count {
                            let clean = words[idx].trimmingCharacters(in: .punctuationCharacters)
                            if let meaning = sentenceWordMeanings[clean] {
                                HStack(spacing: 8) {
                                    Text(clean)
                                        .font(DS.Font.ui(14, weight: .semibold))
                                        .foregroundStyle(DS.Colors.accentDeep)
                                    Text("=")
                                        .font(DS.Font.ui(14))
                                        .foregroundStyle(DS.Colors.muted)
                                    Text(meaning)
                                        .font(DS.Font.ui(14, weight: .medium))
                                        .foregroundStyle(DS.Colors.ink)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(DS.Colors.line, lineWidth: 1)
                                )
                                .transition(.opacity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
                .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DS.Colors.line, lineWidth: 1)
                )
                .animation(.easeOut(duration: 0.2), value: tappedWordIdx)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .obContentWidth()

            // Answer Drop Zone
            VStack(alignment: .leading) {
                if selectedWords.isEmpty {
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                            .padding(.bottom, 44)
                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                    }
                    .frame(height: 100)
                } else {
                    OBFlowLayout(spacing: 10) {
                        ForEach(selectedWords, id: \.self) { word in
                            WordBubble(word: word)
                                .onTapGesture {
                                    withAnimation {
                                        selectedWords.removeAll(where: { $0 == word })
                                        availableWords.append(word)
                                        checkStatus = .idle
                                    }
                                }
                        }
                    }
                    .frame(height: 100, alignment: .topLeading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .obContentWidth()

            Spacer()

            // Available Words Zone
            OBFlowLayout(spacing: 10) {
                ForEach(availableWords.sorted(), id: \.self) { word in
                    WordBubble(word: word)
                        .onTapGesture {
                            withAnimation {
                                availableWords.removeAll(where: { $0 == word })
                                selectedWords.append(word)
                                checkStatus = .idle
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .obContentWidth()

            // Bottom Check Button
            VStack(spacing: 0) {
                if checkStatus == .correct {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DS.Colors.success)
                        Text(langManager.s(.quizCorrect))
                            .font(DS.Font.display(20, weight: .bold))
                            .foregroundStyle(DS.Colors.success)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .obContentWidth()
                } else if checkStatus == .wrong {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DS.Colors.danger)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(langManager.s(.quizWrong))
                                .font(DS.Font.display(20, weight: .bold))
                                .foregroundStyle(DS.Colors.danger)
                            Text(langManager.f(.quizCorrectAnswer, correctWords.joined(separator: " ")))
                                .font(DS.Font.ui(15, weight: .medium))
                                .foregroundStyle(DS.Colors.danger)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .obContentWidth()
                } else {
                    Rectangle()
                        .fill(DS.Colors.line)
                        .frame(height: 1)
                }

                Button(action: {
                    if checkStatus == .correct || checkStatus == .wrong {
                        navigateToPlan = true
                    } else {
                        validateAnswer()
                    }
                }) {
                    Text(checkStatus == .idle ? langManager.s(.quizCheck) : langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle(fill: buttonColor))
                .obDisabled(selectedWords.isEmpty && checkStatus == .idle)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .obContentWidth()
            }
            .background(
                (checkStatus == .correct ? DS.Colors.successSoft
                 : (checkStatus == .wrong ? DS.Colors.dangerSoft : DS.Colors.paper))
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
        .navigationDestination(isPresented: $navigateToPlan) {
            PlanSelectionView(
                languageName: languageName,
                languageCode: languageCode,
                proficiencyLevel: proficiencyLevel,
                learningInterest: learningInterest,
                dailyGoalMinutes: dailyGoalMinutes,
                nativeLangCode: nativeLangCode
            )
        }
    }
    
    private func speakSentence() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        let utterance = AVSpeechUtterance(string: foreignSentence)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguageCode)
        utterance.rate = 0.45
        utterance.volume = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
        // Konuşma bitince isSpeaking'i sıfırla
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(foreignSentence.count) * 0.08 + 1.0) {
            isSpeaking = false
        }
    }

    private var buttonColor: Color {
        if checkStatus == .correct { return DS.Colors.success }
        if checkStatus == .wrong { return DS.Colors.danger }
        return DS.Colors.ink
    }
    
    private func validateAnswer() {
        tappedWordIdx = nil  // tooltip'i kapat
        if selectedWords == correctWords {
            withAnimation { checkStatus = .correct }
        } else {
            withAnimation { checkStatus = .wrong }
        }
    }
}

// Simple Bubble
struct WordBubble: View {
    let word: String
    var body: some View {
        Text(word)
            .font(DS.Font.ui(17, weight: .medium))
            .foregroundStyle(DS.Colors.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DS.Colors.line, lineWidth: 1)
            )
    }
}

// Basic Flow Layout implementation for SwiftUI
struct OBFlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    OnboardingQuizView(languageName: "İngilizce")
}
