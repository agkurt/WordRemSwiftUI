//
//  WelcomePopupView.swift
//  WordRemSwiftUI
//
//  Hesap bazlı hoşgeldin popup'ı.
//  - İlk giriş → yeni kullanıcı karşılama (özellik listesi)
//  - Sonraki girişler → geri dönüş mesajı
//

import SwiftUI

// MARK: - Popup Türü

enum WelcomePopupType {
    case newUser(name: String)
    case returning(name: String)

    var name: String {
        switch self {
        case .newUser(let n), .returning(let n): return n
        }
    }

    var isNew: Bool {
        if case .newUser = self { return true }
        return false
    }
}

// MARK: - WelcomePopupView

struct WelcomePopupView: View {

    @EnvironmentObject var langManager: LanguageManager

    let type: WelcomePopupType
    let onDismiss: () -> Void

    @State private var appear = false

    private var isNew: Bool { type.isNew }
    private var name: String { type.name }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            PaperCard(padding: 28) {
                VStack(alignment: .leading, spacing: 16) {
                    if isNew {
                        newUserContent
                    } else {
                        returningUserContent
                    }

                    Button(isNew ? langManager.s(.welcomeNewCTA) : langManager.s(.welcomeBackCTA),
                           action: dismiss)
                        .buttonStyle(InkButtonStyle())
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .offset(y: appear ? 0 : 12)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appear = true }
        }
    }

    // MARK: - New User Content

    @ViewBuilder
    private var newUserContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: plain(langManager.s(.welcomeNewSubtitle)))
            Text(plain(langManager.s(.welcomeNewTitle)))
                .font(DS.Font.display(30, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }

        VStack(spacing: 0) {
            Rectangle().fill(DS.Colors.line).frame(height: 1)
            ForEach([langManager.s(.welcomeNewFeature1),
                     langManager.s(.welcomeNewFeature2),
                     langManager.s(.welcomeNewFeature3)], id: \.self) { text in
                Text(plain(text))
                    .font(DS.Font.ui(16))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                Rectangle().fill(DS.Colors.line).frame(height: 1)
            }
        }
    }

    // MARK: - Returning User Content

    @ViewBuilder
    private var returningUserContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: plain(langManager.f(.welcomeBackMessageFormat, name)))
            Text(plain(langManager.s(.welcomeBackTitle)))
                .font(DS.Font.display(30, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }

        Text(plain(langManager.s(.welcomeBackMotivation)))
            .font(DS.Font.ui(16))
            .foregroundStyle(DS.Colors.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

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

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.18)) { appear = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
