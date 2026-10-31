//
//  WordRemSwiftUIApp.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI
import UserNotifications

@main
struct WordRemSwiftUIApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authManager = AuthManager()
    @StateObject private var tabBarModifier = TabBarModifier()
    @StateObject private var languageManager = LanguageManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var startupDone = false
    /// Onboarding paywall'a ulaşıp satın almadan kapatıldıysa: yeniden açılışta onboarding/demo tekrar değil, doğrudan paywall
    @State private var resumeAtPaywall = UserDefaults.standard.bool(forKey: OnboardingFlowView.reachedPaywallKey)

    init () {
        // Firebase (analitik) AppDelegate'te kurulur: Track.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !startupDone {
                    LaunchScreenView(onReady: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            startupDone = true
                        }
                    })
                } else if Self.forceMainTabs {
                    MainTabView()
                } else if !hasCompletedOnboarding && !resumeAtPaywall {
                    OnboardingFlowView()
                } else {
                    // Sert paywall: Pro olmayan ana sekmelere geçemez
                    ProGate()
                }
            }
            .environmentObject(authManager)
            .environmentObject(tabBarModifier)
            .environmentObject(languageManager)
            .environment(\.layoutDirection, languageManager.layoutDirection)
            .preferredColorScheme(.light)
            .onChange(of: hasCompletedOnboarding) { completed in
                guard completed else { return }
                Task { await requestNotificationPermission() }
            }
            // Widget'tan gelen bağlantı (Lupa'nın sorusu / seri)
            .onOpenURL { AppRouter.shared.handle($0) }
            .onAppear {
                LupaShared.save(target: LearningLanguages.current, native: OL.nativeLangCode)
                if DemoData.isOn {   // Debug: ekran görüntüleri — izin/Game Center pencereleri açılmaz
                    DemoData.seedIfNeeded()
                    return
                }
                TutorBrain.fixSavedPhraseLanguages()
                #if DEBUG
                DebugDriver.start()
                #endif
                Task {
                    // 1) Bildirim izni — açılışta değil, onboarding tamamlandıktan sonra
                    if hasCompletedOnboarding { await requestNotificationPermission() }

                    // 2) Game Center (sıralama) ve günlük seri
                    GameCenterService.shared.authenticate()
                    if hasCompletedOnboarding { _ = try? await DataService.shared.updateDailyLoginStreak() }

                    // 3) RevenueCat'ten premium durumunu senkronize et
                    await InAppPurchaseManager.shared.syncPremiumStatus()
                }
            }
        }
    }

    /// Sadece Debug: `-ShowMainTabs` argümanıyla girişsiz ana ekranları açar (sunucu kapalıyken UI kontrolü için)
    private static var forceMainTabs: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ShowMainTabs")
        #else
        false
        #endif
    }

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        // Yalnızca yerel bildirimler (günlük hedef / tekrar hatırlatıcıları); uzak push yok
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        await SmartReminders.reschedule()
    }
}

// MARK: - Sert paywall kapısı
/// Pro olmayan kullanıcı uygulamayı kullanamaz: açılışta RevenueCat ile senkronlanır, Pro değilse
/// kapatılamayan paywall gösterilir. Satın alma / geri yükleme → Hoş geldin → ana sekmeler.
/// Pro kullanıcı (önbellekte Pro) hiç beklemeden ana sekmeleri görür; abonelik biterse paywall'a döner.
private struct ProGate: View {
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var iap = InAppPurchaseManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// Açılış senkronu bitti (ya da zaman aşımı)
    @State private var checked = false
    /// Paywall ekranda: satın alma sonrası Hoş geldin ekranı bitene kadar ana sekmelere geçilmez
    @State private var inPaywall = false
    @State private var debugSkipped = false

    var body: some View {
        Group {
            if bypass || (iap.isPremium && !inPaywall) {
                MainTabView()
                    .onAppear(perform: completeOnboardingIfNeeded)
            } else if !checked && !inPaywall {
                // Önbellekte Pro yok: RevenueCat cevabını kısa süre bekle (Pro kullanıcı paywall'u görmesin)
                DS.Colors.paper.ignoresSafeArea()
                    .overlay(ProgressView().tint(DS.Colors.muted))
            } else {
                OnboardingPaywallView(onContinue: paywallFinished,
                                      entryPoint: hasCompletedOnboarding ? "launch_gate" : "onboarding_resume",
                                      isHard: true)
                    .interactiveDismissDisabled(true)
                    .onAppear { inPaywall = true }
            }
        }
        .task {
            await iap.syncPremiumStatus()
            await MainActor.run { checked = true }
        }
        .task {
            // Ağ yavaşsa sonsuza kadar bekletme: önbellekteki duruma göre karar ver
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run { checked = true }
        }
    }

    /// Debug: ekran görüntüsü verisi, `-SkipPaywall` argümanı ya da paywall'daki "DEBUG ›" düğmesi
    private var bypass: Bool {
        #if DEBUG
        return debugSkipped || DemoData.isOn
            || ProcessInfo.processInfo.arguments.contains("-SkipPaywall")
            || UserDefaults.standard.bool(forKey: "debugSkipPaywall")
        #else
        return false
        #endif
    }

    private func paywallFinished() {
        #if DEBUG
        if !iap.isPremium { debugSkipped = true }
        #endif
        inPaywall = false
        completeOnboardingIfNeeded()
    }

    /// Onboarding paywall'da yarım kaldıysa (uygulama kapatıldı) satın almadan sonra burada tamamlanır
    private func completeOnboardingIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        UserDefaults.standard.removeObject(forKey: OnboardingFlowView.reachedPaywallKey)
        Task {
            _ = try? await DataService.shared.updateDailyLoginStreak()
            await MainActor.run { authManager.completeOnboarding() }
        }
    }
}
