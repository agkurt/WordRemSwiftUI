//
//  RegisterScreenViewModel.swift
//  WordRemSwiftUI
//
//  Migrated from Firebase Auth → Supabase Auth.
//

import Foundation
import SwiftUI

@MainActor
final class RegisterScreenViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var userName: String = ""
    @Published var password: String = ""
    @FocusState private var focusedField: FocusableField?
    @Published var colorScheme: ColorScheme?
    @Published var isRegisterSuccess = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    func registerRequest() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseAuthService.shared.registerUser(
                username: userName,
                email: email,
                password: password
            )
            // Create the public.users row with the chosen username
            try await SupabaseAuthService.shared.ensureUserRow(username: userName)
            isRegisterSuccess = true
            EventManager.shared.logRegisterEvent()
            print("✅ Supabase registration success")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Register Error: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func focusNextField() {
        switch focusedField {
        case .email:    focusedField = .username
        case .username: focusedField = .password
        case .password: focusedField = .email
        case .none:     break
        }
    }

    func getColorBasedOnScheme(colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:   return Color.white.opacity(0.7)
        case .dark:    return Color(hex: "#222831").opacity(0.7)
        default:       return Color.gray.opacity(0.7)
        }
    }
}
