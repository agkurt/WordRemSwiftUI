//
//  WordRemSwiftUIApp.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI
import Firebase
import UserNotifications
import AppTrackingTransparency

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
            .onAppear {
                Task {
                    // 1) ATT — kısa gecikme: UI tam oturmuş olsun
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if #available(iOS 14, *) {
                        await ATTrackingManager.requestTrackingAuthorization()
                    }

                    // 2) Bildirim izni
                    let center = UNUserNotificationCenter.current()
                    if let success = try? await center.requestAuthorization(options: [.alert, .badge, .sound]),
                       success {
                        await MainActor.run {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }

                    // 3) Supabase'den kullanıcı dilini senkronize et (fallback: UserDefaults değeri korunur)
                    await languageManager.syncFromSupabase()
                }
            }
        }
    }
}
