//
//  LoginScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI

struct LoginScreenView: View {
    
    @StateObject var loginScreenViewModel = LoginScreenViewModel()
    @State var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient (
                    gradient: Gradient(colors: [Color.init(hex:"#00b4d8")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(spacing:20) {
                    IconImageView()
                    TextFieldView(text: $loginScreenViewModel.email, placeholder: "Email")
                    TextFieldView(text: $loginScreenViewModel.password, placeholder: "Password")
                    Spacer()
                    
                    NavigationLink(destination: GetWordsView(), isActive: $isLoggedIn)  {
                        Button("Login") {
                            loginScreenViewModel.loginRequest()
                        }
                    }
                    
                    .buttonStyle(LoginButtonStyle())
                    
                }
                
            }
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("LoginScreen")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
}

#Preview {
    LoginScreenView()
}
