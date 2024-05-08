//
//  LoginScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI
import AuthenticationServices

struct LoginScreenView: View {
    
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = LoginScreenViewModel()
    @State private var isLoggedIn = false
    @State var isAnimating: Bool = false
    @FocusState var focusedField:FocusableField?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                if viewModel.isLoading {
                   AnimationView()
                }else {
                    VStack {
                        VStack(spacing:0) {
                            Spacer()
                            LoginTextFields(emailText: $viewModel.email, passwordText: $viewModel.password)
                           
                            Button {
                                Task {
                                    await viewModel.loginRequest()
                                }
                                
                            } label: {
                                Text("Login")
                                    .font(.custom("Poppins-Light", size: 15))
                                    .frame(maxWidth: .infinity,alignment:.center)
                                    .padding()
                                    .background(Color(hex: "#313a45"))
                                    .foregroundColor(.white)
                                    .cornerRadius(30)
                            }
                            .padding()
                            
                            ForgotAndSignUpButtonView()
                            Spacer()
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
                                    .foregroundStyle(.primary)
                                
                            }
                            .navigationBarBackButtonHidden(true)
                        }
                        .clipShape(.rect(cornerRadius:20))
                        .padding()
                        
                    }
                    
                    .padding(.top,25)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }
        
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
#Preview {
    LoginScreenView()
}


