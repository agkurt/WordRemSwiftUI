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
    @Environment(\.colorScheme) private var colorScheme

    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack() {
                        Spacer()
                        VStack {
                            VStack(alignment:.leading,spacing: 15) {
                                Text(" Welcome")
                                    .frame(maxWidth: .infinity,alignment:.leading)
                                    .font(.custom("Poppins-Medium", size: 25))
                                Text(" Sign Up")
                                    .frame(maxWidth: .infinity,alignment:.leading)
                                    .font(.custom("Poppins-Bold", size: 25))
                            }
                            .padding(.bottom,30)
                            
                            Text("Sign up with email")
                                .font(.custom("Poppins-Light", size: 15))
                                .frame(maxWidth: .infinity,alignment:.leading)
                                .padding(.leading)
                            
                            VStack(spacing:20) {
                                TextFieldView(text: $viewModel.email, placeholder: "Email")
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)
                                TextFieldView(text: $viewModel.userName, placeholder: "Username")
                                    .focused($focusedField, equals: .username)
                                SecureFieldView(text: $viewModel.password)
                                    .focused($focusedField, equals: .password)
                                    .padding(.bottom,10)
                            }
                            
                            VStack {
                                NavigationLink(destination: LoginScreenView().navigationBarBackButtonHidden(true), isActive: $viewModel.isRegisterSuccess) {
                                    Text("I have already an account")
                                        .font(.custom("Poppins-Light", size: 15))
                                        .foregroundStyle(.white)
                                }
                                Button(action: {
                                    self.isAnimating = true
                                    Task {
                                        await self.registerAsync()
                                    }
                                }) {
                                    Text("Sign Up")
                                        .font(.custom("Poppins-Light", size: 15))
                                        .frame(maxWidth: .infinity,alignment:.center)
                                        .padding()
                                        .background(Color(hex: "#313a45"))
                                        .foregroundColor(.white)
                                        .cornerRadius(30)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding()
                            }
                        }
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                        .cornerRadius(20)
                        .padding()
                        .animation(.easeOut(duration: 0.35),value: 0)
                        Spacer()
                    }
                }
               
                if isAnimating {
                    ActivityIndicatorView(color: Color(.purple), isAnimating: $isAnimating)
                        .frame(width: 100, height: 100)
                        .zIndex(1)
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


