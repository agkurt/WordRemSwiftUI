//
//  HomeScreenView.swift
//  WordRemSwiftUI
//

import SwiftUI
import Lottie

struct HomeScreenView: View {

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
                    // MARK: Header
                    HomeHeaderView(isEditing: $isEditing, onAdd: { showCreateDeck = true })
                        .padding(.top, 4)

                    // MARK: Search
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        TextField(AL.s(.homeSearchPlaceholder), text: $searchText)
                            .font(.custom("Poppins-Regular", size: 15))
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

                    // MARK: Content
                    if viewModel.isLoading {
                        Spacer()
                        LottieView(animation: .named("reeny_waving"))
                            .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .frame(width: 140, height: 140)
                        Spacer()
                    } else if viewModel.cardNames.isEmpty {
                        EmptyDecksView(onAdd: { showCreateDeck = true })
                    } else if filteredIndices.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text(AL.f(.homeNoResultsFormat, searchText))
                                .font(.custom("Poppins-Regular", size: 15))
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
                }
            }
            .navigationBarHidden(true)
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
    @Binding var isEditing: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AL.s(.homeMyDecks))
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(AL.s(.homeTapToStudy))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            HStack(spacing: 12) {
                // Profile Button
                NavigationLink(destination: ProfileView()) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.circularButtonBg)
                            .frame(width: 44, height: 44)
                            .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: 3)
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.circularButtonIcon)
                    }
                }
                
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Empty State
private struct EmptyDecksView: View {
    let onAdd: () -> Void

    var body: some View {
        Spacer()
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#f97316").opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: "#f97316"))
            }
            VStack(spacing: 6) {
                Text(AL.s(.homeNoDecks))
                    .font(.custom("Poppins-SemiBold", size: 20))
                Text(AL.s(.homeNoDecksHint))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        Spacer()
    }
}

// MARK: - Empty State
private struct EmptyDescksView: View {

    var body: some View {
        Spacer()
        VStack(spacing: 20) {
            ZStack {
                LottieView(animation: .named("reeny_waving"))
                    .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 140, height: 140)
            }
           
        }
        Spacer()
    }
}

#Preview {
    EmptyDescksView()
}



