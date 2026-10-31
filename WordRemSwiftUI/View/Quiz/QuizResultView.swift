//
//  QuizResultView.swift
//  WordRemSwiftUI
//
//  Shown after a quiz is completed — displays score, stars, XP earned.
//  Defter: puan sayfaya basılan tarihli mühürde, yıldızlar yerine öğretmenin kalem tikleri,
//  sayılar noktalı satırlarda. Konfeti, halka ya da rozet yok.
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
    @State private var stamped = false

    private var passed: Bool { stars > 0 }

    private var stampDate: String {
        Date().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sayfa: kenar boşluğunun sağında başlık, sağ üstte mühür
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 24)

                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: levelTitle, color: DS.Colors.accentText)
                        Text(passed ? langManager.s(.resultLevelComplete) : langManager.s(.resultKeepPracticing))
                            .font(DS.Font.display(32, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 36)
                    Spacer(minLength: 0)
                    // Mühür sayfaya basılır: büyükten oturur
                    InkStamp(top: stampDate, title: "\(score)%", bottom: "WORDREM",
                             color: passed ? DS.Colors.accent : DS.Colors.slate, size: 112)
                        .scaleEffect(stamped ? 1 : 2.2)
                        .opacity(stamped ? 1 : 0)
                        .rotationEffect(.degrees(stamped ? 0 : 14))
                }

                // Yıldızlar yerine kalem tikleri: kazanılan tikler terrakota mürekkeple çizilir
                HStack(spacing: 14) {
                    ForEach(1...3, id: \.self) { i in
                        ZStack {
                            PenTick()
                                .stroke(DS.Colors.line, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            PenTick()
                                .trim(from: 0, to: showDetails && i <= stars ? 1 : 0)
                                .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .animation(.easeOut(duration: 0.3).delay(0.25 + Double(i) * 0.15), value: showDetails)
                        }
                        .frame(width: 28, height: 24)
                    }
                }
                .padding(.top, 18)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stars)/3")

                // Noktalı satırlarda sayılar
                VStack(spacing: 12) {
                    LeaderRow(label: langManager.s(.resultScore), value: "\(score)%")
                    LeaderRow(label: langManager.s(.resultXPEarned), value: "+\(xpEarned) XP")
                }
                .padding(.top, 30)
                .opacity(showDetails ? 1 : 0)

                Spacer()
            }
            .padding(.leading, DS.Page.textX)
            .padding(.trailing, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // Kenar boşluğu çizgisi yalnızca sayfada, alttaki düğmelerin arkasından geçmez
            .background { MarginLine() }

            // Action button
            VStack(spacing: 10) {
                if passed, let onTalk {
                    Button(action: onTalk) {
                        Label(AL.s(.talkPracticeTitle), systemImage: "waveform")
                    }
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                }
                Button(passed ? langManager.s(.resultContinue) : langManager.s(.resultTryAgain), action: onDone)
                    .buttonStyle(InkButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .ruledPage(margin: false)
        .onAppear {
            if passed { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.55).delay(0.1)) {
                stamped = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showDetails = true
            }
        }
    }
}
