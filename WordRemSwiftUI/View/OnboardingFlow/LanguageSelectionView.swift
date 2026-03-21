//
//  LanguageSelectionView.swift
//  WordRemSwiftUI
//
//  Step 1 of Duolingo-style Onboarding.
//

import SwiftUI

struct LanguageSelectionView: View {
    @State private var selectedLanguage: String?
    @State private var navigateToProficiency = false
    
    // Tüm diller
    private let allLanguages: [(flag: String, name: String, code: String)] = [
        ("🇬🇧", "İngilizce", "en"),
        ("🇩🇪", "Almanca", "de"),
        ("🇷🇺", "Rusça", "ru"),
        ("🇨🇳", "Çince", "zh"),
        ("🇫🇷", "Fransızca", "fr"),
        ("🇮🇹", "İtalyanca", "it"),
        ("🇪🇸", "İspanyolca", "es")
    ]

    // Telefon dilini listeden çıkar — kendi ana dilini öğrenmek mantıksız
    var availableLanguages: [(flag: String, name: String, code: String)] {
        let phoneCode = OL.phoneCode.lowercased()
        return allLanguages.filter { $0.code.lowercased() != phoneCode }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            HStack(spacing: 8) {
                Capsule()
                    .fill(AppTheme.Colors.primaryOrange)
                    .frame(height: 12)
                Capsule()
                    .fill(Color(hex: "#e2e8f0"))
                    .frame(height: 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Character & Speech Bubble
            HStack(alignment: .top, spacing: 16) {
                MascotAnimationView(width: 70, height: 70)

                Text(OL.s(.whatToLearn))
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundStyle(Color(hex: "#1e293b"))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    )
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 20))
                            path.addLine(to: CGPoint(x: -10, y: 25))
                            path.addLine(to: CGPoint(x: 0, y: 30))
                        }
                        .fill(Color.white)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Subtitle — telefon diline göre dinamik ("For English speakers" vs.)
            HStack {
                Text(OL.forSpeakersSubtitle)
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.up")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            // Language List — isimler telefon diline göre
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(availableLanguages, id: \.code) { lang in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedLanguage = lang.name
                            }
                        }) {
                            HStack(spacing: 16) {
                                Text(lang.flag)
                                    .font(.system(size: 28))
                                    .frame(width: 40)

                                Text(OL.languageName(for: lang.code))
                                    .font(.custom("Poppins-SemiBold", size: 15))
                                    .foregroundStyle(Color(hex: "#1e293b"))
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedLanguage == lang.name ? AppTheme.Colors.primaryOrange.opacity(0.1) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedLanguage == lang.name ? AppTheme.Colors.primaryOrange : Color(hex: "#e2e8f0"), lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            // Bottom Continue Button
            VStack {
                Divider()
                Button(action: {
                    navigateToProficiency = true
                }) {
                    Text(OL.s(.continueButton))
                        .font(.custom("Poppins-Bold", size: 17))
                        .foregroundStyle(selectedLanguage == nil ? Color(hex: "#94a3b8") : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedLanguage == nil ? Color(hex: "#e2e8f0") : AppTheme.Colors.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: selectedLanguage == nil ? .clear : AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(selectedLanguage == nil)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .background(Color(hex: "#f8fafc").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToProficiency) {
            let code = availableLanguages.first(where: { $0.name == selectedLanguage })?.code ?? "en"
            ProficiencyView(
                selectedLanguageName: selectedLanguage ?? "İngilizce",
                selectedLanguageCode: code
            )
        }
    }
}

#Preview {
    LanguageSelectionView()
}
