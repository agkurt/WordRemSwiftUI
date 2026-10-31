//
//  LaunchScreenView.swift
//  WordRemSwiftUI
//

import SwiftUI

// MARK: - Shared Logo Text Component
struct WordRemLogoText: View {
    let size: CGFloat

    var body: some View {
        // Serif yazı markası + imza renginde nokta
        (Text("WordRem")
            .foregroundColor(DS.Colors.ink)
         + Text(".")
            .foregroundColor(DS.Colors.accent))
            .font(DS.Font.display(size, weight: .bold))
            .accessibilityLabel("WordRem")
    }
}
// MARK: - Launch Screen (returning users — shown on every app open)
struct LaunchScreenView: View {

    let onReady: () -> Void

    @State private var logoScale  : CGFloat = 0.75
    @State private var logoOpacity: Double  = 0.0

    var body: some View {
        ZStack {
            // Açılış defterin kapağıdır: arduvaz bez, üstten sarkan ayraçlar, ortada etiket
            NotebookCover().ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    BookmarkMark(mood: .speaking, width: 17,
                                 colors: [DS.Colors.ink, DS.Colors.accent, DS.Colors.paper, DS.Colors.margin])
                        .padding(.trailing, 40)
                }
                Spacer()
            }

            HStack(alignment: .center, spacing: 10) {
                WordRemLogoText(size: 44)
                Text("AI")
                    .font(DS.Font.ui(15, weight: .bold))
                    .foregroundStyle(DS.Colors.paper)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DS.Colors.accent, in: RoundedRectangle(cornerRadius: 8))
                    .offset(y: 3)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 8))
            .rotationEffect(.degrees(-1))
            .shadow(color: .black.opacity(0.22), radius: 14, y: 10)
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("WordRem AI")
        }
        .task {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }

            // Profil gelince geç; yavaş ağda en fazla 4 sn bekle. Logo en az 2 sn görünür:
            // bu sırada arka planda RevenueCat, Firebase ve Game Center hazırlanır
            let start = Date()
            // Profil isteği iptal edilmesin; geç gelirse arka planda tamamlansın
            let profile = Task { _ = try? await DataService.shared.fetchUserProfile() }
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await profile.value }
                group.addTask { try? await Task.sleep(nanoseconds: 4_000_000_000) }
                await group.next()
                group.cancelAll()
            }
            let remaining = 2.0 - Date().timeIntervalSince(start)
            if remaining > 0 { try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000)) }

            onReady()
        }
    }
}

#Preview {
    LaunchScreenView(onReady: {})
}
