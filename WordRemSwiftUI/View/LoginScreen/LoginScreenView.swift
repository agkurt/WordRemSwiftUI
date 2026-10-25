//
//  LoginScreenView.swift
//  WordRemSwiftUI
//

import SwiftUI
import AuthenticationServices

struct LoginScreenView: View {

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    /// Profil'den modal açıldığında kapatma butonu gösterilir
    var showsCloseButton: Bool = false
    @StateObject private var viewModel = LoginScreenViewModel()
    @State private var resetMessage: String?
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
                                Text(langManager.s(.loginButton))
                                    .font(.custom("Feather-Bold", size: 16))
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

                            ForgotAndSignUpButtonView(onForgotPassword: sendPasswordReset)

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
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#64748b"))
                                .padding(8)
                                .background(Color(hex: "#e2e8f0"))
                                .clipShape(Circle())
                        }
                    }
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
                if showsCloseButton { dismiss() }
            }
        }
        // ✅ Also react to authManager's own state (covers Supabase stream updates)
        // Apple / Google ile giriş başarılı olunca modal'ı kapat
        .onReceive(authManager.$isAnonymous) { isAnon in
            if !isAnon && showsCloseButton && authManager.userIsLoggedIn { dismiss() }
        }
        // E-posta/şifre hatasını da aynı alert ile göster
        .onChange(of: viewModel.errorMessage) { message in
            if let message { authManager.loginError = message }
        }
        .overlay {
            if authManager.isAuthenticating {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .overlay(ProgressView().tint(.white).scaleEffect(1.5))
            }
        }
        .onTapGesture {
            UIApplication.shared.hideKeyboard()
        }
        // Apple / Google hatalarını alert olarak göster
        .alert(langManager.s(.loginFailedTitle), isPresented: Binding(
            get: { authManager.loginError != nil },
            set: { if !$0 { authManager.loginError = nil } }
        )) {
            Button(langManager.s(.paywallOk), role: .cancel) { authManager.loginError = nil }
        } message: {
            Text(authManager.loginError ?? "")
        }
        .alert(langManager.s(.loginResetTitle), isPresented: Binding(
            get: { resetMessage != nil },
            set: { if !$0 { resetMessage = nil } }
        )) {
            Button(langManager.s(.paywallOk), role: .cancel) { resetMessage = nil }
        } message: {
            Text(resetMessage ?? "")
        }
    }

    private func sendPasswordReset() {
        let email = viewModel.email.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else {
            resetMessage = langManager.s(.loginResetEmailMissing)
            return
        }
        Task {
            do {
                try await SupabaseAuthService.shared.sendPasswordReset(email: email)
                resetMessage = langManager.s(.loginResetEmailSent)
            } catch {
                authManager.loginError = error.localizedDescription
            }
        }
    }
}

#Preview {
    LoginScreenView()
        .environmentObject(AuthManager())
        .environmentObject(LanguageManager.shared)
}

