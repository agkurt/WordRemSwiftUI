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
    @StateObject var viewModel = LoginScreenViewModel(authManager: AuthManager())
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
                            
                            GoogleAndAppleSignView()
                            
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
