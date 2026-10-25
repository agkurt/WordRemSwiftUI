//
//  OnboardingLoadingView.swift
//  WordRemSwiftUI
//
//  Step 3 of Duolingo-style Onboarding.
//  Shows a loading animation and signs the user in anonymously.
//

import SwiftUI

struct OnboardingLoadingView: View {
    @EnvironmentObject var langManager: LanguageManager
    let languageName: String
    let languageCode: String
    let proficiencyLevel: Int
    var learningInterest: String = ""
    var dailyGoalMinutes: Int = 10
    var nativeLangCode: String = OL.nativeLangCode

    @EnvironmentObject var authManager: AuthManager
    @State private var signInFailed = false

    var body: some View {
        ZStack {
            Color(hex: "#1a1a2e").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                LoadingAnimationView(width: 160, height: 160)
                if signInFailed {
                    VStack(spacing: 16) {
                        Text(AL.s(.loadFailedMessage))
                            .font(.custom("Feather-Bold", size: 16))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button {
                            signInFailed = false
                            startGame()
                        } label: {
                            Text(AL.s(.paywallRetry))
                                .font(.custom("Feather-Bold", size: 16))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(AppTheme.Colors.primaryOrange, in: Capsule())
                        }
                    }
                } else {
                VStack(spacing: 16) {
                    Text(langManager.s(.loadingText))
                        .font(.custom("Feather-Bold", size: 18))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                    Text(langManager.s(.loadingMessage))
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(6)
                }
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
            // Anadil: hem UserDefaults'a hem LanguageManager'a yaz
            langManager.setLanguage(nativeLangCode)
            if !learningInterest.isEmpty {
                UserDefaults.standard.set(learningInterest, forKey: "learningInterest")
            }

            // Yükleme animasyonu için kısa bekleme
            try? await Task.sleep(nanoseconds: 2_500_000_000)

            // Uygulama yeniden kurulduğunda Keychain'de eski session kalabilir.
            // Yeni misafir başlatmadan önce mutlaka mevcut oturumu kapat.
            if SupabaseAuthService.shared.isSignedIn {
                try? await SupabaseAuthService.shared.signOut()
                // Sign-out'un Supabase tarafında işlenmesi için kısa bekleme
                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            // Supabase anonim giriş — oturum olmadan uygulama çalışmaz; hata olursa tekrar dene ekranı
            do {
                try await SupabaseAuthService.shared.signInAnonymously()
                let guestName = "Guest-\(Int.random(in: 1000...9999))"
                try? await SupabaseAuthService.shared.ensureUserRow(username: guestName)
                print("✅ Anonymous login success")
            } catch {
                print("⚠️ Anonymous login failed: \(error.localizedDescription)")
                await MainActor.run { signInFailed = true }
                return
            }

            // Supabase'e TÜM tercihleri kaydet (arka planda, başarısız olsa da devam et)
            Task {
                try? await SupabaseDataService.shared.saveUserPreferences(
                    targetLangCode: languageCode,
                    nativeLangCode: nativeLangCode,
                    proficiencyLevel: proficiencyLevel,
                    learningInterest: learningInterest,
                    dailyGoalMinutes: dailyGoalMinutes
                )
            }

            // Oturum açıldı → ana uygulamaya geç
            await MainActor.run {
                authManager.userIsLoggedIn = true
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        }
    }
}
