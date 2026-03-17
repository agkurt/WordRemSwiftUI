//
//  ContentView.swift
//  WordRemSwiftUI
//

import SwiftUI

class TabBarModifier: ObservableObject {
    @Published var customAddAction: (() -> Void)? = nil
}

struct ContentView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject var sentenceViewModel = SentenceViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isSelectMotherTongue") var isSelectMotherTongue: Bool = true
    @StateObject var motherTongueViewModel = MotherTongueViewModel()
    @StateObject var tabBarModifier = TabBarModifier()

    var body: some View {
        Group {
            if authManager.userIsLoggedIn {
                MainTabView()
            } else {
                LoginScreenView()
            }
        }
        .environmentObject(authManager)
        .environmentObject(sentenceViewModel)
        .environmentObject(tabBarModifier)
        .onAppear {
            Task {
                let center = UNUserNotificationCenter.current()
                do {
                    let success = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                    if success {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } catch {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
}
