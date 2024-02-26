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
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            if authViewModel.userIsLoggedIn {
                TabBarCustom()
            } else {
                RegisterScreenView()
            }
        }
    }
}




