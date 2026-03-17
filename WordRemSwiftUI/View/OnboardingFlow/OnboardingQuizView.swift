//
//  OnboardingQuizView.swift
//  WordRemSwiftUI
//
//  Step 4 of Duolingo-style Onboarding.
//  A mini mock quiz to simulate the app's functionality.
//

import SwiftUI

struct OnboardingQuizView: View {
    let languageName: String
    @State private var navigateToPlan = false
    
    // Mock Data
    let questionText = "Aşağıdaki cümleyi çevir:"
    
    var foreignSentence: String {
        switch languageName {
        case "İngilizce", "English": return "I love learning languages."
        case "Almanca", "German": return "Ich liebe es, Sprachen zu lernen."
        case "İspanyolca", "Spanish": return "Me encanta aprender idiomas."
        case "Fransızca", "French": return "J'adore apprendre des langues."
        default: return "Il loro video è fantastico." // Default to italian mock
        }
    }
    
    var correctWords: [String] {
        switch languageName {
        case "İngilizce", "English", "Almanca", "German", "İspanyolca", "Spanish", "Fransızca", "French":
            return ["Dil", "öğrenmeyi", "seviyorum"]
        default:
            return ["Onların", "videosu", "harika"]
        }
    }
    
    @State private var availableWords: [String]
    @State private var selectedWords: [String] = []
    
    init(languageName: String) {
        self.languageName = languageName
        
        var initialWords: [String]
        switch languageName {
        case "İngilizce", "English", "Almanca", "German", "İspanyolca", "Spanish", "Fransızca", "French":
            initialWords = ["Dil", "olmak", "öğrenmeyi", "seviyorum", "Nasılsın", "zaman", "Harika"]
        default:
            initialWords = ["harika", "iyisi", "Onların", "renk", "Şarkıcıyı", "videosu", "olmak"]
        }
        
        self._availableWords = State(initialValue: initialWords.shuffled())
    }
    
    @State private var checkStatus: QuizValidationStatus = .idle
    
    enum QuizValidationStatus {
        case idle, correct, wrong
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
                Text(questionText)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1e293b"))
                
                HStack(spacing: 16) {
                    // Speaker Button
                    Button(action: {
                        // Play sound mock
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.blue)
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    
                    Text(foreignSentence)
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundStyle(Color(hex: "#1e293b"))
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
                            Text("Harika!")
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
                            Text("Yanlış Cevap")
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundStyle(Color.red)
                            Text("Doğrusu: \(correctWords.joined(separator: " "))")
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
                    Text(checkStatus == .idle ? "KONTROL ET" : "DEVAM ET")
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
        .navigationDestination(isPresented: $navigateToPlan) {
            PlanSelectionView(languageName: languageName)
        }
    }
    
    private var buttonColor: Color {
        if checkStatus == .correct { return Color(hex: "#22c55e") } // Green
        if checkStatus == .wrong { return Color(hex: "#ef4444") } // Red
        if selectedWords.isEmpty { return Color(hex: "#e2e8f0") }
        return AppTheme.Colors.primaryOrange
    }
    
    private func validateAnswer() {
        if selectedWords == correctWords {
            withAnimation {
                checkStatus = .correct
            }
        } else {
            withAnimation {
                checkStatus = .wrong
            }
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
