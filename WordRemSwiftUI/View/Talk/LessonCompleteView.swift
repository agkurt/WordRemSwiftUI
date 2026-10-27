//
//  LessonCompleteView.swift
//  WordRemSwiftUI
//
//  Sesli ders bitince tek, sakin bir kutlama sayfası: konfeti, rozet, başlık, sayılarla canlanan
//  istatistikler, öğrenilen ifadeler (öğretmenin sesiyle) ve Devam → ana sayfa (sıradaki ders).
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
    @State private var confetti = 0

    private var targetCode: String { UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN" }

    private var headline: String {
        lessonTitle.isEmpty ? AL.s(.talkSessionEnded) : lessonTitle
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    badge.padding(.top, 36)

                    Text(learnerName.isEmpty ? AL.s(.lcGreatJob) : AL.f(.lcCongrats, learnerName))
                        .font(DS.Font.ui(17, weight: .medium))
                        .foregroundStyle(DS.Colors.accent)
                        .padding(.top, 8)
                    Text(headline)
                        .font(DS.Font.display(32, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                        .padding(.horizontal, 8)
                    if !lessonTitle.isEmpty {
                        Label(AL.s(.talkLessonComplete), systemImage: "checkmark.seal.fill")
                            .font(DS.Font.ui(14, weight: .semibold))
                            .foregroundStyle(DS.Colors.accent)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(DS.Colors.accent.opacity(0.12), in: Capsule())
                            .padding(.top, 10)
                    }

                    HStack(spacing: 12) {
                        statTile("\(shownPhrases)", AL.s(.lcPhrases), "text.bubble")
                        statTile("\(shownMastery)%", AL.s(.lcMastery), "target")
                        statTile(durationText, AL.s(.lcTime), "clock")
                    }
                    .padding(.top, 30)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 14)
                    .animation(.easeOut(duration: 0.45).delay(0.25), value: appear)

                    if !phrases.isEmpty {
                        Text(AL.f(.lcNewPhrases, phrases.count))
                            .font(DS.Font.ui(15, weight: .semibold))
                            .foregroundStyle(DS.Colors.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 32)
                            .padding(.bottom, 12)
                        VStack(spacing: 10) {
                            ForEach(Array(phrases.enumerated()), id: \.element.id) { i, p in
                                phraseRow(p)
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 12)
                                    .animation(.easeOut(duration: 0.4).delay(0.45 + Double(i) * 0.06), value: appear)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 130)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }

            // Sabit alt düğme
            VStack(spacing: 0) {
                LinearGradient(colors: [DS.Colors.paper.opacity(0), DS.Colors.paper], startPoint: .top, endPoint: .bottom)
                    .frame(height: 28)
                Button(AL.s(.talkContinueNext), action: onContinue)
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(DS.Colors.paper)
            }
        }
        .paperBackground()
        .overlay(ConfettiBurst(origin: .top, count: 100, trigger: confetti).ignoresSafeArea())
        .task {
            Haptics.success()
            confetti += 1
            withAnimation(.spring(response: 0.6, dampingFraction: 0.62)) { appear = true }
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

    // MARK: - Rozet (hâle + tik)
    private var badge: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [DS.Colors.accent.opacity(0.22), DS.Colors.accent.opacity(0)],
                                     center: .center, startRadius: 10, endRadius: 120))
                .frame(width: 240, height: 240)
                .scaleEffect(appear ? 1 : 0.6)
            Circle()
                .fill(DS.Colors.accent)
                .frame(width: 104, height: 104)
                .shadow(color: DS.Colors.accent.opacity(0.35), radius: 18, y: 8)
                .scaleEffect(appear ? 1 : 0.3)
            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(DS.Colors.paper)
                .scaleEffect(appear ? 1 : 0.2)
                .rotationEffect(.degrees(appear ? 0 : -30))
        }
        .frame(height: 200)
    }

    private func statTile(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.Colors.accent)
            Text(value)
                .font(DS.Font.ui(24, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
            Text(label)
                .font(DS.Font.ui(13))
                .foregroundStyle(DS.Colors.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(DS.Colors.line))
    }

    private func phraseRow(_ p: Phrase) -> some View {
        Button { TutorVoice.shared.speak(p.text, langCode: targetCode) } label: {
            HStack(spacing: 14) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.accent)
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.accent.opacity(0.1), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.text)
                        .font(DS.Font.ui(17, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    if let tr = p.translation {
                        Text(tr).font(DS.Font.ui(14)).foregroundStyle(DS.Colors.muted)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(DS.Colors.line))
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
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6478985459?action=write-review")!
}
