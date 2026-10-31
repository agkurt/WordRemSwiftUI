//
//  LessonCompleteView.swift
//  WordRemSwiftUI
//
//  Sesli ders bitince defter sayfası: tarihli mühür, başlık, noktalı satırlarda sayılar,
//  fosforlu öğrenilen ifadeler (öğretmenin sesiyle) ve Devam → ana sayfa (sıradaki ders).
//

import SwiftUI
import StoreKit

struct LessonCompleteView: View {
    struct Phrase: Identifiable {
        let id = UUID()
        let text: String
        let translation: String?
    }

    let lessonTitle: String
    let learnerName: String
    let phrases: [Phrase]
    let mastery: Int          // yüzde
    let duration: TimeInterval
    /// Gerçek derslerde true; ekran görüntüsü demosunda puan penceresi açılmasın
    var asksForReview = false
    var onContinue: () -> Void

    @Environment(\.requestReview) private var requestReview
    @State private var appear = false
    @State private var shownPhrases = 0
    @State private var shownMastery = 0

    private var targetCode: String { UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN" }

    private var headline: String {
        lessonTitle.isEmpty ? AL.s(.talkSessionEnded) : lessonTitle
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Başlık solda, tarihli mühür sağ üstte (sayfaya basılır)
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(learnerName.isEmpty ? AL.s(.lcGreatJob) : AL.f(.lcCongrats, learnerName))
                                .font(.system(size: 17, design: .serif).italic())
                                .foregroundStyle(DS.Colors.accentText)
                            Text(headline)
                                .font(DS.Font.display(30, weight: .bold))
                                .foregroundStyle(DS.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if !lessonTitle.isEmpty {
                                Text(AL.s(.talkLessonComplete))
                                    .font(DS.Font.ui(13))
                                    .foregroundStyle(DS.Colors.muted)
                            }
                        }
                        .padding(.top, 48)
                        Spacer(minLength: 0)
                        InkStamp(top: stampDate, title: "✓", bottom: "WORDREM", size: 112)
                            .scaleEffect(appear ? 1 : 2.2)
                            .opacity(appear ? 1 : 0)
                            .rotationEffect(.degrees(appear ? 0 : 14))
                            .padding(.top, 8)
                    }

                    VStack(spacing: 12) {
                        LeaderRow(label: AL.s(.lcPhrases), value: "\(shownPhrases)")
                        LeaderRow(label: AL.s(.lcMastery), value: "%\(shownMastery)")
                        LeaderRow(label: AL.s(.lcTime), value: durationText)
                    }
                    .padding(.top, 30)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.35), value: appear)

                    if !phrases.isEmpty {
                        Eyebrow(text: AL.f(.lcNewPhrases, phrases.count), color: DS.Colors.accentText)
                            .padding(.top, 34)
                            .padding(.bottom, 4)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(phrases.enumerated()), id: \.element.id) { i, p in
                                phraseRow(p)
                                    .opacity(appear ? 1 : 0)
                                    .animation(.easeOut(duration: 0.4).delay(0.55 + Double(i) * 0.06), value: appear)
                            }
                        }
                    }
                }
                .padding(.leading, DS.Page.textX)
                .padding(.trailing, 24)
                .padding(.bottom, 130)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Sabit alt düğme
            Button(AL.s(.talkContinueNext), action: onContinue)
                .buttonStyle(InkButtonStyle())
                .frame(maxWidth: 560)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
                .background(DS.Colors.paper.ignoresSafeArea(edges: .bottom))
        }
        .ruledPage()
        .task {
            // Mühür sayfaya basılır: büyükten oturur, tok bir titreşim
            withAnimation(.spring(response: 0.38, dampingFraction: 0.55).delay(0.15)) { appear = true }
            try? await Task.sleep(nanoseconds: 330_000_000)
            Haptics.success()
            // Sayılar sıfırdan yükselir
            let steps = 24
            for s in 1...steps {
                try? await Task.sleep(nanoseconds: 28_000_000)
                shownPhrases = Int((Double(phrases.count) * Double(s) / Double(steps)).rounded())
                shownMastery = Int((Double(mastery) * Double(s) / Double(steps)).rounded())
            }
            // Kutlama oturduktan sonra, kullanıcı en mutluyken puan iste
            if asksForReview && ReviewPrompt.shouldAsk(mastery: mastery) {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                ReviewPrompt.markAsked()
                requestReview()
            }
        }
    }

    private var stampDate: String {
        Date().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))).uppercased()
    }

    /// Öğrenilen ifade: fosforlu satır, dokununca Lupa'nın sesiyle
    private func phraseRow(_ p: Phrase) -> some View {
        Button { TutorVoice.shared.speak(p.text, langCode: targetCode) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    highlightedText(p.text)
                        .font(DS.Font.display(20, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    if let tr = p.translation, !tr.isEmpty {
                        Text(tr)
                            .font(.system(size: 14, design: .serif).italic())
                            .foregroundStyle(DS.Colors.muted)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DS.Colors.accentText)
                    .frame(width: 44, height: 44)
            }
            .padding(.vertical, 8)
            .frame(minHeight: DS.Page.pitch * 2)
            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var durationText: String {
        let s = Int(duration)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// App Store puan isteği: iyi geçen her dersten sonra, en az 3 gün arayla. Apple pencereyi yılda
/// en fazla 3 kez gösteriyor, ilk ayda puan hızı sıralamayı belirlediği için o hakları erken kullanıyoruz.
enum ReviewPrompt {
    private static let lastAskedKey = "reviewPromptLastAsked"
    private static let minGap: TimeInterval = 3 * 24 * 3600

    static func shouldAsk(mastery: Int) -> Bool {
        guard mastery >= 60 else { return false }
        guard let last = UserDefaults.standard.object(forKey: lastAskedKey) as? Date else { return true }
        return Date().timeIntervalSince(last) >= minGap
    }

    static func markAsked() { UserDefaults.standard.set(Date(), forKey: lastAskedKey) }

    /// Profil'deki "Puan ver" satırı: doğrudan yorum yazma sayfası
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6474321549?action=write-review")!
}
