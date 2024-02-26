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
    @State var isAnimating: Bool = false
    
    var body: some View {
        NavigationStack {
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
                        .animation(.easeOut(duration: 0.35),value: 0)
                        
                        VStack {
                            NavigationLink(destination: LoginScreenView().navigationBarBackButtonHidden(true), isActive: $viewModel.isRegisterSuccess) {
                                Text("I have already an account")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            Button(action: {
                                self.isAnimating = true
                                Task {
                                    await self.registerAsync()
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
                
                if isAnimating {
                    ActivityIndicatorView(color: Color(.purple), isAnimating: $isAnimating)
                        .frame(width: 100, height: 100)
                        .zIndex(1)
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
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
    
    private func registerAsync() async {
        self.isAnimating = true
        let result = await viewModel.registerRequest()
        self.isAnimating = false
        self.isRegisterSuccess = result
    }
}

#Preview {
    RegisterScreenView()
}


