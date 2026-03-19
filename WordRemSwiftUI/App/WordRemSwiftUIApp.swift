//
//  WordRemSwiftUIApp.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI
import Firebase

@main
struct WordRemSwiftUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var sentenceViewModel = SentenceViewModel()
    @StateObject private var authManager = AuthManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var startupDone = false

    init () {
        // Firebase is now configured in AppDelegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !startupDone {
                    // Always show launch screen first (preloads data for 2.5s)
                    LaunchScreenView(onReady: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            startupDone = true
                        }
                    })
                    .environmentObject(authManager)
                    .environmentObject(sentenceViewModel)
                } else if hasCompletedOnboarding {
                    ContentView(sentenceViewModel: sentenceViewModel)
                        .environmentObject(authManager)
                        .environmentObject(sentenceViewModel)
                } else {
                    // New user: skip old SplashScreenView (LaunchScreenView already played)
                    WelcomeView()
                        .environmentObject(authManager)
                        .environmentObject(sentenceViewModel)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}






