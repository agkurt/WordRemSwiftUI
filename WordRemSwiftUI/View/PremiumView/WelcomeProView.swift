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

    private var features: [(String, String)] {[
        (langManager.s(.paywallFeature1), langManager.s(.paywallFeature1Sub)),
        (langManager.s(.paywallFeature2), langManager.s(.paywallFeature2Sub)),
        (langManager.s(.paywallFeature3), langManager.s(.paywallFeature3Sub)),
        (langManager.s(.paywallFeature4), langManager.s(.paywallFeature4Sub)),
    ]}

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                PaperCard(padding: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: plain(langManager.s(.welcomeProTitle)), color: DS.Colors.slate)
                            Text("WordRem Pro")
                                .font(DS.Font.display(34, weight: .bold))
                                .foregroundStyle(DS.Colors.ink)
                            Text(plain(langManager.s(.welcomeProSubtitle)))
                                .font(DS.Font.ui(16))
                                .foregroundStyle(DS.Colors.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(spacing: 0) {
                            Rectangle().fill(DS.Colors.line).frame(height: 1)
                            ForEach(features, id: \.0) { title, sub in
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(DS.Colors.accent)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(title)
                                            .font(DS.Font.ui(16, weight: .semibold))
                                            .foregroundStyle(DS.Colors.ink)
                                        Text(sub)
                                            .font(DS.Font.ui(14))
                                            .foregroundStyle(DS.Colors.muted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 12)
                                Rectangle().fill(DS.Colors.line).frame(height: 1)
                            }
                        }

                        Button(plain(langManager.s(.welcomeProCTA)), action: onContinue)
                            .buttonStyle(InkButtonStyle())
                            .padding(.top, 8)
                    }
                }
                .frame(maxWidth: 440)
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            }
            .offset(y: appear ? 0 : 12)
            .opacity(appear ? 1 : 0)
        }
        .presentationBackground(.clear)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) { appear = true }
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
