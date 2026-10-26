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
                        // Header
                        Eyebrow(text: AL.f(.quizWordsCount, wordInfos.count))
                        Text(AL.s(.quizModeTitle))
                            .font(DS.Font.display(34, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .padding(.top, 6)
                        Text(cardName)
                            .font(DS.Font.ui(16))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .padding(.top, 4)

                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                            .padding(.top, 20)

                        // Mode rows
                        ForEach(QuizMode.deckModes) { mode in
                            QuizModeRow(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                isAvailable: wordInfos.count >= mode.minimumWordCount
                            ) {
                                if wordInfos.count >= mode.minimumWordCount {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        selectedMode = mode
                                    }
                                }
                            }
                            Rectangle().fill(DS.Colors.line).frame(height: 1)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

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
                .padding(.bottom, 24)
                .animation(.easeOut(duration: 0.15), value: selectedMode)
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .paperBackground()
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

private struct QuizModeRow: View {
    let mode: QuizMode
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? DS.Colors.paperRaised : DS.Colors.inkSoft)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? DS.Colors.ink : DS.Colors.paperRaised, in: Circle())
                    .overlay(Circle().stroke(isSelected ? DS.Colors.ink : DS.Colors.line, lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.title)
                        .font(DS.Font.display(20))
                        .foregroundStyle(DS.Colors.ink)
                    Text(mode.description)
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .multilineTextAlignment(.leading)
                    if !isAvailable {
                        Text(AL.f(.quizNeedsWords, mode.minimumWordCount))
                            .font(DS.Font.ui(12, weight: .semibold))
                            .foregroundStyle(DS.Colors.accent)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? DS.Colors.ink : DS.Colors.line)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isAvailable ? 1.0 : 0.5)
        .disabled(!isAvailable)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}
