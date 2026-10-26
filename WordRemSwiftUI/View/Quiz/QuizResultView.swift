//
//  QuizResultView.swift
//  WordRemSwiftUI
//
//  Shown after a quiz is completed — displays score, stars, XP earned.
//  "Paper & ink": big serif score, quiet gold stars, no celebration illustration.
//

import SwiftUI

struct QuizResultView: View {

    @EnvironmentObject var langManager: LanguageManager
    let score: Int       // 0–100
    let stars: Int       // 0–3
    let xpEarned: Int
    let levelTitle: String
    let onDone: () -> Void
    /// Seviye geçildiyse: o seviyenin kelimeleriyle sesli pratik
    var onTalk: (() -> Void)? = nil

    @State private var showDetails = false

    private var passed: Bool { stars > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Eyebrow(text: levelTitle)

            // Title
            Text(passed ? langManager.s(.resultLevelComplete) : langManager.s(.resultKeepPracticing))
                .font(DS.Font.display(34, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Rectangle().fill(DS.Colors.line).frame(height: 1)
                .padding(.vertical, 28)

            // Score
            Eyebrow(text: langManager.s(.resultScore), color: DS.Colors.muted)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(score)")
                    .font(DS.Font.display(88, weight: .bold).monospacedDigit())
                    .foregroundStyle(DS.Colors.ink)
                Text("%")
                    .font(DS.Font.display(36, weight: .regular))
                    .foregroundStyle(DS.Colors.inkSoft)
            }
            .padding(.top, 2)

            // Stars
            HStack(spacing: 10) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(i <= stars ? DS.Colors.gold : DS.Colors.line)
                }
            }
            .padding(.top, 14)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(stars)/3")

            // XP
            Text("+\(xpEarned) XP · \(langManager.s(.resultXPEarned))")
                .font(DS.Font.ui(15, weight: .medium).monospacedDigit())
                .foregroundStyle(DS.Colors.muted)
                .padding(.top, 18)
                .opacity(showDetails ? 1 : 0)

            Spacer()

            // Action button
            if passed, let onTalk {
                Button(action: onTalk) {
                    Label(AL.s(.talkPracticeTitle), systemImage: "waveform")
                }
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                .padding(.bottom, 10)
            }
            Button(passed ? langManager.s(.resultContinue) : langManager.s(.resultTryAgain), action: onDone)
                .buttonStyle(InkButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .paperBackground()
        .onAppear {
            if passed { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showDetails = true
            }
        }
    }
}
