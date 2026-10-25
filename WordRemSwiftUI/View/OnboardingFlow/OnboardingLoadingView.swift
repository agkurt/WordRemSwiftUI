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
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                if signInFailed {
                    Text(AL.s(.loadFailedMessage))
                        .font(DS.Font.display(28, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        signInFailed = false
                        startGame()
                    } label: {
                        Text(AL.s(.paywallRetry))
                    }
                    .buttonStyle(InkButtonStyle())
                    .padding(.top, 8)
                } else {
                    Eyebrow(text: langManager.s(.loadingText), color: DS.Colors.muted)

                    Text(langManager.s(.loadingMessage))
                        .font(DS.Font.display(30, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(DS.Colors.ink)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .obContentWidth()

            Spacer()
            Spacer()
        }
        .paperBackground()
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
