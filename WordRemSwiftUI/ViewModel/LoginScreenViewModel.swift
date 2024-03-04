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
import AuthenticationServices
import CryptoKit


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
            return Color.white.opacity(0.7) // Light mode background
        case .dark:
            return Color(hex: "#222831").opacity(0.7) // Dark mode background (adjust as needed)
        default:
            return Color.gray.opacity(0.7) // Fallback
        }
    }
    
    // MARK: Apple Sign in API
      func appleAuthenticate(credential: ASAuthorizationAppleIDCredential){
          // getting token...
          guard let token = credential.identityToken else{
              print("error with firebase")
              return
          }
          
          // Token String
          guard let tokenString = String(data: token, encoding: .utf8) else{
              print("error with Token")
              return
          }
          
          let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
          
          Auth.auth().signIn(with: firebaseCredential){(result, err) in
              if let error = err{
                  print(error.localizedDescription)
                  return
              }
              
              var name = "Unknown"
              if let display_name = result?.user.displayName{
                  self.loginName = display_name
              }
              else{
                  self.loginName = name
              }
          
              guard let email = result?.user.email else{
                  print("email not found with apple auth")
                  return
              }
              
              guard let uid = result?.user.uid else{
                  print("uid not found with apple auth")
                  return
                  
              }
              
              if let phone = result?.user.phoneNumber{
              }
              print("here")
              print(email)
              print(uid)
              
              self.logStatus = true
              
              
              
          }
      }
    
    // MARK: Apple Sign in Helpers
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }

    func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }

}
