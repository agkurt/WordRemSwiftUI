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
            // Dinle düğmesi & cümle
            HStack(alignment: .top, spacing: 12) {
                // Dinle: kâğıt üstünde mürekkep halka; çalarken imza rengiyle dolar
                Button {
                    viewModel.speak(text: sentence, languageCode: targetLanguageCode)
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isPlaying ? DS.Colors.accent : DS.Colors.paperRaised)
                        Circle()
                            .strokeBorder(viewModel.isPlaying ? DS.Colors.accent : DS.Colors.line, lineWidth: 1)

                        Image(systemName: viewModel.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(viewModel.isPlaying ? DS.Colors.paperRaised : DS.Colors.inkSoft)
                    }
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isPlaying)

                VStack(alignment: .leading, spacing: 8) {
                    // Asıl cümle; aranan kelime fosforlu kalemle
                    AlignedSentenceText(
                        sentence: sentence,
                        highlightedWord: highlightedWord,
                        translatedSentence: viewModel.translatedSentence,
                        wordAlignments: viewModel.wordAlignments,
                        isOriginal: true
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)

                    // Çeviri bağlantısı: altı çizili küçük terrakota yazı
                    if !viewModel.showTranslation && AIEngine.isAvailable {
                        Button {
                            Task {
                                await viewModel.translateSentence(
                                    sentence,
                                    fromLang: targetLanguageCode,
                                    toLang: nativeLanguageCode
                                )
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(PageText.translation)
                                    .font(DS.Font.ui(13, weight: .semibold))
                                    .underline(true, color: DS.Colors.accent.opacity(0.5))
                            }
                            .foregroundStyle(DS.Colors.accentText)
                            .frame(minHeight: 28)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Çeviri (gösteriliyorsa): kenara kurşun kalemle yazılmış not gibi
                    if viewModel.showTranslation {
                        if viewModel.isLoadingTranslation {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(DS.Colors.muted)
                                    .scaleEffect(0.8)
                                Text(AL.s(.cardTranslating))
                                    .font(DS.Font.ui(12, weight: .semibold))
                                    .foregroundStyle(DS.Colors.muted)
                            }
                        } else if let translated = viewModel.translatedSentence {
                            HStack(alignment: .top, spacing: 8) {
                                AlignedSentenceText(
                                    sentence: translated,
                                    highlightedWord: "",  // Çeviride vurgu yok
                                    translatedSentence: sentence,
                                    wordAlignments: viewModel.wordAlignments,
                                    isOriginal: false
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                                .overlay(alignment: .leading) {
                                    Rectangle().fill(DS.Colors.margin).frame(width: 1.5)
                                }

                                // Gizle
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.hideTranslation()
                                    }
                                } label: {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(DS.Colors.muted)
                                        .frame(width: 28, height: 28)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
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
        
        FlowLayout(spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.offset) { item in
                WordView(
                    word: String(item.element),
                    highlightedWord: highlightedWord,
                    wordAlignments: wordAlignments,
                    isOriginal: isOriginal
                )
            }
        }
    }
    
    // MARK: - Word View Component
    private struct WordView: View {
        let word: String
        let highlightedWord: String
        let wordAlignments: [String: (translation: String, colorIndex: Int)]
        var isOriginal: Bool = true

        var body: some View {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
            let isHighlighted = !highlightedWord.isEmpty &&
                cleanWord.contains(highlightedWord.lowercased())

            Text(word)
                .font(DS.Font.display(16, weight: isHighlighted ? .semibold : .regular))
                .italic(!isOriginal)
                .foregroundStyle(
                    isHighlighted
                    ? DS.Colors.ink
                    : (isOriginal ? DS.Colors.inkSoft : DS.Colors.muted)
                )
                .padding(.horizontal, 2)
                // Fosforlu kalem: köşesiz, satırın alt yarısına daha çok taşar
                .background {
                    if isHighlighted {
                        DS.Colors.highlight.padding(.top, 3).padding(.horizontal, -1)
                    }
                }
                .fixedSize()
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
