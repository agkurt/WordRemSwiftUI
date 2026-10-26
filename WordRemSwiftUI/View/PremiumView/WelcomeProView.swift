//
//  WelcomeProView.swift
//  WordRemSwiftUI
//
//  Satın alma başarılı olduğunda gösterilen hoşgeldin popup'ı.
//

import SwiftUI

struct WelcomeProView: View {

    @EnvironmentObject var langManager: LanguageManager
    var onContinue: () -> Void

    @State private var appear = false
    @State private var burst = 0

    // Paywall'da vaat edilenlerle birebir aynı maddeler
    private var features: [(String, String, String)] {[
        ("waveform.circle", AL.s(.pwTalkTitle), AL.s(.pwTalkSub)),
        ("map", AL.s(.pwPlanTitle), AL.s(.pwPlanSub)),
        ("checkmark.bubble", AL.s(.pwFixTitle), AL.s(.pwFixSub)),
        ("bookmark", AL.s(.pwRemTitle), AL.s(.pwRemSub)),
    ]}

    var body: some View {
        ZStack {
            DS.Colors.paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Kutlama rozeti
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [DS.Colors.accent.opacity(0.22), DS.Colors.accent.opacity(0)],
                                                 center: .center, startRadius: 8, endRadius: 110))
                            .frame(width: 170, height: 170)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(DS.Colors.paper)
                            .frame(width: 76, height: 76)
                            .background(DS.Colors.accent, in: Circle())
                            .scaleEffect(appear ? 1 : 0.4)
                            .rotationEffect(.degrees(appear ? 0 : -25))
                    }
                    .frame(height: 140)
                    .padding(.top, 8)

                    Text("WORDREM PRO")
                        .font(DS.Font.ui(13, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(DS.Colors.accent)
                        .padding(.top, 4)
                    Text(AL.s(.proWelcomeTitle))
                        .font(DS.Font.display(30, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                    Text(AL.s(.proWelcomeSub))
                        .font(DS.Font.ui(16))
                        .foregroundStyle(DS.Colors.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.offset) { i, f in
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: f.0)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(DS.Colors.accent)
                                    .frame(width: 24)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(f.1)
                                        .font(DS.Font.ui(17, weight: .semibold))
                                        .foregroundStyle(DS.Colors.ink)
                                    Text(f.2)
                                        .font(DS.Font.ui(14))
                                        .foregroundStyle(DS.Colors.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 7)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.35 + Double(i) * 0.08), value: appear)
                        }
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Düğme her zaman görünür: kaydırmaya gerek yok
                Button(AL.s(.proWelcomeCTA), action: onContinue)
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 28)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .background(DS.Colors.paper)
            }
            ConfettiBurst(origin: .top, count: 90, trigger: burst).ignoresSafeArea()
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) { appear = true }
            burst += 1
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
    WelcomeProView(onContinue: {})
        .environmentObject(LanguageManager.shared)
}
