//
//  AchievementUnlockPopup.swift
//  WordRemSwiftUI
//
//  Yeni bir başarım kazanıldığında gösterilen sade kâğıt modal.
//  Dokununca ya da 4.5 sn sonra kapanır.
//

import SwiftUI

struct AchievementUnlockPopup: View {

    @EnvironmentObject var langManager: LanguageManager
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            PaperCard(padding: 28) {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: outlineSymbol(achievement.icon))
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(DS.Colors.gold)
                        .frame(width: 56, height: 56)
                        .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Eyebrow(text: plain(langManager.s(.achievementNewUnlocked)), color: DS.Colors.gold)
                            Text("·").foregroundStyle(DS.Colors.muted)
                            Eyebrow(text: achievement.rarity.label, color: DS.Colors.muted)
                        }
                        Text(achievement.title)
                            .font(DS.Font.display(30, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(achievement.description)
                            .font(DS.Font.ui(16))
                            .foregroundStyle(DS.Colors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(langManager.s(.achievementTapToDismiss))
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.top, 4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { dismiss() }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .offset(y: appear ? 0 : 12)
        }
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { appear = true }
            // Auto-dismiss after 4.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 4_500_000_000)
                dismiss()
            }
        }
    }

    /// Dolgulu SF Symbol adlarını outline karşılığına indirger.
    private func outlineSymbol(_ name: String) -> String {
        let stripped = name.replacingOccurrences(of: ".fill", with: "")
        return UIImage(systemName: stripped) != nil ? stripped : name
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

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) { appear = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}
