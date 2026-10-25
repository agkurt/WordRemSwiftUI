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
    @StateObject private var motherTongueViewModel = MotherTongueViewModel()
    @StateObject private var languageManager = LanguageManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var startupDone = false

    init () {
        // Firebase is now configured in AppDelegate
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
                } else if !hasCompletedOnboarding {
                    OnboardingFlowView()
                } else {
                    MainTabView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(tabBarModifier)
            .environmentObject(motherTongueViewModel)
            .environmentObject(languageManager)
            .environment(\.layoutDirection, languageManager.layoutDirection)
            .preferredColorScheme(.light)
            .onChange(of: hasCompletedOnboarding) { completed in
                guard completed else { return }
                Task { await requestNotificationPermission() }
            }
            .onAppear {
                if DemoData.isOn {   // Debug: ekran görüntüleri — izin/Game Center pencereleri açılmaz
                    DemoData.seedIfNeeded()
                    return
                }
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
    }
}
