//
//  RegisterScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import Foundation
import SwiftUI

class RegisterScreenViewModel:ObservableObject {
    
    @Published var email: String = ""
    @Published var userName: String = ""
    @Published var password: String = ""
    @Published var isRegisterSuccess = false
    
    
    func registerRequest() {
        let registerModel = RegisterModel(username: userName, email: email, password: password)
        
        FirebaseService.shared.registerUser(userRequest: registerModel) { [weak self] result, error in
            
            guard let self = self else {return}
            
            if let error = error {
                print(error.localizedDescription)
            }else {
                DispatchQueue.main.async {
                    self.isRegisterSuccess = true
                }
            }
        }
    }
}
