//
//  WordRemSwiftUIApp.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI
import Firebase
import FirebaseCore

@main
struct WordRemSwiftUIApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var authManager = AuthManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.userIsLoggedIn {
                TabBarCustom()
                    .onAppear(perform: {
                        authManager.configureAuthStateChanges()
                    })
            } else {
                RegisterScreenView()
                    .onAppear(perform: {
                        authManager.configureAuthStateChanges()
                    })
            }
        }
        .environmentObject(authManager)
    }
}






