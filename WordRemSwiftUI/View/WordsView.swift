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
    var onOpenLeaderboard: () -> Void = {}

    @State private var searchText = ""
    /// Düzenle: her satırın başında silme düğmesi
    @State private var editing = false
    @State private var showPractice = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Uygulamanın ortak üst satırı (Konuş sekmesindekiyle aynı)
            AppHeader(onOpenLeaderboard: onOpenLeaderboard)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
            // Defter ayırıcı sekmeleri
            HStack(alignment: .bottom, spacing: 4) {
                tab(NoteText.title, .decks)
                tab(langManager.s(.wordsLearned), .learned)
            }
            .padding(.leading, 20)
            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }

            switch segment {
            case .learned: learnedList
            case .decks:   NotebookShelfView(homeVM: homeVM, showCreateDeck: $showCreateDeck)
            }
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .paperBackground()
        .onAppear { scheduler.reload() }
    }

    private func tab(_ title: String, _ value: Segment) -> some View {
        let on = segment == value
        let shape = UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
        return Button { withAnimation(.easeOut(duration: 0.15)) { segment = value } } label: {
            Text(title)
                .font(DS.Font.ui(14, weight: on ? .semibold : .regular))
                .foregroundStyle(on ? DS.Colors.ink : DS.Colors.muted)
                .padding(.horizontal, 18)
                .frame(height: on ? 40 : 34)
                .background(on ? DS.Colors.paperRaised : DS.Colors.paperSunken, in: shape)
                .overlay(shape.stroke(DS.Colors.line))
                .overlay(alignment: .bottom) {
                    if on { Rectangle().fill(DS.Colors.paperRaised).frame(height: 2).offset(y: 1) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: - Learned
    private var filtered: [LearnedWord] {
        let words = scheduler.currentWords
        guard !searchText.isEmpty else { return words }
        return words.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.meaning.localizedCaseInsensitiveContains(searchText)
        }
    }

    @ViewBuilder
    private var learnedList: some View {
        if scheduler.currentWords.isEmpty {
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
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(DS.Colors.muted)
                        TextField(langManager.s(.wordsSearch), text: $searchText)
                            .font(DS.Font.ui(16))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button { withAnimation(.easeOut(duration: 0.2)) { editing.toggle() } } label: {
                            Text(editing ? WordsText.done : WordsText.edit)
                                .font(DS.Font.ui(14, weight: .semibold))
                                .foregroundStyle(DS.Colors.accentText)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .frame(height: 48)
                    .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
                    .padding(.bottom, 12)

                    if searchText.isEmpty { practiceCard.padding(.bottom, 8) }

                    // Sözlük gibi: harfler kenar boşluğunda
                    ForEach(groups, id: \.letter) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(group.words) { word in
                                row(word)
                                Rectangle().fill(DS.Colors.rule).frame(height: 1)
                            }
                        }
                        .overlay(alignment: .topLeading) {
                            Text(group.letter)
                                .font(DS.Font.display(20, weight: .bold))
                                .foregroundStyle(DS.Colors.accentText)
                                .frame(width: 40)
                                .offset(x: -52, y: 14)
                        }
                    }
                }
                .padding(.leading, 58)
                .padding(.trailing, 20)
                .padding(.bottom, 120)
            }
            .background(alignment: .leading) {
                Rectangle().fill(DS.Colors.margin).frame(width: 1.5).padding(.leading, 46)
            }
            .background(DS.Colors.paperRaised)
        }
    }

    /// Baş harfe göre gruplar (dile duyarlı sıralama)
    private var groups: [(letter: String, words: [LearnedWord])] {
        let locale = Locale(identifier: langManager.currentLanguageCode)
        let sorted = filtered.sorted { $0.term.compare($1.term, locale: locale) == .orderedAscending }
        var out: [(letter: String, words: [LearnedWord])] = []
        for w in sorted {
            let stripped = w.term.replacingOccurrences(of: #"^(el|la|los|las|le|les|l'|der|die|das|il|lo|gli|the|a|an)\s+"#,
                                                       with: "", options: [.regularExpression, .caseInsensitive])
            let letter = String(stripped.prefix(1)).uppercased(with: locale)
            if out.last?.letter == letter { out[out.count - 1].words.append(w) } else { out.append((letter, [w])) }
        }
        return out
    }

    /// Öğrenilen kelimeleri sesli öğretmenle cümle içinde kullan
    private var practiceCard: some View {
        Button { showPractice = true } label: {
            HStack(spacing: 14) {
                StampMic(look: .ready, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(AL.s(.talkPracticeTitle))
                        .font(DS.Font.ui(16, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    Text(AL.s(.talkPracticeSub))
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(DS.Colors.accentText)
            }
            .padding(14)
            .background(DS.Colors.note, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showPractice) {
            VoiceTutorView(mode: .wordPractice) { _ in scheduler.reload() }
        }
    }

    private func row(_ word: LearnedWord) -> some View {
        HStack(alignment: .center, spacing: 12) {
            if editing {
                // Kırmızı kalemle silme düğmesi
                Button { delete(word) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DS.Colors.redPen)
                        .frame(width: 32, height: 44)
                }
                .accessibilityLabel(NoteText.delete)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
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
        .contentShape(Rectangle())
        // Uzun basınca silme
        .contextMenu {
            Button(role: .destructive) { delete(word) } label: { Label(NoteText.delete, systemImage: "trash") }
        }
    }

    private func delete(_ word: LearnedWord) {
        Haptics.tap()
        withAnimation(.easeOut(duration: 0.25)) { scheduler.remove(word) }
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

/// Kelimelerim metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
private enum WordsText {
    static var edit: String { PageText.t(["Düzenle", "Edit", "Bearbeiten", "Modifier", "Editar", "Modifica", "Изменить", "编辑"]) }
    static var done: String { PageText.t(["Bitti", "Done", "Fertig", "OK", "Listo", "Fine", "Готово", "完成"]) }
}
