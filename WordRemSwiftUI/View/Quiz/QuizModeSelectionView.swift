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
            ZStack {
                LinearBackgroundView()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Quiz Mode")
                            .font(.custom("Feather-Bold", size: 28))
                            .foregroundStyle(.primary)
                        Text(cardName)
                            .font(.custom("Feather-Bold", size: 14))
                            .foregroundStyle(.secondary)
                        Text("\(wordInfos.count) words")
                            .font(.custom("Feather-Bold", size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Mode Cards
                    VStack(spacing: 16) {
                        ForEach(QuizMode.allCases) { mode in
                            QuizModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                isAvailable: wordInfos.count >= mode.minimumWordCount
                            ) {
                                if wordInfos.count >= mode.minimumWordCount {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedMode = mode
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Start Button
                    Button {
                        showQuiz = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("Start Quiz")
                                .font(.custom("Feather-Bold", size: 17))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            selectedMode != nil
                                ? LinearGradient(colors: [Color(hex: "#f97316"), Color(hex: "#ea580c")],
                                                 startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                                                 startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: selectedMode != nil ? Color(hex: "#f97316").opacity(0.4) : .clear,
                                radius: 12, y: 6)
                    }
                    .disabled(selectedMode == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .animation(.easeInOut(duration: 0.2), value: selectedMode)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
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
                if let cards = try? await FirebaseService.shared.fetchSourceAndTargetLang(cardId: cardId),
                   let lang = cards.first?.targetLang {
                    targetLang = lang
                }
            }
        }
    }
}

// MARK: - Mode Card

private struct QuizModeCard: View {
    let mode: QuizMode
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.Colors.primaryOrange : Color.white)
                        .frame(width: 50, height: 50)
                        .shadow(color: AppTheme.Shadows.cardColor, radius: 4, y: 2)
                    Image(systemName: mode.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isSelected ? .white : AppTheme.Colors.primaryOrange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.rawValue)
                        .font(.custom("Feather-Bold", size: 15))
                        .foregroundStyle(isAvailable ? .primary : .secondary)
                    Text(mode.description)
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(.secondary)
                    if !isAvailable {
                        Text("Needs at least \(mode.minimumWordCount) words")
                            .font(.custom("Feather-Bold", size: 11))
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: isSelected ? AppTheme.Shadows.vibrantColor : AppTheme.Shadows.cardColor, radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppTheme.Colors.primaryOrange : AppTheme.Colors.inputBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .opacity(isAvailable ? 1.0 : 0.5)
        .disabled(!isAvailable)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
