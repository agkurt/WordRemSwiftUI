//
//  StreakCelebrationView.swift
//  WordRemSwiftUI
//
//  Günde bir kez, gece yarısından sonraki ilk açılışta gösterilen seri kutlaması.
//

import SwiftUI

// MARK: - View
struct StreakCelebrationView: View {

    @EnvironmentObject var langManager: LanguageManager
    let streakDays: Int
    let onContinue: () -> Void

    @State private var appear = false

    // MARK: - Week helpers
    /// ISO weekday index: Mon=0 … Sun=6
    private var todayISO: Int {
        let wd = Calendar.current.component(.weekday, from: Date()) // 1=Sun … 7=Sat
        return (wd + 5) % 7
    }

    private var days: [String] { langManager.weekDayAbbreviations }

    private enum DayState { case today, streaked, missed, future }

    private func dayState(_ i: Int) -> DayState {
        if i == todayISO           { return .today }
        if i > todayISO            { return .future }
        let daysAgo = todayISO - i
        return daysAgo < streakDays ? .streaked : .missed
    }

    private var title: String {
        plain(streakDays == 1
              ? langManager.s(.streakStartedTitle)
              : langManager.f(.streakContinuedTitle, streakDays))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            PaperCard(padding: 28) {
                VStack(alignment: .leading, spacing: 18) {
                    Eyebrow(text: title, color: DS.Colors.gold)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(streakDays)")
                            .font(DS.Font.display(80, weight: .bold).monospacedDigit())
                            .foregroundStyle(DS.Colors.gold)
                        Text(langManager.s(.todayStreak))
                            .font(DS.Font.ui(15, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }

                    Text(langManager.s(.streakSubtitle))
                        .font(DS.Font.ui(16))
                        .foregroundStyle(DS.Colors.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    weekRow
                        .padding(.vertical, 4)

                    Button(langManager.s(.streakContinue), action: onContinue)
                        .buttonStyle(InkButtonStyle())
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .offset(y: appear ? 0 : 12)
            .opacity(appear ? 1 : 0)
        }
        .presentationBackground(.clear)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) { appear = true }
        }
    }

    // MARK: - Week row
    private var weekRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 8) {
                    dot(dayState(i))
                    Text(days[i])
                        .font(DS.Font.ui(11, weight: .semibold))
                        .foregroundStyle(dayState(i) == .today ? DS.Colors.ink : DS.Colors.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dot(_ state: DayState) -> some View {
        switch state {
        case .today:
            Circle().fill(DS.Colors.gold).frame(width: 14, height: 14)
        case .streaked:
            Circle().fill(DS.Colors.gold.opacity(0.45)).frame(width: 10, height: 10)
                .frame(width: 14, height: 14)
        case .missed, .future:
            Circle().stroke(DS.Colors.line, lineWidth: 1.5).frame(width: 10, height: 10)
                .frame(width: 14, height: 14)
        }
    }

    /// Yerelleştirilmiş metinlerdeki emojileri arayüzden ayıklar.
    private func plain(_ s: String) -> String {
        let scalars = s.unicodeScalars.filter { u in
            let p = u.properties
            if u.value == 0xFE0F || u.value == 0x200D { return false }
            return !(p.isEmojiPresentation || (p.isEmoji && u.value > 0x238C))
        }
        return String(String.UnicodeScalarView(scalars))
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

#Preview {
    StreakCelebrationView(streakDays: 5) {}
        .environmentObject(LanguageManager.shared)
}
