//
//  ProfileViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI
import Firebase

class SettingsViewModel: ObservableObject {
    
    @Published var isSignedIn = false
    @Published var shouldNavigateToLoginScreen = false
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }       
}
