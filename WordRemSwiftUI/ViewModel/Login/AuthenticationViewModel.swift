//
//  AuthenticationViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI
import Firebase

class AuthenticationViewModel: ObservableObject {
    
    @Published var userIsLoggedIn = false
    
    init() {
        userIsLoggedIn = Auth.auth().currentUser != nil
    }
    
    func signOut() {
           do {
               try Auth.auth().signOut()
               userIsLoggedIn = false
           } catch {
               print("Error signing out: \(error)")
           }
       }
}
