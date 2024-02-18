//
//  LoginScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI

struct LoginScreenView: View {
    @StateObject var viewModel = LoginScreenViewModel()
    @State private var isLoggedIn = false
    @FocusState private var focusedField: FocusableField?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack {
                        IconImageView()
                        VStack {
                            TextFieldView(text: $viewModel.email, placeholder: "Email")
                                .focused($focusedField, equals: .email)
                                .keyboardType(.emailAddress)
                            SecureFieldView(text: $viewModel.password)
                                .focused($focusedField, equals: .password)
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .padding()
                        .frame(width: geometry.size.width * 1, height: geometry.size.height * 0.45)
                        .animation(.easeOut(duration: 0.20))
                      
                        Spacer()
                        
                        VStack {
                            NavigationLink(destination: GetWordsView().navigationBarBackButtonHidden(true), isActive: $isLoggedIn) {
                                Text("Continue as guest")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                viewModel.loginRequest()
                            }, label: {
                                Text("Login")
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "393E46"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            })
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .onReceive(viewModel.$isLoginSuccess) { success in
                if success {
                    isLoggedIn = true
                }
            }
            .onSubmit(focusNextField)
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
        }
    }
    
    private func focusNextField() {
        switch focusedField {
        case .email:
            focusedField = .password
        case .password:
            focusedField = .email
        case .none:
            break
        case .username:
            focusedField = .password
        }
    }
}


#Preview {
    LoginScreenView()
}
