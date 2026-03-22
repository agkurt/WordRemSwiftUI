//
//  SplashScreenView.swift
//  WordRemSwiftUI
//

import SwiftUI

// MARK: - Shared Logo Text Component
struct WordRemLogoText: View {
    let size: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Text("WordRem")
                .font(.custom("Feather-Bold", size: size))
                .foregroundStyle(Color(hex: "#ae7979"))

            Text("AI")
                .font(.custom("Feather-Bold", size: size * 0.38))
                .foregroundStyle(.white)
                .padding(.horizontal, size * 0.18)
                .padding(.vertical, size * 0.1)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#7c3aed"), Color(hex: "#4f46e5")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: size * 0.16)
                )
                .shadow(color: Color(hex: "#7c3aed").opacity(0.45), radius: 8, y: 3)
                .padding(.bottom, size * 0.1)
        }
    }
}

// MARK: - Splash Screen (first launch / onboarding)
struct SplashScreenView: View {

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var sentenceViewModel: SentenceViewModel

    @State private var isActive   = false
    @State private var logoScale  : CGFloat = 0.75
    @State private var logoOpacity: Double  = 0.0

    var body: some View {
        if isActive {
            WelcomeView()
                .environmentObject(authManager)
                .environmentObject(sentenceViewModel)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#fdf4f4"), Color(hex: "#fff9f9"), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    WordRemLogoText(size: 48)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    LoadingAnimationView(width: 80, height: 80)
                        .opacity(logoOpacity)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                    logoScale   = 1.0
                    logoOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

// MARK: - Launch Screen (returning users — shown on every app open)
struct LaunchScreenView: View {

    let onReady: () -> Void

    @State private var logoScale  : CGFloat = 0.75
    @State private var logoOpacity: Double  = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#fdf4f4"), Color(hex: "#fff9f9"), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                WordRemLogoText(size: 48)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                LoadingAnimationView(width: 80, height: 80)
                    .opacity(logoOpacity)
            }
        }
        .task {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = try? await SupabaseDataService.shared.fetchUserProfile()
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
    SplashScreenView()
}
