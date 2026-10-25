//
//  WordRemSwiftUIApp.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct WordRemSwiftUIApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authManager = AuthManager()
    @StateObject private var sentenceViewModel = SentenceViewModel()
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
                } else if !hasCompletedOnboarding {
                    WelcomeView()
                } else if authManager.userIsLoggedIn {
                    MainTabView()
                } else {
                    LoginScreenView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(sentenceViewModel)
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
                Task {
                    // 1) Bildirim izni — açılışta değil, onboarding tamamlandıktan sonra
                    if hasCompletedOnboarding { await requestNotificationPermission() }

                    // 2) Supabase'den kullanıcı dilini senkronize et (fallback: UserDefaults değeri korunur)
                    await languageManager.syncFromSupabase()

                    // 3) RevenueCat'ten premium durumunu senkronize et
                    await InAppPurchaseManager.shared.syncPremiumStatus()
                }
            }
        }
    }

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        if let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound]),
           granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
