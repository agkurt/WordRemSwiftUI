//
//  DailyGoalBreakPopupView.swift
//  WordRemSwiftUI
//
//  Günlük çalışma hedefi dolduğunda gösterilen mola popup'ı.
//  Kâğıt kart, serif başlık, iki buton (Devam Et / Mola Ver).
//

import SwiftUI

struct DailyGoalBreakPopupView: View {

    let minutesStudied: Int
    let onDismiss: () -> Void

    @EnvironmentObject var langManager: LanguageManager

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            PaperCard(padding: 28) {
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow(text: String(format: langManager.s(.dailyBreakBodyFormat), minutesStudied),
                            color: DS.Colors.success)

                    Text(langManager.s(.dailyBreakTitle))
                        .font(DS.Font.display(30, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(langManager.s(.dailyBreakSubtitle))
                        .font(DS.Font.ui(16))
                        .foregroundStyle(DS.Colors.muted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        Button(langManager.s(.dailyBreakContinue)) { dismiss() }
                            .buttonStyle(InkButtonStyle())
                        Button(langManager.s(.dailyBreakRest)) { dismiss() }
                            .buttonStyle(OutlineButtonStyle())
                    }
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

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.18)) { appear = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}
