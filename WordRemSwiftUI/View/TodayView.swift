//
//  TodayView.swift
//  WordRemSwiftUI
//
//  Uygulamanın açılış ekranı: bugünün tekrarları, seri ve günün kelimesi.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var langManager: LanguageManager
    @ObservedObject private var scheduler = ReviewScheduler.shared
    @ObservedObject private var mistakes = MistakesManager.shared

    /// "Yeni kelime öğren" → Pratik sekmesine geçiş
    var onLearnNew: () -> Void
    var onOpenLeaderboard: () -> Void

    @State private var showReview = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header
                reviewCard
                statsRow
                if let word = wordOfTheDay {
                    wordOfTheDayCard(word)
                }
                learnNewButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .paperBackground()
        .onAppear { scheduler.reload() }
        .fullScreenCover(isPresented: $showReview) {
            ReviewSessionView(words: scheduler.dueToday)
                .environmentObject(langManager)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: Date().formatted(.dateTime.weekday(.wide).day().month(.wide)
                    .locale(Locale(identifier: langManager.currentLanguageCode))))
                Text(langManager.s(.todayTitle))
                    .font(DS.Font.display(40, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
            }
            Spacer()
            Button(action: onOpenLeaderboard) {
                Image(systemName: "trophy")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            }
            .accessibilityLabel(langManager.s(.tabRank))
        }
    }

    // MARK: - Review Card
    @ViewBuilder
    private var reviewCard: some View {
        let due = scheduler.dueToday.count
        PaperCard(padding: 24) {
            if scheduler.knownCount == 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text(langManager.s(.todayNoWords))
                        .font(DS.Font.display(24))
                        .foregroundStyle(DS.Colors.ink)
                    Text(langManager.s(.todayNoWordsBody))
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if due == 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.success)
                        .frame(width: 36, height: 36)
                        .background(DS.Colors.successSoft, in: Circle())
                    Text(langManager.s(.todayAllDone))
                        .font(DS.Font.display(26))
                        .foregroundStyle(DS.Colors.ink)
                    Text(langManager.s(.todayAllDoneBody))
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(due)")
                            .font(DS.Font.display(64, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .contentTransition(.numericText())
                        Text(langManager.s(.todayDueCount))
                            .font(DS.Font.ui(17, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                    Text(langManager.f(.todayDueMinutes, max(1, Int((Double(due) * 20 / 60).rounded(.up)))))
                        .font(DS.Font.ui(14))
                        .foregroundStyle(DS.Colors.muted)
                    Button(langManager.s(.todayStartReview)) { showReview = true }
                        .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                }
            }
        }
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 0) {
            stat(value: "\(scheduler.streak)", label: langManager.s(.todayStreak),
                 tint: scheduler.reviewedToday ? DS.Colors.gold : DS.Colors.ink)
            divider
            stat(value: "\(scheduler.knownCount)", label: langManager.s(.todayKnown), tint: DS.Colors.ink)
            divider
            stat(value: "+\(scheduler.learnedThisWeek)", label: langManager.s(.todayThisWeek), tint: DS.Colors.ink)
        }
        .padding(.vertical, 4)
    }

    private var divider: some View {
        Rectangle().fill(DS.Colors.line).frame(width: 1, height: 40)
    }

    private func stat(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DS.Font.display(28, weight: .bold))
                .foregroundStyle(tint)
            Text(label)
                .font(DS.Font.ui(12, weight: .medium))
                .foregroundStyle(DS.Colors.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Word of the Day
    private var wordOfTheDay: LearnedWord? {
        let words = scheduler.words
        guard !words.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return words[(day &* 7919) % words.count]
    }

    private func wordOfTheDayCard(_ word: LearnedWord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: langManager.s(.todayWordOfDay), color: DS.Colors.muted)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.term)
                        .font(DS.Font.display(34))
                        .foregroundStyle(DS.Colors.ink)
                    if let phonetic = word.phonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(DS.Colors.muted)
                    }
                }
                Spacer()
                SpeakButton(text: word.term, langCode: word.languageCode)
            }
            Rectangle().fill(DS.Colors.accent).frame(width: 24, height: 2)
            Text(word.meaning)
                .font(DS.Font.ui(17, weight: .medium))
                .foregroundStyle(DS.Colors.inkSoft)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Learn New
    private var learnNewButton: some View {
        VStack(spacing: 12) {
            Button(action: onLearnNew) {
                Label(langManager.s(.todayLearnNew), systemImage: "plus")
            }
            .buttonStyle(OutlineButtonStyle())

            if mistakes.count > 0 {
                Button(action: onLearnNew) {
                    HStack {
                        Text(langManager.s(.todayMistakes))
                        Spacer()
                        Text("\(mistakes.count)")
                            .font(DS.Font.ui(15, weight: .bold))
                            .foregroundStyle(DS.Colors.danger)
                    }
                    .font(DS.Font.ui(15, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Speak Button (cihaz içi seslendirme)
struct SpeakButton: View {
    let text: String
    let langCode: String
    var body: some View {
        Button {
            TTSManager.shared.speak(text, langCode: langCode)
        } label: {
            Image(systemName: "speaker.wave.2")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DS.Colors.inkSoft)
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
        }
    }
}
