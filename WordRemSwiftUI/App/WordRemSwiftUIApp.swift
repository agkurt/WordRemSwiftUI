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
    
    init () {
        // Firebase is now configured in AppDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView(sentenceViewModel: sentenceViewModel)
                        .environmentObject(authManager)
                        .environmentObject(sentenceViewModel)
                } else {
                    WelcomeView()
                        .environmentObject(authManager)
                        .environmentObject(sentenceViewModel)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}






