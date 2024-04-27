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
    @FocusState private var focusedField: FocusableField?
    @Published var colorScheme:ColorScheme?
    @Published var isRegisterSuccess = false
    
    func registerRequest() async {
        let registerModel = RegisterModel(username: userName, email: email, password: password)
        FirebaseService.shared.registerUser(userRequest: registerModel) { [weak self] result, error in
            guard let self = self else {return}
            if let error = error {
                print(error.localizedDescription)
            } else {
                OperationQueue.main.addOperation {
                    self.isRegisterSuccess = true
                }
            }
        }
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
            return Color.white.opacity(0.7)
        case .dark:
            return Color(hex: "#222831").opacity(0.7)
        default:
            return Color.gray.opacity(0.7)
        }
    }
}
