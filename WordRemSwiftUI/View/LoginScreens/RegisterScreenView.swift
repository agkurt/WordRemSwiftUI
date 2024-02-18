//
//  RegisterScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI

struct RegisterScreenView: View {
    @StateObject var viewModel = RegisterScreenViewModel()
    @State var isRegisterSuccess = false
    @FocusState var focusedField: FocusableField?

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
                            TextFieldView(text: $viewModel.userName, placeholder: "Username")
                                .focused($focusedField, equals: .username)
                            SecureFieldView(text: $viewModel.password)
                                .focused($focusedField, equals: .password)
                        }
                        
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .padding()
                        .frame(width: geometry.size.width * 1, height: geometry.size.height * 0.65)
                        .animation(.easeOut(duration: 0.35))
                        
                        VStack {
                            NavigationLink(destination: LoginScreenView(), isActive: $viewModel.isRegisterSuccess) {
                                Text("I already have an account")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                if viewModel.registerRequest() {
                                    self.isRegisterSuccess = true
                                }
                            }) {
                                Text("Register")
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "393E46"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())  
                        }
                    }
                }
            }
            .onSubmit(focusNextField)
            .onTapGesture() {
                UIApplication.shared.hideKeyboard()
            }
        }
        
    }
    
    private func focusFirstField() {
        focusedField = FocusableField.allCases.first
    }

    private func focusNextField() {
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
}


#Preview {
    RegisterScreenView()
}


