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
                        VStack(spacing:0) {
                            Spacer()
                            VStack(alignment:.leading,spacing: 15) {
                                Text(" Welcome")
                                    .frame(maxWidth: .infinity,alignment:.leading)
                                    .font(.custom("Poppins-Medium", size: 25))
                                Text(" Login")
                                    .frame(maxWidth: .infinity,alignment:.leading)
                                    .font(.custom("Poppins-Bold", size: 25))
                            }
                            .padding(.bottom,30)
                           
                            Text("Sign in with email")
                                .font(.custom("Poppins-Light", size: 15))
                                .frame(maxWidth: .infinity,alignment:.leading)
                                .padding()
                            
                            VStack(spacing:20) {

                                TextFieldView(text: $viewModel.email, placeholder: "Email")
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)
                                
                                SecureFieldView(text: $viewModel.password)
                                    .focused($focusedField, equals: .password)
                            }
                            
                            VStack {
                                NavigationLink(destination: TabBarCustom().navigationBarBackButtonHidden(), isActive: .constant(authManager.authState != .signedOut)) {
                                    EmptyView()
                                }
                                .padding()
                                Button(action: {
                                    viewModel.loginRequest()
                                }, label: {
                                    Text("Login")
                                        .font(.custom("Poppins-Light", size: 15))
                                        .frame(maxWidth: .infinity,alignment:.center)
                                        .padding()
                                        .background(Color(hex: "#313a45"))
                                        .foregroundColor(.white)
                                        .cornerRadius(30)
                                })
                                .ignoresSafeArea(.keyboard)
                                
                                HStack {
                                    Button(action: {
                                        
                                    }) {
                                        Text("Forgot Your Password?")
                                            .font(.custom("Poppins-Light", size: 15))
                                            .foregroundStyle(viewModel.getColorBasedOnScheme(colorScheme: colorScheme))
                                    }
                                    Spacer()
                                    NavigationLink {
                                        RegisterScreenView().navigationBarBackButtonHidden()
                                    } label: {
                                        Text("Sign Up")
                                            .foregroundStyle(viewModel.getColorBasedOnScheme(colorScheme: colorScheme))
                                    }
                                }
                                .padding()
                            }
                            HStack(spacing:70) {
                                Button {
                                    authManager.handleGoogleSignIn(with: getRootViewController())
                                } label: {
                                        Image("google")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60,height: 60)
                                }
                                Button {
                                    
                                } label: {
                                        Image("apple")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50,height: 50)
                                }
                            }
                            .padding()
                            Spacer()
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
                                Text("Continue as Guest")
                                    .font(.custom("Poppins-Light", size: 18))
                                    .foregroundStyle(.white)
                                
                            }
                            .navigationBarBackButtonHidden(true)
                        }
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



