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
    let languageCode: String
    let proficiencyLevel: Int

    @EnvironmentObject var authManager: AuthManager
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
                    Text(OL.s(.loadingText))
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundStyle(Color(hex: "#94a3b8"))

                    Text(OL.s(.loadingMessage))
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
            try? await Task.sleep(nanoseconds: 2_500_000_000)

            do {
                try await loginVM.signAnonymously()

                // Onboarding tercihlerini UserDefaults'a kaydet
                UserDefaults.standard.set(languageCode, forKey: "selectedTargetLanguageCode")
                UserDefaults.standard.set(languageName, forKey: "selectedTargetLanguageName")
                UserDefaults.standard.set(proficiencyLevel, forKey: "selectedProficiencyLevel")

                // Supabase'e kaydet (arka planda, başarısız olsa da devam et)
                Task {
                    try? await SupabaseDataService.shared.saveUserPreferences(
                        targetLangCode: languageCode,
                        proficiencyLevel: proficiencyLevel
                    )
                }

                await MainActor.run {
                    authManager.userIsLoggedIn = true
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
            } catch {
                print("❌ Guest login error during onboarding: \(error)")
                // Dil tercihlerini yine de kaydet
                UserDefaults.standard.set(languageCode, forKey: "selectedTargetLanguageCode")
                UserDefaults.standard.set(languageName, forKey: "selectedTargetLanguageName")
                UserDefaults.standard.set(proficiencyLevel, forKey: "selectedProficiencyLevel")

                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
            }
        }
    }
}
