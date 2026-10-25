//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Kullanıcının desteleri. "Kelimelerim → Desteler" segmentinin içinde gösterilir;
//  sayfa başlığı ve zemin üst görünümde (WordsView).
//

import SwiftUI

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
                DS.Colors.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        AppLoadingView(message: langManager.s(.homeLoadingDecks))
                    } else if viewModel.cardNames.isEmpty {
                        EmptyDecksView(onAdd: { showCreateDeck = true })
                    } else {
                        // Search + edit toggle
                        HStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass").foregroundStyle(DS.Colors.muted)
                                TextField(langManager.s(.homeSearchPlaceholder), text: $searchText)
                                    .font(DS.Font.ui(16))
                                    .foregroundStyle(DS.Colors.ink)
                                    .tint(DS.Colors.accent)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 12))

                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { isEditing.toggle() }
                            } label: {
                                Image(systemName: isEditing ? "checkmark" : "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(isEditing ? DS.Colors.danger : DS.Colors.inkSoft)
                                    .frame(width: 44, height: 44)
                                    .background(isEditing ? DS.Colors.dangerSoft : DS.Colors.paperSunken,
                                                in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 4)

                        if filteredIndices.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(langManager.f(.homeNoResultsFormat, searchText))
                                    .font(DS.Font.ui(16))
                                    .foregroundStyle(DS.Colors.muted)
                                Spacer()
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 0) {
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
                                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
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

// MARK: - Empty State
private struct EmptyDecksView: View {
    @EnvironmentObject var langManager: LanguageManager
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(langManager.s(.homeCreateFirstDeck))
                .font(DS.Font.display(26, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(langManager.s(.homeCreateFirstDeckHint))
                .font(DS.Font.ui(16))
                .foregroundStyle(DS.Colors.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onAdd) {
                Label(langManager.s(.homeCreateDeck), systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle())
            .frame(maxWidth: 320)
            .padding(.top, 14)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

#Preview {
    EmptyDecksView(onAdd: {})
        .environmentObject(LanguageManager.shared)
}
