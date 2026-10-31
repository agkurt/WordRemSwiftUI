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
                        // Boş deste: üstüne henüz bir şey yazılmamış fiş kartı
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(AL.s(.deckNoWords))
                                    .font(DS.Font.display(26, weight: .semibold))
                                    .foregroundStyle(DS.Colors.ink)
                                    .padding(.bottom, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(DS.Colors.accent).frame(height: 2).padding(.horizontal, -22)
                                    }
                                Text(AL.s(.deckTapToAdd))
                                    .font(DS.Font.ui(16))
                                    .foregroundStyle(DS.Colors.inkSoft)
                                    .padding(.top, 10)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(22)
                            .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                            .background {
                                ZStack(alignment: .top) {
                                    DS.Colors.paperRaised
                                    RuledLines(pitch: 36, color: DS.Colors.cardRule).padding(.top, 66)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Colors.line, lineWidth: 1))
                            .rotationEffect(.degrees(-1))
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .frame(maxWidth: 620, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 18) {
                                // Kelime sayısı + quiz: "+" (kelime ekle) düğmesiyle çakışmasın diye üstte
                                HStack {
                                    Eyebrow(text: AL.f(.deckWordCount, viewModel.wordInfo.count), color: DS.Colors.accentText)
                                    Spacer()
                                    // Quiz: dolu hap yerine mürekkep mührü gibi çerçeveli etiket
                                    Button { showQuizSheet = true } label: {
                                        Label(AL.s(.deckQuiz), systemImage: "checklist")
                                            .font(DS.Font.ui(14, weight: .semibold))
                                            .foregroundStyle(DS.Colors.accentText)
                                            .padding(.horizontal, 12)
                                            .frame(height: 34)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Colors.accent, lineWidth: 1.5))
                                            .contentShape(Rectangle())
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
