//
//  LoginScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI

struct LoginScreenView: View {
    
    @StateObject var viewModel = LoginScreenViewModel()
    @StateObject var authManager = AuthManager()
    @State private var isLoggedIn = false
    @FocusState private var focusedField: FocusableField?
    @State var isAnimating: Bool = false
    @State private var rememberMe = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack {
                        IconImageView()
                        VStack(spacing:0) {
                            Text("Log in to your account")
                                .font(.custom("Poppins-Medium", size: 25))
                                .padding()
                                .frame(maxWidth: .infinity,alignment:.center)
                            
                            Text("Sign in with email")
                                .font(.custom("Poppins-Light", size: 15))
                                .frame(maxWidth: .infinity,alignment:.leading)
                                .padding(.leading)
                            
                            VStack(spacing:0) {

                                TextFieldView(text: $viewModel.email, placeholder: "Email")
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)
                                    .frame(height: 75)
                                
                                SecureFieldView(text: $viewModel.password)
                                    .focused($focusedField, equals: .password)
                            }
                            
                            LineView()
                            
                            VStack(spacing:10) {
                                Button {
                                } label: {
                                    Text("\(Image("google")) Log in with Google")
                                        .font(.custom("Poppins-Light", size: 15))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "393E46"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                
                                Button {
                                    
                                } label: {
                                    Text("\(Image("apple")) Log in with Apple")
                                        
                                        .font(.custom("Poppins-Light", size: 15))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "393E46"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            
                            //remember me and forgot your pasword
                            HStack {
                                Toggle(isOn: $rememberMe) {
                                    Text("Remember Me")
                                        .font(.custom("Poppins-Light", size: 15))
                                    
                                }
                                .toggleStyle(CheckboxStyle())
                                
                                Spacer()
                                Button(action: {
                                    
                                }) {
                                    Text("Forgot Your Password?")
                                        .font(.custom("Poppins-Light", size: 15))
                                }
                                
                                
                            }
                            .padding()
                            
                            VStack {
                                NavigationLink(destination: TabBarCustom().navigationBarBackButtonHidden(), isActive: .constant(authManager.authState != .signedOut)) {
                                    EmptyView()
                                }
                                
                                Button(action: {
                                    viewModel.loginRequest()
                                }, label: {
                                    Text("Login")
                                        .font(.custom("Poppins-Light", size: 15))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "393E46"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                })
                                .buttonStyle(PlainButtonStyle())
                                .padding()
                            }
                            HStack {
                                Text("Don't have an account?")
                                
                                NavigationLink {
                                    RegisterScreenView().navigationBarBackButtonHidden()
                                } label: {
                                    Text("Sign up")
                                }
                            }

                            Button(action: {
                                Task {
                                    do {
                                        try await viewModel.signAnonymously()
                                    }
                                    catch {
                                        print("SignInAnonymouslyError: \(error)")
                                    }
                                }
                            }) {
                                Text("Continue as guest")
                                    .font(.custom("Poppins-Light", size: 15))
                                
                            }
                            .navigationBarBackButtonHidden(true)
                            .padding()
                        }
                        .background(getColorBasedOnScheme())
                        .clipShape(.rect(cornerRadius:20))
                        .padding()
                        
                    }
                    .frame(minWidth: geometry.size.width * 1,minHeight: geometry.size.height * 1)
                    .padding(.top,25)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .onReceive(viewModel.$isLoginSuccess) { success in
                if success {
                    viewModel.authManager.authState = .signedIn
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
        case .username:
            focusedField = .none
        case .none:
            break
        }
    }
    
    private func getColorBasedOnScheme() -> Color {
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
#Preview {
    LoginScreenView()
}




