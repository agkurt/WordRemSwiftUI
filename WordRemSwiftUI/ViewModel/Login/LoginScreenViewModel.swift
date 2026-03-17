//
//  LoginScreenViewModel.swift
//  WordRemSwiftUI
//
//  Migrated from Firebase Auth → Supabase Auth.
//

import SwiftUI
import GoogleSignIn

@MainActor
final class LoginScreenViewModel: ObservableObject {

    var authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoginSuccess = false
    @Published var focusedField: FocusableField?
    @Published var colorScheme: ColorScheme?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Email / Password Login
    func loginRequest() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseAuthService.shared.loginUser(email: email, password: password)
            // Ensure the public.users row exists (in case the user registered on another device)
            try await SupabaseAuthService.shared.ensureUserRow(username: "")
            authManager.userIsLoggedIn = true
            isLoginSuccess = true
            EventManager.shared.logLoginEvent(method: "email")
            print("✅ Supabase login success")
        } catch {
            errorMessage = error.localizedDescription
            self.email = ""
            self.password = ""
            print("❌ Supabase login error: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Anonymous (Guest) Sign-In
    func signAnonymously() async throws {
        // Uses Supabase native anonymous auth — no email, no rate limits
        try await SupabaseAuthService.shared.signInAnonymously()
        
        let randomNum = Int.random(in: 1000...9999)
        try await SupabaseAuthService.shared.ensureUserRow(username: "Guest-\(randomNum)")
        
        authManager.userIsLoggedIn = true
        EventManager.shared.logLoginEvent(method: "anonymous")
    }


    // MARK: - Focus helper
    func focusNextField(focusField: FocusableField) {
        switch focusedField {
        case .email:    focusedField = .password
        case .password: focusedField = .email
        case .username: focusedField = .none
        case .none:     break
        }
    }

    func getColorBasedOnScheme(colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:   return Color.black
        case .dark:    return Color.white
        default:       return Color.gray.opacity(0.7)
        }
    }
}
