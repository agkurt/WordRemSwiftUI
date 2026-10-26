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
            // Uygulama ikonunun zemin rengi: logo kenarsız, ikonla birebir aynı görünür
            Color(red: 247 / 255, green: 233 / 255, blue: 232 / 255).ignoresSafeArea()

            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .accessibilityLabel("WordRem AI")
        }
        .task {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = try? await DataService.shared.fetchUserProfile()
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                }
                await group.waitForAll()
            }

            onReady()
        }
    }
}

#Preview {
    LaunchScreenView(onReady: {})
}
