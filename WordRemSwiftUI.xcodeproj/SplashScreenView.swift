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
                    // Logo with Corner Radius
                    Image("appLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .shadow(
                            color: AppTheme.Colors.primaryOrange.opacity(0.4),
                            radius: 30,
                            y: 15
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // App Name
                    Text("Flash AI")
                        .font(.custom("Poppins-Bold", size: 48))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                        .opacity(logoOpacity)
                    
                    // Loading Indicator (opsiyonel)
                    ProgressView()
                        .tint(AppTheme.Colors.primaryOrange)
                        .scaleEffect(1.2)
                        .padding(.top, 20)
                        .opacity(logoOpacity * 0.7)
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
