//
//  LoginScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI
import GoogleSignIn
import FirebaseCore

@MainActor
final class LoginScreenViewModel : ObservableObject {
    
    var authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    @Published var email:String = ""
    @Published var password:String = ""
    @Published var isLoginSuccess = false
    @Published var focusedField: FocusableField?
    @Published var colorScheme:ColorScheme?
    @Published var isLoading = false
    
    
    func loginRequest() async {
        isLoading = true
        let loginModel = LoginModel(email: email, password: password)
        FirebaseService.shared.loginUser(loginModel: loginModel) { [weak self] success, error in
            guard let self = self else { return }
            if let error = error {
                print("Login error: \(error.localizedDescription)")
                self.isLoading = false
                self.email = ""
                self.password = ""
            } else if success {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.authManager.userIsLoggedIn = true
                    self.isLoading = false
                    self.isLoginSuccess = true
                    print("Successful login")
                }
            }
        }
    }
    
    func focusNextField(focusField:FocusableField)  {
        switch focusedField {
        case .email:
            focusedField = .password
        case .password:
            focusedField = .email
        case .username:
            focusedField = .none
        case .none:
            break
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
    
    func getColorBasedOnScheme(colorScheme:ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color.black
        case .dark:
            return Color.white
        default:
            return Color.gray.opacity(0.7)
        }
    }
}
