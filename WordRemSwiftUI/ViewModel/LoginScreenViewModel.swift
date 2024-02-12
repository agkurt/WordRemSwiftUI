//
//  LoginScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI

class LoginScreenViewModel : ObservableObject {
    
    @Published var email:String = ""
    @Published var password:String = ""
    @State var isLoginSuccess = false
    
    func loginRequest() {
          let loginModel = LoginModel(email: email, password: password)
          
          FirebaseService.shared.loginUser(loginModel: loginModel) { [weak self] success, error in
              guard let self = self else { return }
              
              if let error = error {
                  print("Login error: \(error.localizedDescription)")
                  // Giriş başarısız oldu, gerektiğinde kullanıcıya bildirim gösterebilirsiniz.
              } else {
                  // Giriş başarılı oldu
                  DispatchQueue.main.async {
                      self.isLoginSuccess = true
                      print("başarılı giriş")
                  }
              }
          }
      }
    
}