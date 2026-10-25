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

    @EnvironmentObject var langManager: LanguageManager

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
    @State private var selectedCode: String = OL.nativeLangCode
    @State private var navigateToLanguage = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Progress Bar (adım 0/2) ─────────────────────────────
            OBProgressBar(total: 2, filled: 1)

            // ── Header ──────────────────────────────────────────────
            OBHeader(
                title: langManager.s(.nativeLangTitle),
                subtitle: langManager.s(.nativeLangHint)
            )

            // ── Language List ───────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(allNativeLanguages, id: \.code) { lang in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedCode = lang.code
                                // Seçilen dili anlık uygula — onboarding metinleri de bu dile geçer
                                langManager.setLanguage(lang.code)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(lang.flag)
                                    .font(.system(size: 26))
                                    .frame(width: 36)

                                Text(langManager.languageName(for: lang.code))
                                    .font(DS.Font.ui(17, weight: .medium))
                                    .foregroundStyle(DS.Colors.ink)

                                Spacer()

                                OBCheckmark(isSelected: selectedCode == lang.code)
                            }
                            .modifier(OBSelectableCard(isSelected: selectedCode == lang.code))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .obContentWidth()
            }

            // ── Continue Button ─────────────────────────────────────
            OBBottomBar {
                Button {
                    navigateToLanguage = true
                } label: {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
            }
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToLanguage) {
            LanguageSelectionView(nativeLangCode: selectedCode)
        }
    }
}

// MARK: - Shared onboarding building blocks ("paper & ink")

extension View {
    /// iPad'de içeriği kenardan kenara yaymamak için genişliği sınırlar
    func obContentWidth() -> some View {
        frame(maxWidth: 620).frame(maxWidth: .infinity)
    }
}

/// İnce adım göstergesi: çizgi rengi iz, mürekkep dolgu
struct OBProgressBar: View {
    let total: Int
    let filled: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i < filled ? DS.Colors.ink : DS.Colors.line)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .obContentWidth()
    }
}

/// Sola hizalı başlık: opsiyonel eyebrow, serif soru, opsiyonel açıklama
struct OBHeader: View {
    var eyebrow: String? = nil
    let title: String
    var subtitle: String? = nil
    var titleSize: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let eyebrow {
                Eyebrow(text: eyebrow)
            }
            Text(title)
                .font(DS.Font.display(titleSize, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .obContentWidth()
    }
}

/// Düz seçenek kartı: paperRaised zemin, 1pt çizgi; seçiliyken 1.5pt mürekkep kenar
struct OBSelectableCard: ViewModifier {
    let isSelected: Bool
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isSelected ? DS.Colors.ink : DS.Colors.line,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Seçim işareti — yer kaplamaya devam eder, böylece satır kaymaz
struct OBCheckmark: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20))
            .foregroundStyle(DS.Colors.ink)
            .opacity(isSelected ? 1 : 0)
    }
}

/// Alt eylem alanı: üstte ince çizgi, kâğıt zemin
struct OBBottomBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DS.Colors.line)
                .frame(height: 1)
            content
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .obContentWidth()
        }
        .background(DS.Colors.paper)
    }
}

extension View {
    /// Ink CTA'nın pasif hali: aynı stil, düşük opaklık
    func obDisabled(_ disabled: Bool) -> some View {
        self.disabled(disabled).opacity(disabled ? 0.35 : 1)
    }
}

#Preview {
    NavigationStack {
        NativeLanguageSelectionView()
    }
}
