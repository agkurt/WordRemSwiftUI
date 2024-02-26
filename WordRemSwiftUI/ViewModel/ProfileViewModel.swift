//
//  ProfileViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI
import Firebase

class ProfileViewModel: ObservableObject {
    
    @Published var isSignedIn = true
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
        } catch {
            print("Error signing out: \(error)")
        }
    }       
}
