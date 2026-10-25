//
//  AuthManager.swift
//  WordRemSwiftUI
//
//  Hesap/giriş sistemi yok: kullanıcı onboarding'i bitirince uygulamayı kullanır,
//  ilerlemesi cihazda + iCloud'da tutulur. Bu sınıf yalnızca uygulama genelindeki
//  oturum durumunu ve "ilerlemeyi sıfırla" işlemini yönetir.
//

import SwiftUI
import RevenueCat

@MainActor
final class AuthManager: ObservableObject {

    /// Onboarding tamamlandıysa uygulama açılır
    @Published var userIsLoggedIn: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    /// Ana ekranda bir kez gösterilecek karşılama popup'ı
    @Published var pendingWelcome: WelcomePopupType? = nil

    @Published var isResetting = false

    /// Onboarding sonunda çağrılır
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        pendingWelcome = .newUser(name: UserStore.shared.snapshot.username)
        userIsLoggedIn = true
    }

    /// Tüm ilerlemeyi, desteleri ve öğrenilen kelimeleri bu cihazdan ve iCloud'dan siler,
    /// uygulamayı onboarding'e döndürür.
    func resetAllProgress() {
        isResetting = true
        UserStore.shared.reset()
        DeckService.shared.deleteAll()
        LearnedWordsStore.clear()
        ReviewScheduler.shared.clear()
        MistakesManager.shared.removeMistakes(Set(MistakesManager.shared.mistakeUUIDs.map(\.uuidString)))
        InAppPurchaseManager.shared.isPremium = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        isResetting = false
        userIsLoggedIn = false
        Task { await InAppPurchaseManager.shared.syncPremiumStatus() }   // aktif abonelik varsa geri gelir
    }
}
