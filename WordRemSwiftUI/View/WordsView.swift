//
//  WordsView.swift
//  WordRemSwiftUI
//
//  Öğrenilen kelimeler (SRS durumuyla) ve kullanıcı desteleri.
//

import SwiftUI

struct WordsView: View {
    enum Segment: Hashable { case learned, decks }

    @EnvironmentObject var langManager: LanguageManager
    @ObservedObject private var scheduler = ReviewScheduler.shared
    @ObservedObject var homeVM: HomeScreenViewModel
    @Binding var showCreateDeck: Bool
    @Binding var segment: Segment

    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text(langManager.s(.wordsTitle))
                    .font(DS.Font.display(34, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                Picker("", selection: $segment) {
                    Text(langManager.s(.wordsLearned)).tag(Segment.learned)
                    Text(langManager.s(.wordsDecks)).tag(Segment.decks)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 12)

            switch segment {
            case .learned: learnedList
            case .decks:   HomeScreenView(viewModel: homeVM, showCreateDeck: $showCreateDeck)
            }
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .paperBackground()
        .onAppear { scheduler.reload() }
    }

    // MARK: - Learned
    private var filtered: [LearnedWord] {
        let words = scheduler.words
        guard !searchText.isEmpty else { return words }
        return words.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.meaning.localizedCaseInsensitiveContains(searchText)
        }
    }

    @ViewBuilder
    private var learnedList: some View {
        if scheduler.words.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(langManager.s(.wordsEmpty))
                    .font(DS.Font.ui(16))
                    .foregroundStyle(DS.Colors.muted)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(DS.Colors.muted)
                        TextField(langManager.s(.wordsSearch), text: $searchText)
                            .font(DS.Font.ui(16))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 12)

                    ForEach(filtered) { word in
                        row(word)
                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func row(_ word: LearnedWord) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(word.term)
                    .font(DS.Font.display(20))
                    .foregroundStyle(DS.Colors.ink)
                Text(word.meaning)
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            statusLabel(word)
            SpeakButton(text: word.term, langCode: word.languageCode)
                .scaleEffect(0.85)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func statusLabel(_ word: LearnedWord) -> some View {
        if let state = scheduler.state(for: word) {
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                                       to: Calendar.current.startOfDay(for: state.due)).day ?? 0
            if state.isMature {
                Text(langManager.s(.wordsMastered))
                    .font(DS.Font.ui(12, weight: .semibold))
                    .foregroundStyle(DS.Colors.success)
            } else if days <= 0 {
                Text(langManager.s(.wordsDue))
                    .font(DS.Font.ui(12, weight: .semibold))
                    .foregroundStyle(DS.Colors.accent)
            } else {
                Text(langManager.f(.wordsDueIn, days))
                    .font(DS.Font.ui(12))
                    .foregroundStyle(DS.Colors.muted)
            }
        }
    }
}
