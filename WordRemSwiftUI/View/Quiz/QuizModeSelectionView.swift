//
//  QuizModeSelectionView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct QuizModeSelectionView: View {

    let wordInfos: [WordInfo]
    let cardId: String
    let cardName: String

    @State private var selectedMode: QuizMode? = nil
    @State private var showQuiz = false
    @State private var targetLang: String = "EN"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Başlık: kenar boşluğunun sağında, sayfa başlığı gibi
                        VStack(alignment: .leading, spacing: 0) {
                            Eyebrow(text: AL.f(.quizWordsCount, wordInfos.count), color: DS.Colors.accentText)
                            Text(AL.s(.quizModeTitle))
                                .font(DS.Font.display(34, weight: .bold))
                                .foregroundStyle(DS.Colors.ink)
                                .padding(.top, 6)
                            Text(cardName)
                                .font(.system(size: 17, design: .serif).italic())
                                .foregroundStyle(DS.Colors.inkSoft)
                                .padding(.top, 4)
                        }
                        .padding(.leading, DS.Page.textX)
                        .padding(.trailing, 24)

                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                            .padding(.top, 20)

                        // Mod satırları: numaralı defter satırları, seçili olana kenarda kalem tiki
                        ForEach(Array(QuizMode.deckModes.enumerated()), id: \.element) { index, mode in
                            QuizModeRow(
                                mode: mode,
                                number: index + 1,
                                isSelected: selectedMode == mode,
                                isAvailable: wordInfos.count >= mode.minimumWordCount
                            ) {
                                if wordInfos.count >= mode.minimumWordCount {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        selectedMode = mode
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                // Kenar boşluğu çizgisi yalnızca sayfada, alttaki düğmenin arkasından geçmez;
                // seçili satırın not zemininin üstünde kalsın diye overlay
                .overlay { MarginLine().allowsHitTesting(false) }

                // Start Button
                Button {
                    showQuiz = true
                } label: {
                    Label(AL.s(.quizStart), systemImage: "play.fill")
                }
                .buttonStyle(InkButtonStyle(fill: selectedMode != nil ? DS.Colors.ink : DS.Colors.line,
                                            foreground: selectedMode != nil ? DS.Colors.paperRaised : DS.Colors.muted))
                .disabled(selectedMode == nil)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .animation(.easeOut(duration: 0.15), value: selectedMode)
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .ruledPage(margin: false)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                }
            }
            .fullScreenCover(isPresented: $showQuiz) {
                if let mode = selectedMode {
                    QuizSessionView(
                        wordInfos: wordInfos,
                        mode: mode,
                        cardId: cardId,
                        cardName: cardName,
                        targetLang: targetLang
                    )
                }
            }
            .task {
                if let cards = try? await DeckService.shared.fetchSourceAndTargetLang(cardId: cardId),
                   let lang = cards.first?.targetLang {
                    targetLang = lang
                }
            }
        }
    }
}

// MARK: - Mode Row

/// Defter satırı: kenar boşluğunda sıra numarası (seçilince kalem tiki), sağda mod adı ve açıklaması
private struct QuizModeRow: View {
    let mode: QuizMode
    let number: Int
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.title)
                        .font(DS.Font.display(20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(DS.Colors.ink)
                    Text(mode.description)
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if !isAvailable {
                        Text(AL.f(.quizNeedsWords, mode.minimumWordCount))
                            .font(.system(size: 13, design: .serif).italic())
                            .foregroundStyle(DS.Colors.accentText)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, DS.Page.textX)
            .padding(.trailing, 24)
            .padding(.vertical, 14)
            .frame(minHeight: DS.Page.pitch * 2)
            .background(isSelected ? DS.Colors.note : .clear)
            .overlay(alignment: .leading) {
                ZStack {
                    // Kenardaki sıra numarası; seçilince yerini kalem tiki alır
                    Text("\(number)")
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .opacity(isSelected ? 0 : 1)
                    PenTick()
                        .trim(from: 0, to: isSelected ? 1 : 0)
                        .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                .frame(width: 28, height: 24)
                .padding(.leading, 22)
                .animation(.easeOut(duration: 0.25), value: isSelected)
            }
            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isAvailable ? 1.0 : 0.5)
        .disabled(!isAvailable)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}
