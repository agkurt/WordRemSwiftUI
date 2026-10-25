//
//  LanguageSelectionView.swift
//  WordRemSwiftUI
//
//  Step 1 of Duolingo-style Onboarding.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var langManager: LanguageManager
    let nativeLangCode: String          // NativeLanguageSelectionView'dan gelir

    @State private var selectedLanguage: String?
    @State private var navigateToProficiency = false

    // Tüm diller
    private let allLanguages: [(flag: String, name: String, code: String)] = [
        ("🇹🇷", "Türkçe", "tr"),
        ("🇬🇧", "İngilizce", "en"),
        ("🇩🇪", "Almanca", "de"),
        ("🇷🇺", "Rusça", "ru"),
        ("🇨🇳", "Çince", "zh"),
        ("🇫🇷", "Fransızca", "fr"),
        ("🇮🇹", "İtalyanca", "it"),
        ("🇪🇸", "İspanyolca", "es")
    ]

    // Seçilen anadili listeden çıkar — kendi anadilini öğrenmek mantıksız
    var availableLanguages: [(flag: String, name: String, code: String)] {
        allLanguages.filter { $0.code.lowercased() != nativeLangCode.lowercased() }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            OBProgressBar(total: 2, filled: 1)

            // Header — alt başlık seçilen anadile göre dinamik ("Türkçe bilenler için" vs.)
            OBHeader(
                title: langManager.s(.whatToLearn),
                subtitle: langManager.forSpeakersSubtitle(nativeLangCode: nativeLangCode)
            )

            // Language List — isimler telefon diline göre
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(availableLanguages, id: \.code) { lang in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedLanguage = lang.name
                            }
                        }) {
                            HStack(spacing: 14) {
                                Text(lang.flag)
                                    .font(.system(size: 26))
                                    .frame(width: 36)

                                Text(langManager.languageName(for: lang.code))
                                    .font(DS.Font.ui(17, weight: .medium))
                                    .foregroundStyle(DS.Colors.ink)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                OBCheckmark(isSelected: selectedLanguage == lang.name)
                            }
                            .modifier(OBSelectableCard(isSelected: selectedLanguage == lang.name))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .obContentWidth()
            }

            // Bottom Continue Button
            OBBottomBar {
                Button(action: {
                    navigateToProficiency = true
                }) {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
                .obDisabled(selectedLanguage == nil)
            }
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToProficiency) {
            let code = availableLanguages.first(where: { $0.name == selectedLanguage })?.code ?? "en"
            ProficiencyView(
                selectedLanguageName: langManager.languageName(for: code),
                selectedLanguageCode: code,
                nativeLangCode: nativeLangCode
            )
        }
    }
}

#Preview {
    NavigationStack { LanguageSelectionView(nativeLangCode: "tr") }
}
