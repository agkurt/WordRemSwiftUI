//
//  ContentView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.04.2024.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var authManager: AuthManager
    @StateObject var sentenceViewModel = SentenceViewModel()
    @StateObject var homeScreenViewModel = HomeScreenViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isSelectMotherTongue") var isSelectMotherTongue: Bool = true
    @StateObject var motherTongueViewModel = MotherTongueViewModel()
    
    var body: some View {
        VStack {
            if authManager.userIsLoggedIn {
                HomeScreenView(viewModel: homeScreenViewModel)
            } else  {
                LoginScreenView()
            }
        }
        .environmentObject(authManager)
        .environmentObject(sentenceViewModel)
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
