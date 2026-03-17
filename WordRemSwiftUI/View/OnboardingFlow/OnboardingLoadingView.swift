//
//  OnboardingLoadingView.swift
//  WordRemSwiftUI
//
//  Step 3 of Duolingo-style Onboarding.
//  Shows a loading animation and signs the user in anonymously.
//

import SwiftUI

struct OnboardingLoadingView: View {
    let languageName: String
    
    @EnvironmentObject var authManager: AuthManager
    // Local ViewModel to trigger anonymous sign in
    @StateObject private var loginVM = LoginScreenViewModel(authManager: AuthManager())
    
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            Color(hex: "#1a1a2e").ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Mascot reading a book
                MascotAnimationView(width: 120, height: 120)
                
                VStack(spacing: 16) {
                    Text("YÜKLENİYOR...")
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                    
                    Text("İnsanlar WordRem'de, aynı süre boyunca bir sınıfta ders alan öğrencilerden daha fazla şey öğreniyor. Hem de evden çıkmalarına gerek kalmadan!")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(6)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appearAnimation = true
            loginVM.authManager = authManager
            startGame()
        }
    }
    
    private func startGame() {
        Task {
            // Fake loading delay for effect
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            
            do {
                try await loginVM.signAnonymously()
                
                // Switch root views
                await MainActor.run {
                    authManager.userIsLoggedIn = true
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
            } catch {
                print("❌ Guest login error during onboarding: \(error)")
                // Fallback: just open ContentView which will show LoginScreen
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
            }
        }
    }
}
