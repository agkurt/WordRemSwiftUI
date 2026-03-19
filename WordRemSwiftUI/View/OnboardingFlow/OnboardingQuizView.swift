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
    let languageName: String
    let languageCode: String
    let proficiencyLevel: Int
    @State private var navigateToPlan = false
    @State private var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    // Mock Data
    let questionText = "Aşağıdaki cümleyi çevir:"

    // Her dil için cümle — hepsi "Dil öğrenmeyi seviyorum" anlamında
    var foreignSentence: String {
        switch effectiveLanguageName {
        case "İngilizce", "English":   return "I love learning languages."
        case "Almanca", "German":      return "Ich liebe es, Sprachen zu lernen."
        case "İspanyolca", "Spanish":  return "Me encanta aprender idiomas."
        case "Fransızca", "French":    return "J'adore apprendre des langues."
        case "İtalyanca", "Italian":   return "Adoro imparare le lingue."
        case "Rusça", "Russian":       return "Я люблю изучать языки."
        case "Çince", "Chinese":       return "我喜欢学习语言。"
        default:                       return "J'adore apprendre des langues."
        }
    }

    // Telefon diline göre doğru cevap
    var correctWords: [String] { OL.quizCorrectWords }

    // Ses için dil kodu
    var voiceLanguageCode: String {
        switch effectiveLanguageName {
        case "İngilizce", "English":   return "en-US"
        case "Almanca", "German":      return "de-DE"
        case "İspanyolca", "Spanish":  return "es-ES"
        case "Fransızca", "French":    return "fr-FR"
        case "İtalyanca", "Italian":   return "it-IT"
        case "Rusça", "Russian":       return "ru-RU"
        case "Çince", "Chinese":       return "zh-CN"
        default:                       return "fr-FR"
        }
    }

    @State private var availableWords: [String]
    @State private var selectedWords: [String] = []

    init(languageName: String, languageCode: String = "en", proficiencyLevel: Int = 0) {
        self.languageName = languageName
        self.languageCode = languageCode
        self.proficiencyLevel = proficiencyLevel
        let initialWords = OL.quizCorrectWords + OL.quizDecoyWords
        self._availableWords = State(initialValue: initialWords.shuffled())
    }
    
    /// True when user is learning the same language as their phone language (e.g. English phone + English target).
    /// In this edge case we show French as the demo foreign language to avoid showing an identical Q&A.
    private var targetMatchesNative: Bool {
        let phone = OL.phoneCode.lowercased()
        let target = languageCode.lowercased()
        return target.hasPrefix(phone) || phone.hasPrefix(target)
    }

    /// Effective language name used for sentence & TTS — falls back to French when target == native.
    private var effectiveLanguageName: String {
        targetMatchesNative ? "Fransızca" : languageName
    }

    @State private var checkStatus: QuizValidationStatus = .idle
    @State private var tappedWordIdx: Int? = nil  // tooltip için tıklanan kelime indexi

    enum QuizValidationStatus {
        case idle, correct, wrong
    }

    /// Kelime → çeviri eşleşmesi (demo cümle için sabit).
    /// OL.phoneCode'a göre native dil seçilir.
    private var sentenceWordMeanings: [String: String] {
        let phone = OL.phoneCode.uppercased()
        switch effectiveLanguageName {
        case "Fransızca", "French":
            if phone == "EN" {
                return ["J'adore": "I love", "apprendre": "to learn", "des": "some", "langues": "languages"]
            }
            return ["J'adore": "Seviyorum", "apprendre": "öğrenmeyi", "des": "-", "langues": "dilleri"]
        case "Rusça", "Russian":
            if phone == "EN" {
                return ["Я": "I", "люблю": "love", "изучать": "to learn", "языки": "languages"]
            }
            return ["Я": "Ben", "люблю": "seviyorum", "изучать": "öğrenmeyi", "языки": "dilleri"]
        case "Almanca", "German":
            if phone == "EN" {
                return ["Ich": "I", "liebe": "love", "Sprachen": "languages", "lernen": "to learn"]
            }
            return ["Ich": "Ben", "liebe": "seviyorum", "Sprachen": "dilleri", "lernen": "öğrenmeyi"]
        case "İspanyolca", "Spanish":
            if phone == "EN" {
                return ["Me": "I", "encanta": "love", "aprender": "to learn", "idiomas": "languages"]
            }
            return ["Me": "Ben", "encanta": "seviyorum", "aprender": "öğrenmeyi", "idiomas": "dilleri"]
        default:
            if phone == "EN" {
                return ["I": "Ben", "love": "seviyorum", "learning": "öğrenmeyi", "languages": "dilleri"]
            }
            return ["I": "I", "love": "love", "learning": "learning", "languages": "languages"]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(AppTheme.Colors.primaryOrange)
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Question Section
            VStack(alignment: .leading, spacing: 24) {
                Text(OL.s(.quizInstruction))
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1e293b"))
                
                HStack(alignment: .bottom, spacing: 0) {
                    // Maskot (sol — Duolingo tarzı)
                    MascotAnimationView(width: 90, height: 90)
                        .offset(y: 8)

                    // Speech bubble (sağ)
                    VStack(alignment: .leading, spacing: 8) {
                        // Speaker button (bubble içinde)
                        HStack {
                            Button(action: { speakSentence() }) {
                                Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(isSpeaking ? .white : Color.blue)
                                    .padding(8)
                                    .background(
                                        isSpeaking ? Color.blue : Color.blue.opacity(0.1),
                                        in: Circle()
                                    )
                            }
                            .animation(.easeInOut(duration: 0.2), value: isSpeaking)
                            Spacer()
                        }
                        let words = foreignSentence.components(separatedBy: " ").filter { !$0.isEmpty }
                        OBFlowLayout(spacing: 8) {
                            ForEach(Array(words.enumerated()), id: \.offset) { idx, word in
                                let clean = word.trimmingCharacters(in: .punctuationCharacters)
                                let hasMeaning = sentenceWordMeanings[clean] != nil

                                Text(word)
                                    .font(.custom("Poppins-Regular", size: 18))
                                    .foregroundStyle(tappedWordIdx == idx
                                        ? Color.blue
                                        : Color(hex: "#1e293b"))
                                    .padding(.horizontal, hasMeaning ? 6 : 0)
                                    .padding(.vertical, hasMeaning ? 2 : 0)
                                    .background(
                                        hasMeaning
                                        ? (tappedWordIdx == idx ? Color.blue.opacity(0.12) : Color.blue.opacity(0.06))
                                        : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 5)
                                    )
                                    .underline(hasMeaning, color: Color.blue.opacity(0.4))
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.25)) {
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
                                        .font(.custom("Poppins-SemiBold", size: 13))
                                        .foregroundStyle(Color.blue)
                                    Text("=")
                                        .foregroundStyle(Color(hex: "#94a3b8"))
                                    Text(meaning)
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundStyle(Color(hex: "#1e293b"))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(hex: "#f0f9ff"), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                                )
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#e2e8f0"), lineWidth: 1.5)
                    )
                    // Speech bubble tail
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#e2e8f0"))
                            .rotationEffect(.degrees(-90))
                            .offset(x: -7, y: -14)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                    .animation(.spring(response: 0.3), value: tappedWordIdx)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            // Answer Drop Zone
            VStack(alignment: .leading) {
                Divider().opacity(0)
                
                // Wrap view for selected words (simple layout for mock)
                if selectedWords.isEmpty {
                    VStack {
                        Spacer()
                        Divider()
                            .padding(.vertical, 8)
                        Divider()
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
            .padding(.top, 40)
            
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
            
            // Bottom Check Button
            VStack(spacing: 0) {
                if checkStatus == .correct {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(OL.s(.quizCorrect))
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundStyle(Color.green)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.1))
                } else if checkStatus == .wrong {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(OL.s(.quizWrong))
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundStyle(Color.red)
                            Text(OL.f(.quizCorrectAnswer, correctWords.joined(separator: " ")))
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundStyle(Color.red.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.1))
                } else {
                    Divider()
                }
                
                Button(action: {
                    if checkStatus == .correct || checkStatus == .wrong {
                        navigateToPlan = true
                    } else {
                        validateAnswer()
                    }
                }) {
                    Text(checkStatus == .idle ? OL.s(.quizCheck) : OL.s(.continueButton))
                        .font(.custom("Poppins-Bold", size: 17))
                        .foregroundStyle(selectedWords.isEmpty && checkStatus == .idle ? Color(hex: "#94a3b8") : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(buttonColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: (selectedWords.isEmpty && checkStatus == .idle) ? .clear : buttonColor.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(selectedWords.isEmpty && checkStatus == .idle)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .background(checkStatus == .correct ? Color.green.opacity(0.1) : (checkStatus == .wrong ? Color.red.opacity(0.1) : Color.white))
            }
        }
        .background(Color(hex: "#f8fafc").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
        .navigationDestination(isPresented: $navigateToPlan) {
            PlanSelectionView(
                languageName: languageName,
                languageCode: languageCode,
                proficiencyLevel: proficiencyLevel
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
        if checkStatus == .correct { return Color(hex: "#22c55e") } // Green
        if checkStatus == .wrong { return Color(hex: "#ef4444") } // Red
        if selectedWords.isEmpty { return Color(hex: "#e2e8f0") }
        return AppTheme.Colors.primaryOrange
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
            .font(.custom("Poppins-Regular", size: 16))
            .foregroundStyle(Color(hex: "#1e293b"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#cbd5e1"), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
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
