//
//  LoginScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI

class LoginScreenViewModel : ObservableObject {
    
    @Published var email:String = ""
    @Published var password:String = ""
    @Published var isLoginSuccess = false
    @FocusState private var focusedField: FocusableField?
    @StateObject var authManager = AuthManager()

    func loginRequest() {
        let loginModel = LoginModel(email: email, password: password)
        
        FirebaseService.shared.loginUser(loginModel: loginModel) { [weak self] success, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Login error: \(error.localizedDescription)")
            } else if success {
                DispatchQueue.main.async {
                    self.isLoginSuccess = true
                    print("Successful login")
                }
            }
        }
    }
    
    func focusNextField() {
        switch focusedField {
        case .email:
            focusedField = .password
        case .password:
            focusedField = .email
        case .none:
            break
        case .username:
            focusedField = .password
        }
    }
    
    func signAnonymously() async throws {
        do {
            _ = try await authManager.signInAnonymously()
        }
        catch {
            print("SignInAnonymouslyError: \(error)")
            throw error
        }
    }

}
