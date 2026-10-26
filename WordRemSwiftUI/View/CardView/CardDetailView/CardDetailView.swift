//
//  CardDetailView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardDetailView: View {

    @ObservedObject var viewModel: CardDetailViewModel
    var cardName: String
    @State var cardId: String
    @State private var showSheet = false
    @State private var showQuizSheet = false
    @State var isEditing: Bool = false
    @State var isFlipped: Bool = true
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tabBarModifier: TabBarModifier

    var body: some View {
        ZStack {
            DS.Colors.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Empty state
                    if viewModel.wordInfo.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(AL.s(.deckNoWords))
                                .font(DS.Font.display(26, weight: .semibold))
                                .foregroundStyle(DS.Colors.ink)
                            Text(AL.s(.deckTapToAdd))
                                .font(DS.Font.ui(16))
                                .foregroundStyle(DS.Colors.muted)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .frame(maxWidth: 620, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                // Kelime sayısı + quiz: "+" (kelime ekle) düğmesiyle çakışmasın diye üstte
                                HStack {
                                    Eyebrow(text: AL.f(.deckWordCount, viewModel.wordInfo.count), color: DS.Colors.muted)
                                    Spacer()
                                    Button { showQuizSheet = true } label: {
                                        Label(AL.s(.deckQuiz), systemImage: "checklist")
                                            .font(DS.Font.ui(14, weight: .semibold))
                                            .foregroundStyle(DS.Colors.paper)
                                            .padding(.horizontal, 14)
                                            .frame(height: 36)
                                            .background(DS.Colors.accent, in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.bottom, 4)
                                ForEach(viewModel.wordInfo.indices, id: \.self) { index in
                                    CardFlipView(viewModel: viewModel,
                                                 isEditing: $isEditing,
                                                 isFlipped: isFlipped,
                                                 cardId: cardId,
                                                 index: index)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 110)
                            .frame(maxWidth: 620)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

            }
            .onAppear {
                tabBarModifier.customAddAction = {
                    showSheet = true
                }
                Task {
                    await viewModel.fetchCardInfo(cardId: cardId)
                }
            }
            .onDisappear {
                tabBarModifier.customAddAction = nil
            }
            .navigationTitle(cardName)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Image(systemName: isEditing ? "checkmark" : "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isEditing ? DS.Colors.danger : DS.Colors.inkSoft)
                    }
                }
            }
            .sheet(isPresented: $showQuizSheet) {
                QuizModeSelectionView(
                    wordInfos: viewModel.wordInfo,
                    cardId: cardId,
                    cardName: cardName
                )
            }
            .sheet(isPresented: $showSheet) {
                CardPlusView(cardId: cardId) {
                    // Refresh data after adding a word
                    Task {
                        await viewModel.fetchCardInfo(cardId: cardId)
                    }
                }
            }
    }
}
