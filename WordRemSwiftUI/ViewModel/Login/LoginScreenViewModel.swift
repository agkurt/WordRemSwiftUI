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

    // LoginScreenView.onAppear'da set edilir; başlangıçta nil, kullanım öncesinde set edilmiş olur
    var authManager: AuthManager?

    init() {}

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
            let fallbackUsername = email.split(separator: "@").first.map(String.init) ?? "User"
            try await SupabaseAuthService.shared.ensureUserRow(username: fallbackUsername)
            authManager?.userIsLoggedIn = true
            authManager?.authState = .signedIn
            authManager?.isAnonymous = false
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
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
