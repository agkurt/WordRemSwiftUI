//
//  SplashScreenView.swift
//  WordRemSwiftUI
//
//  Splash screen with logo animation
//

import SwiftUI

struct SplashScreenView: View {
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var sentenceViewModel: SentenceViewModel
    
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        if isActive {
            // Splash ekranı bittikten sonra Welcome ekranına geç
            WelcomeView()
                .environmentObject(authManager)
                .environmentObject(sentenceViewModel)
        } else {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color(hex: "#fef3c7"),
                        Color(hex: "#fff7ed"),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Logo
                    Image("appLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .shadow(
                            color: AppTheme.Colors.primaryOrange.opacity(0.4),
                            radius: 30,
                            y: 15
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // App Name
                    Text("WordRem AI")
                        .font(.custom("Feather-Bold", size: 48))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                        .opacity(logoOpacity)
                    
                    // Lottie loading animation
                    LoadingAnimationView(width: 80, height: 80)
                        .padding(.top, 8)
                        .opacity(logoOpacity)
                }
            }
            .onAppear {
                // Logo animasyonu
                withAnimation(.easeOut(duration: 1.0)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                // 2.5 saniye sonra Welcome ekranına geç
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

// MARK: - Launch Screen (returning users — shown on every app open)

struct LaunchScreenView: View {

    let onReady: () -> Void

    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#fef3c7"),
                    Color(hex: "#fff7ed"),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("appLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(
                        color: AppTheme.Colors.primaryOrange.opacity(0.4),
                        radius: 30,
                        y: 15
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("WordRem AI")
                    .font(.custom("Feather-Bold", size: 48))
                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                    .opacity(logoOpacity)

                LoadingAnimationView(width: 80, height: 80)
                    .padding(.top, 8)
                    .opacity(logoOpacity)
            }
        }
        .task {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Prefetch user profile and wait at least 2.5 seconds (concurrent)
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
