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
    var learningInterest: String = ""
    var dailyGoalMinutes: Int = 10

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            Color(hex: "#1a1a2e").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                LoadingAnimationView(width: 160, height: 160)
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
        .onAppear { startGame() }
    }

    private func startGame() {
        Task {
            // Dil tercihlerini hemen kaydet
            UserDefaults.standard.set(languageCode, forKey: "selectedTargetLanguageCode")
            UserDefaults.standard.set(languageName, forKey: "selectedTargetLanguageName")
            UserDefaults.standard.set(proficiencyLevel, forKey: "selectedProficiencyLevel")
            UserDefaults.standard.set(dailyGoalMinutes, forKey: "dailyGoalMinutes")
            if !learningInterest.isEmpty {
                UserDefaults.standard.set(learningInterest, forKey: "learningInterest")
            }

            // Yükleme animasyonu için kısa bekleme
            try? await Task.sleep(nanoseconds: 2_500_000_000)

            // Supabase anonim giriş — hata olsa bile ilerle
            do {
                try await SupabaseAuthService.shared.signInAnonymously()
                let guestName = "Guest-\(Int.random(in: 1000...9999))"
                try? await SupabaseAuthService.shared.ensureUserRow(username: guestName)
                print("✅ Anonymous login success")
            } catch {
                print("⚠️ Anonymous login failed, continuing anyway: \(error.localizedDescription)")
            }

            // Supabase'e TÜM tercihleri kaydet (arka planda, başarısız olsa da devam et)
            Task {
                try? await SupabaseDataService.shared.saveUserPreferences(
                    targetLangCode: languageCode,
                    nativeLangCode: OL.phoneCode,
                    proficiencyLevel: proficiencyLevel,
                    learningInterest: learningInterest,
                    dailyGoalMinutes: dailyGoalMinutes
                )
            }

            // HER DURUMDA ana uygulamaya geç
            await MainActor.run {
                authManager.userIsLoggedIn = true
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        }
    }
}
