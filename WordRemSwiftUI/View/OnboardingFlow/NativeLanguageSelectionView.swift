//
//  NativeLanguageSelectionView.swift
//  WordRemSwiftUI
//
//  Onboarding Step 0 — Kullanıcının anadilini seçtiği ekran.
//  Telefon dilinden bağımsız olarak tüm desteklenen diller listelenir.
//  Seçilen anadil LanguageSelectionView'a iletilir ve oraya filtre uygulanır.
//

import SwiftUI

struct NativeLanguageSelectionView: View {

    // Tüm desteklenen diller — burada filtreleme YOK
    private let allNativeLanguages: [(flag: String, code: String)] = [
        ("🇹🇷", "tr"),
        ("🇬🇧", "en"),
        ("🇩🇪", "de"),
        ("🇫🇷", "fr"),
        ("🇪🇸", "es"),
        ("🇮🇹", "it"),
        ("🇷🇺", "ru"),
        ("🇨🇳", "zh"),
    ]

    // Telefon dilini varsayılan olarak seç — kullanıcı değiştirebilir
    @State private var selectedCode: String = OL.phoneCode
    @State private var navigateToLanguage = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Progress Bar (adım 0/2) ─────────────────────────────
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

            // ── Mascot + Speech Bubble ──────────────────────────────
            HStack(alignment: .top, spacing: 16) {
                MascotAnimationView(width: 70, height: 70)

                VStack(alignment: .leading, spacing: 6) {
                    Text(OL.s(.nativeLangTitle))
                        .font(.custom("Feather-Bold", size: 18))
                        .foregroundStyle(Color(hex: "#1e293b"))
                    Text(OL.s(.nativeLangHint))
                        .font(.custom("Feather-Bold", size: 13))
                        .foregroundStyle(Color(hex: "#64748b"))
                }
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

            // ── Language List ───────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(allNativeLanguages, id: \.code) { lang in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedCode = lang.code
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Text(lang.flag)
                                    .font(.system(size: 28))
                                    .frame(width: 40)

                                Text(OL.languageName(for: lang.code))
                                    .font(.custom("Feather-Bold", size: 15))
                                    .foregroundStyle(Color(hex: "#1e293b"))

                                Spacer()

                                if selectedCode == lang.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCode == lang.code
                                          ? AppTheme.Colors.primaryOrange.opacity(0.08)
                                          : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedCode == lang.code
                                            ? AppTheme.Colors.primaryOrange
                                            : Color(hex: "#e2e8f0"), lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            // ── Continue Button ─────────────────────────────────────
            VStack {
                Divider()
                Button {
                    navigateToLanguage = true
                } label: {
                    Text(OL.s(.continueButton))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.Colors.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .background(Color(hex: "#f8fafc").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToLanguage) {
            LanguageSelectionView(nativeLangCode: selectedCode)
        }
    }
}

#Preview {
    NavigationStack {
        NativeLanguageSelectionView()
    }
}
