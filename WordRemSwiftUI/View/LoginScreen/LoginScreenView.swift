//
//  LoginScreenView.swift
//  WordRemSwiftUI
//

import SwiftUI
import AuthenticationServices

struct LoginScreenView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = LoginScreenViewModel()
    @FocusState var focusedField: FocusableField?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                if viewModel.isLoading {
                    AnimationView()
                } else {
                    VStack {
                        VStack(spacing: 0) {
                            Spacer()
                            LoginTextFields(emailText: $viewModel.email, passwordText: $viewModel.password)

                            Button {
                                Task { await viewModel.loginRequest() }
                            } label: {
                                Text("Login")
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(30)
                            }
                            .padding()

                            ForgotAndSignUpButtonView()

                            Spacer()
                            GoogleAndAppleSignView()
                            Spacer()
                        }
                        .clipShape(.rect(cornerRadius: 20))
                        .padding()
                    }
                    .padding(.top, 25)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }
        // ✅ Sync viewModel's authManager with the shared one on appear
        .onAppear {
            viewModel.authManager = authManager
        }
        // ✅ Navigate when login succeeds
        .onReceive(viewModel.$isLoginSuccess) { success in
            if success {
                authManager.userIsLoggedIn = true
                authManager.authState = .signedIn
            }
        }
        // ✅ Also react to authManager's own state (covers Supabase stream updates)
        .onReceive(authManager.$userIsLoggedIn) { loggedIn in
            // ContentView already watches this — no extra work needed here
            _ = loggedIn
        }
        .onTapGesture {
            UIApplication.shared.hideKeyboard()
        }
        // Apple / Google hatalarını alert olarak göster
        .alert("Giriş Başarısız", isPresented: Binding(
            get: { authManager.loginError != nil },
            set: { if !$0 { authManager.loginError = nil } }
        )) {
            Button("Tamam", role: .cancel) { authManager.loginError = nil }
        } message: {
            Text(authManager.loginError ?? "")
        }
    }
}

#Preview {
    LoginScreenView()
        .environmentObject(AuthManager())
}

