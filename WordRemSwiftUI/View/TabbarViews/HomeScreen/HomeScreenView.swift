//
//  HomeScreenView.swift
//  WordRemSwiftUI
//

import SwiftUI
import Lottie

struct HomeScreenView: View {

    @EnvironmentObject var langManager: LanguageManager
    @ObservedObject var viewModel: HomeScreenViewModel
    @EnvironmentObject var authManager: AuthManager
    @Binding var showCreateDeck: Bool
    @State var isEditing = false
    @State private var searchText = ""

    private var filteredIndices: [Int] {
        viewModel.cardNames.indices.filter { i in
            searchText.isEmpty ? true : viewModel.cardNames[i].localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()

                VStack(spacing: 0) {
                    // MARK: Content
                    if viewModel.isLoading {
                        AppLoadingView(message: langManager.s(.homeLoadingDecks))
                    } else if viewModel.cardNames.isEmpty {
                        EmptyDecksView(onAdd: { showCreateDeck = true })
                    } else {
                        // Header — sadece deste varken göster
                        HomeHeaderView(isEditing: $isEditing)
                            .padding(.top, 4)

                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            TextField(langManager.s(.homeSearchPlaceholder), text: $searchText)
                                .font(.custom("Feather-Bold", size: 15))
                                .autocorrectionDisabled()
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                .tint(AppTheme.Colors.primaryOrange)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.Colors.inputBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.Colors.inputBorder, lineWidth: 1)
                                )
                                .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                        if filteredIndices.isEmpty {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.secondary)
                                Text(langManager.f(.homeNoResultsFormat, searchText))
                                    .font(.custom("Feather-Bold", size: 15))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredIndices, id: \.self) { index in
                                        NavigationLink(
                                            destination: CardDetailView(
                                                viewModel: CardDetailViewModel(),
                                                cardName: viewModel.cardNames[index],
                                                cardId: viewModel.cardIds[index]
                                            )
                                        ) {
                                            CardView(
                                                isEditing: $isEditing,
                                                title: viewModel.cardNames[index],
                                                image: viewModel.selectedFlag[index],
                                                wordCount: index < viewModel.cardWordCounts.count ? viewModel.cardWordCounts[index] : 0,
                                                onDelete: {
                                                    if isEditing {
                                                        withAnimation { viewModel.deleteCard(at: index) }
                                                    }
                                                }
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 120)
                            }
                        }
                    } // end else (has decks)
                }
            }
            .navigationBarHidden(true)
            .hideKeyboardOnTap()
            .onAppear {
                Task { await viewModel.fetchCardName() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .pathMistakesDeckCreated)) { _ in
                Task { await viewModel.fetchCardName() }
            }
        }
    }
}

// MARK: - Header
private struct HomeHeaderView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Binding var isEditing: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(langManager.s(.homeMyDecks))
                    .font(.custom("Feather-Bold", size: 28))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(langManager.s(.homeTapToStudy))
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            // Edit/Delete Button
            Button {
                withAnimation(.spring()) { isEditing.toggle() }
            } label: {
                ZStack {
                    Circle()
                        .fill(isEditing ? AppTheme.Colors.destructiveSoft : AppTheme.Colors.circularButtonBg)
                        .frame(width: 44, height: 44)
                        .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: 3)
                    Image(systemName: isEditing ? "checkmark" : "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isEditing ? AppTheme.Colors.destructive : AppTheme.Colors.circularButtonIcon)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Empty State
private struct EmptyDecksView: View {
    @EnvironmentObject var langManager: LanguageManager
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            LottieView(animation: .named("reeny_waving"))
                .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .frame(width: 160, height: 160)

            VStack(spacing: 8) {
                Text(langManager.s(.homeCreateFirstDeck))
                    .font(.custom("Feather-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(langManager.s(.homeCreateFirstDeckHint))
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(langManager.s(.homeCreateDeck))
                        .font(.custom("Feather-Bold", size: 15))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(AppTheme.Colors.primaryOrange, in: Capsule())
                .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.35), radius: 12, y: 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
    }
}

#Preview {
    EmptyDecksView(onAdd: {})
}



