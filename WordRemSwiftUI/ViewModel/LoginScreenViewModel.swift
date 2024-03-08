//
//  LoginScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

class LoginScreenViewModel : ObservableObject {
    
    //MARK: Login
    @Published var email:String = ""
    @Published var password:String = ""
    
    // MARK: Success Properties
    @Published var isLoginSuccess = false
    
    // MARK: Keyboard
    @Published var focusedField: FocusableField?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: Color
    @Published var colorScheme:ColorScheme?
    
    // MARK: Auth Manager
    var authManager: AuthManager
    
    // MARK: Apple Sign in Properties
    @Published var nonce: String = ""
    
    // MARK: App Log Status
     @AppStorage("log_status") var logStatus: Bool = false
     
     @AppStorage("token") var token: String?
     
     @AppStorage("login_name") var loginName: String = ""
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    
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
