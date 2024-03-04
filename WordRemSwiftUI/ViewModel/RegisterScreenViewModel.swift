//
//  RegisterScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import Foundation
import SwiftUI

class RegisterScreenViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var userName: String = ""
    @Published var password: String = ""
    @Published var isRegisterSuccess = false
    @Published var isAnimating: Bool = false
    @FocusState private var focusedField: FocusableField?
    @Published var colorScheme:ColorScheme?
    
    func registerRequest() async -> Bool {
        let registerModel = RegisterModel(username: userName, email: email, password: password)
        var isSuccess = false
        
        await withCheckedContinuation { continuation in
            FirebaseService.shared.registerUser(userRequest: registerModel) { [weak self] result, error in
                guard let self = self else {return}
                
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.isRegisterSuccess = true
                        isSuccess = true
                    }
                }
                continuation.resume(returning: isSuccess)
            }
        }
        return isSuccess
    }
    
    func registerAsync() async {
        self.isAnimating = true
        let result = await registerRequest()
        self.isAnimating = false
        self.isRegisterSuccess = result
    }
    
    func focusNextField() {
        switch focusedField {
        case .email:
            focusedField = .username
        case .username:
            focusedField = .password
        case .password:
            focusedField = .email
        case .none:
            break
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
    
    
}

