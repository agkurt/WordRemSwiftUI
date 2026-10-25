//
//  WelcomeView.swift
//  WordRemSwiftUI
//
//  İlk açılış ekranı — yazı markası, değer önerisi ve örnek bir kelime kartı.
//

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject var langManager: LanguageManager
    @State private var navigateToLanguage = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                WordRemLogoText(size: 22)
                    .padding(.top, 12)

                Spacer(minLength: 24)

                Text(langManager.s(.welcomeTagline))
                    .font(DS.Font.display(40, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                sampleCard
                    .padding(.top, 32)

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    Button(langManager.s(.welcomeStart)) { navigateToLanguage = true }
                        .buttonStyle(InkButtonStyle())
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .paperBackground()
            .navigationDestination(isPresented: $navigateToLanguage) {
                NativeLanguageSelectionView()
            }
        }
    }

    /// Uygulamanın ne yaptığını gösteren örnek kart (widget ile aynı dil)
    private var sampleCard: some View {
        PaperCard(padding: 22) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: Locale(identifier: langManager.currentLanguageCode)
                    .localizedString(forLanguageCode: "es") ?? "Español")
                Text("aprender")
                    .font(DS.Font.display(34, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .padding(.top, 14)
                Text("/a.pɾenˈdeɾ/")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(DS.Colors.muted)
                    .padding(.top, 2)
                Rectangle().fill(DS.Colors.accent).frame(width: 24, height: 2)
                    .padding(.top, 16)
                Text(Locale(identifier: langManager.currentLanguageCode).language.languageCode?.identifier == "tr"
                     ? "öğrenmek" : "to learn")
                    .font(DS.Font.ui(17, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .padding(.top, 10)
            }
        }
        .rotationEffect(.degrees(-1.5))
    }
}

#Preview {
    WelcomeView()
        .environmentObject(LanguageManager.shared)
}
