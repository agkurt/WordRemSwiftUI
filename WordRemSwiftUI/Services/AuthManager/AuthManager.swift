//
//  AuthManager.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn

class AuthManager: ObservableObject {
    
    @Published var user: User?
    @Published var authState = AuthState.signedOut
    @Published var userIsLoggedIn = false
    
    var authStateHandle: AuthStateDidChangeListenerHandle!
    
    init () {
        userIsLoggedIn = Auth.auth().currentUser != nil
        configureAuthStateChanges()
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userIsLoggedIn = false
            
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    func configureAuthStateChanges() {
        authStateHandle = Auth.auth().addStateDidChangeListener { auth, user in
            print("Auth changed: \(user != nil)")
            self.updateState(user: user)
        }
    }
    
    func removeAuthStateListener() {
        Auth.auth().removeStateDidChangeListener(authStateHandle)
    }
    
    private func updateState(user: User?) {
        self.user = user
        let isAuthenticatedUser = user != nil
        let isAnonymous = user?.isAnonymous ?? false
        
        if isAuthenticatedUser {
            self.authState = isAnonymous ? .authenticated : .signedIn
            self.userIsLoggedIn = true
        } else {
            self.authState = .signedOut
        }
    }
    
    func signInAnonymously() async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("FirebaseAuthSuccess: Sign in anonymously, UID:(\(String(describing: result.user.uid)))")
            return result
        }
        catch {
            print("FirebaseAuthError: failed to sign in anonymously: \(error.localizedDescription)")
            throw error
        }
    }
    
    func handleGoogleSignIn(with viewController: UIViewController)  {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: Firebase client ID is not configured.")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signResult, error in
            if let error = error {
                print("Error signing in with Google: \(error.localizedDescription)")
                return
            }
            
            guard let user = signResult?.user, let idToken = user.idToken else {
                print("Error: Unable to retrieve user information from Google sign-in.")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error authenticating with Firebase: \(error.localizedDescription)")
                    return
                }
                print("Successful login with Google")
                
            }
        }
    }
}

