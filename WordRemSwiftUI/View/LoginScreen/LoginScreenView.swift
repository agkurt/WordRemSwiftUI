//
//  LoginScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI
import AuthenticationServices

struct LoginScreenView: View {
    
    @StateObject var authManager: AuthManager
    @StateObject var viewModel: LoginScreenViewModel
    @State private var isLoggedIn = false
    @State var isAnimating: Bool = false
    @State private var rememberMe = false
    @FocusState var focusedField:FocusableField?
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        let authManager = AuthManager()
        _authManager = StateObject(wrappedValue: authManager)
        _viewModel = StateObject(wrappedValue: LoginScreenViewModel(authManager: authManager))
    }
    
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
                            
                            VStack(spacing:20) {
                                
                                TextFieldView(text: $viewModel.email, placeholder: "Email")
                                    .focused($focusedField, equals: .email)
                                
                                    .keyboardType(.emailAddress)
                                
                                SecureFieldView(text: $viewModel.password)
                                    .focused($focusedField, equals: .password)
                                
                                
                            }
                            .padding()
                            
                            LineView(textPlace: "or countinue with")
                            
                            VStack(spacing:10) {
                                Button {
                                    authManager.handleGoogleSignIn(with: getRootViewController())
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
                        .background(viewModel.getColorBasedOnScheme(colorScheme: colorScheme))
                        .clipShape(.rect(cornerRadius:20))
                        .padding()
                        
                    }
                    
                    .frame(minWidth: geometry.size.width * 1,minHeight: geometry.size.height * 1)
                    .padding(.top,25)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .onSubmit { viewModel.focusNextField(focusField: focusedField!) }
            
            .onReceive(viewModel.$isLoginSuccess) { success in
                if success {
                    viewModel.authManager.authState = .signedIn
                }
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
        }
    }
}
#Preview {
    LoginScreenView()
}



