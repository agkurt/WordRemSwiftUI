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
            LinearBackgroundView()
                VStack(spacing: 0) {
                    // Empty state
                    if viewModel.wordInfo.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            Text("No words yet")
                                .font(.custom("Feather-Bold", size: 18))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Tap + to add your first word")
                                .font(.custom("Feather-Bold", size: 14))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack {
                                ForEach(viewModel.wordInfo.indices, id: \.self) { index in
                                    CardFlipView(viewModel: viewModel,
                                                 isEditing: $isEditing,
                                                 isFlipped: isFlipped,
                                                 cardId: cardId,
                                                 index: index)
                                }
                            }
                            .padding(.bottom, 90)
                        }
                    }
                }

                // Quiz FAB
                if !viewModel.wordInfo.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showQuizSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Quiz")
                                        .font(.custom("Feather-Bold", size: 15))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [Color(hex: "#f97316"), Color(hex: "#ea580c")],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color(hex: "#f97316").opacity(0.4), radius: 12, y: 6)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 24)
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
                            .foregroundStyle(AppTheme.Colors.primaryOrange)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Image(systemName: isEditing ? "checkmark" : "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isEditing ? Color.green : AppTheme.Colors.primaryOrange)
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
