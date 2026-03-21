//
//  InteractiveSentenceView.swift
//  WordRemSwiftUI
//
//  Created by AI Assistant on 14.03.2026.
//

import SwiftUI

struct InteractiveSentenceView: View {
    
    let sentence: String
    let highlightedWord: String
    let targetLanguageCode: String // Language of the sentence (FR, ES, etc.)
    let nativeLanguageCode: String // User's native language (TR, EN, etc.)
    
    @StateObject private var viewModel = SentencePlayerViewModel()
    
    var body: some View {
        VStack(spacing: 8) {
            // Play button & Sentence
            HStack(alignment: .top, spacing: 12) {
                // Speaker button
                Button {
                    viewModel.speak(text: sentence, languageCode: targetLanguageCode)
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                viewModel.isPlaying
                                ? AppTheme.Colors.primaryOrange
                                : AppTheme.Colors.primaryOrange.opacity(0.15)
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: viewModel.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(
                                viewModel.isPlaying
                                ? .white
                                : AppTheme.Colors.primaryOrange
                            )
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.isPlaying)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Original sentence with translate button
                    HStack(alignment: .top, spacing: 8) {
                        AlignedSentenceText(
                            sentence: sentence,
                            highlightedWord: highlightedWord,
                            translatedSentence: viewModel.translatedSentence,
                            wordAlignments: viewModel.wordAlignments,
                            isOriginal: true
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Translate button
                        if !viewModel.showTranslation {
                            Button {
                                Task {
                                    await viewModel.translateSentence(
                                        sentence,
                                        fromLang: targetLanguageCode,
                                        toLang: nativeLanguageCode
                                    )
                                }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                            }
                        }
                    }
                    
                    // Translated sentence (if shown)
                    if viewModel.showTranslation {
                        if viewModel.isLoadingTranslation {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(AppTheme.Colors.primaryOrange)
                                    .scaleEffect(0.8)
                                Text("Translating...")
                                    .font(.custom("Feather-Bold", size: 12))
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            .padding(.leading, 4)
                        } else if let translated = viewModel.translatedSentence {
                            HStack(alignment: .top, spacing: 8) {
                                AlignedSentenceText(
                                    sentence: translated,
                                    highlightedWord: "",  // No highlight in translated
                                    translatedSentence: sentence,
                                    wordAlignments: viewModel.wordAlignments,
                                    isOriginal: false
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Hide button
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.hideTranslation()
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Aligned Sentence Text with Color Matching
private struct AlignedSentenceText: View {
    let sentence: String
    let highlightedWord: String
    let translatedSentence: String?
    let wordAlignments: [String: (translation: String, colorIndex: Int)]
    let isOriginal: Bool
    
    var body: some View {
        let words = sentence.split(separator: " ")
        
        FlowLayout(spacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { item in
                WordView(
                    word: String(item.element),
                    highlightedWord: highlightedWord,
                    wordAlignments: wordAlignments
                )
            }
        }
    }
    
    // MARK: - Word View Component
    private struct WordView: View {
        let word: String
        let highlightedWord: String
        let wordAlignments: [String: (translation: String, colorIndex: Int)]
        
        @State private var showMeaning = false
        @State private var wordMeaning: String = ""
        
        var body: some View {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
                .lowercased()
            
            // Check if this is the highlighted word
            let isHighlighted = cleanWord.contains(highlightedWord.lowercased())
            
            Button {
                if !isHighlighted && !cleanWord.isEmpty {
                    // Get meaning from alignments
                    print("🔍 Tapped word: '\(cleanWord)'")
                    print("📚 Available alignments: \(wordAlignments.keys.sorted())")
                    
                    // Try exact match first
                    if let alignment = wordAlignments[cleanWord] {
                        wordMeaning = alignment.translation
                        print("✅ Found exact meaning: \(wordMeaning)")
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showMeaning.toggle()
                        }
                    } else {
                        // Try prefix matching (for conjugated words)
                        var found = false
                        for (key, value) in wordAlignments {
                            if cleanWord.hasPrefix(key) || key.hasPrefix(cleanWord) {
                                wordMeaning = value.translation
                                print("✅ Found prefix meaning: \(wordMeaning)")
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showMeaning.toggle()
                                }
                                found = true
                                break
                            }
                        }
                        if !found {
                            print("❌ No alignment found for '\(cleanWord)'")
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(word)
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(
                            isHighlighted
                            ? AppTheme.Colors.primaryOrange
                            : AppTheme.Colors.textSecondary
                        )
                        .fontWeight(isHighlighted ? .semibold : .regular)
                        .padding(.horizontal, isHighlighted ? 6 : 2)
                        .padding(.vertical, isHighlighted ? 3 : 0)
                        .background(
                            isHighlighted
                            ? AppTheme.Colors.primaryOrange.opacity(0.15)
                            : Color.clear
                        )
                        .cornerRadius(6)
                        .fixedSize()
                    
                    // Show meaning below word
                    if showMeaning && !wordMeaning.isEmpty {
                        Text(wordMeaning)
                            .font(.custom("Feather-Bold", size: 10))
                            .foregroundStyle(AppTheme.Colors.primaryOrange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.primaryOrange.opacity(0.1))
                            .cornerRadius(4)
                            .transition(.scale.combined(with: .opacity))
                            .fixedSize()
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Flow Layout (Wrap Layout)
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

struct InteractiveSentenceView_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveSentenceView(
            sentence: "Mon cousin habite à Paris.",
            highlightedWord: "cousin",
            targetLanguageCode: "FR",
            nativeLanguageCode: "TR"
        )
        .padding()
    }
}
