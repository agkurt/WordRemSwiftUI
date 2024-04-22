//
//  ContentView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.04.2024.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var manager = NotificationManager()
    @StateObject var authManager = AuthManager()
    @StateObject private var loginViewModel = LoginScreenViewModel(authManager: AuthManager())
    @StateObject var sentenceViewModel = SentenceViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some View {
        VStack {
            if authManager.userIsLoggedIn {
                HomeScreenView()
            } else {
                LoginScreenView()
            }
        }
        .environmentObject(sentenceViewModel)
        .environmentObject(authManager)
        .onAppear(perform: {
            Task {
                let center = UNUserNotificationCenter.current()
                
                do {
                    let success = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                    
                    if success {
                        UIApplication.shared.registerForRemoteNotifications()
                        print("Push notification allowed by user")
                    } else {
                        print("Push notification not allowed by user")
                    }
                    
                } catch {
                    print("Error")
                }
            }
        })
    }
}
