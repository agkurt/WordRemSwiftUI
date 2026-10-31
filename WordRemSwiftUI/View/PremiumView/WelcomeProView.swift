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
                    // Sayfaya basılan "Pro" mührü
                    InkStamp(top: "WORDREM",
                             title: "Pro",
                             bottom: Date().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))).uppercased(),
                             size: 150)
                        .scaleEffect(appear ? 1 : 2.2)
                        .opacity(appear ? 1 : 0)
                        .frame(height: 170)
                        .padding(.top, 8)

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
                                PenTick()
                                    .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    .frame(width: 26, height: 22)
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
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.55).delay(0.15)) { appear = true }
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
