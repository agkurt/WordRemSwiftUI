//
//  ReviewSessionView.swift
//  WordRemSwiftUI
//
//  Aralıklı tekrar oturumu: kelimeyi gör, hatırlamaya çalış, cevabı aç, kendini puanla.
//  "Tekrar" denen kartlar oturumun sonuna eklenir.
//

import SwiftUI

struct ReviewSessionView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var scheduler = ReviewScheduler.shared

    @State private var queue: [LearnedWord]
    @State private var revealed = false
    @State private var reviewedCount = 0
    @State private var glow = false
    @State private var shakes = 0
    @State private var startedAt = Date()
    @State private var answers = 0
    @State private var misses = 0
    @State private var tracked = false
    private let total: Int

    init(words: [LearnedWord]) {
        _queue = State(initialValue: words)
        total = max(words.count, 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if let word = queue.first {
                card(word)
                    .successGlow(glow)
                    .shake(shakes)
                    .id(word.id + "\(reviewedCount)")
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                Spacer(minLength: 16)
                controls(word)
            } else {
                doneView
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .paperBackground()
        .onAppear {
            startedAt = Date()
            Track.practice("start", type: "review", wordCount: total, entryPoint: "home")
        }
        .onDisappear { trackEnd("exit") }
    }

    private func trackEnd(_ action: String) {
        guard !tracked else { return }
        tracked = true
        Track.practice(action, type: "review", wordCount: total, correct: answers - misses, total: answers,
                       duration: Date().timeIntervalSince(startedAt), entryPoint: "home")
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(langManager.s(.reviewClose))
            // Her kart bir çentik
            let parts = min(total, 20)
            HStack(spacing: 3) {
                ForEach(0..<parts, id: \.self) { i in
                    Capsule()
                        .fill(Double(i) < Double(reviewedCount) * Double(parts) / Double(max(1, total)) ? DS.Colors.accent : DS.Colors.line)
                        .frame(height: 4)
                }
            }
            .animation(.easeOut(duration: 0.25), value: reviewedCount)
            Text("\(min(reviewedCount, total))/\(total)")
                .font(DS.Font.ui(13, weight: .medium).monospacedDigit())
                .foregroundStyle(DS.Colors.muted)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    // MARK: - Card: fiş kartı (üstte kırmızı çizgi, açık mavi satırlar; arkada deste)
    private func card(_ word: LearnedWord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: Locale(identifier: langManager.currentLanguageCode)
                .localizedString(forLanguageCode: word.languageCode.lowercased()) ?? word.languageCode,
                    color: DS.Colors.accentText)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.accent).frame(height: 2).padding(.horizontal, -28) }
            Spacer()
            HStack(alignment: .center) {
                Text(word.term)
                    .font(DS.Font.display(52, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                Spacer(minLength: 12)
                SpeakButton(text: word.term, langCode: word.languageCode)
            }
            if let phonetic = word.phonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(DS.Colors.muted)
                    .padding(.top, 6)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                Text(word.meaning)
                    .font(DS.Font.display(28, weight: .regular))
                    .foregroundStyle(DS.Colors.slate)
                    .opacity(revealed ? 1 : 0)
                    .blur(radius: revealed ? 0 : 8)
            }
            .frame(minHeight: 90, alignment: .top)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 360, maxHeight: 520, alignment: .leading)
        .background {
            ZStack(alignment: .top) {
                DS.Colors.paperRaised
                RuledLines(pitch: 36, color: DS.Colors.cardRule).padding(.top, 66)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Colors.line, lineWidth: 1))
        .background {
            // Destenin bir sonraki kartı arkadan görünür
            RoundedRectangle(cornerRadius: 10)
                .fill(DS.Colors.paperSunken)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Colors.line))
                .rotationEffect(.degrees(3.5))
                .offset(x: 8, y: 6)
                .opacity(queue.count > 1 ? 1 : 0)
        }
        .rotationEffect(.degrees(-1))
        .shadow(color: Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.08), radius: 12, y: 8)
        .contentShape(Rectangle())
        .onTapGesture { reveal() }
    }

    // MARK: - Controls
    @ViewBuilder
    private func controls(_ word: LearnedWord) -> some View {
        if revealed {
            let current = scheduler.state(for: word) ?? ReviewState(due: .now)
            HStack(spacing: 10) {
                gradeButton(.again, label: langManager.s(.reviewAgain), hint: langManager.s(.reviewMinutes),
                            tint: DS.Colors.danger, word: word)
                gradeButton(.hard, label: langManager.s(.reviewHard),
                            hint: days(ReviewScheduler.schedule(current, .hard).interval), tint: DS.Colors.inkSoft, word: word)
                gradeButton(.good, label: langManager.s(.reviewGood),
                            hint: days(ReviewScheduler.schedule(current, .good).interval), tint: DS.Colors.success, word: word)
                gradeButton(.easy, label: langManager.s(.reviewEasy),
                            hint: days(ReviewScheduler.schedule(current, .easy).interval), tint: DS.Colors.slate, word: word)
            }
            .transition(.opacity)
        } else {
            Button(langManager.s(.reviewShow)) { reveal() }
                .buttonStyle(InkButtonStyle())
        }
    }

    private func gradeButton(_ grade: ReviewGrade, label: String, hint: String, tint: Color, word: LearnedWord) -> some View {
        Button {
            answer(word, grade)
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(DS.Font.ui(16, weight: .semibold))
                    .foregroundStyle(tint)
                Text(hint)
                    .font(DS.Font.ui(12))
                    .foregroundStyle(DS.Colors.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.button).stroke(DS.Colors.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func days(_ interval: Double) -> String {
        langManager.f(.reviewDays, max(1, Int(interval.rounded())))
    }

    // MARK: - Done
    private var doneView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            InkStamp(top: Date().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))).uppercased(),
                     title: "\(reviewedCount)", bottom: "WORDREM", size: 104)
            Text(langManager.s(.reviewDoneTitle))
                .font(DS.Font.display(40, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
            Text(langManager.f(.reviewDoneBody, reviewedCount))
                .font(DS.Font.ui(17))
                .foregroundStyle(DS.Colors.inkSoft)
            Spacer()
            Button(langManager.s(.reviewClose)) { dismiss() }
                .buttonStyle(InkButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { Haptics.success(); trackEnd("complete") }
    }

    // MARK: - Actions
    private func reveal() {
        guard !revealed else { return }
        withAnimation(.easeOut(duration: 0.25)) { revealed = true }
    }

    private func answer(_ word: LearnedWord, _ grade: ReviewGrade) {
        scheduler.grade(word, grade)
        answers += 1
        if grade == .again { misses += 1 }
        // Önce tepki (doğru: parlama, yanlış: sallanma), sonra sıradaki kart
        if grade == .again {
            Haptics.warning()
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
        } else {
            Haptics.success()
            glow = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) { advance(grade) }
    }

    private func advance(_ grade: ReviewGrade) {
        glow = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            var q = queue
            let first = q.removeFirst()
            if grade == .again { q.append(first) } else { reviewedCount += 1 }
            queue = q
            revealed = false
        }
    }
}
