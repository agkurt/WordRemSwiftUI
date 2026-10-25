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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    WordRemLogoText(size: 20)
                        .padding(.top, 8)
                        .padding(.bottom, 36)

                    Text(langManager.s(.loginTitle))
                        .font(DS.Font.display(36, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                    Text(langManager.s(.loginSubtitle))
                        .font(DS.Font.ui(16))
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.top, 6)
                        .padding(.bottom, 28)

                    // Apple / Google
                    VStack(spacing: 12) {
                        Button { authManager.handleAppleLogin() } label: {
                            Label(langManager.s(.loginWithApple), systemImage: "apple.logo")
                        }
                        .buttonStyle(InkButtonStyle())

                        Button { authManager.handleGoogleSignIn(with: getRootViewController()) } label: {
                            HStack(spacing: 10) {
                                Image("google").resizable().scaledToFit().frame(width: 18, height: 18)
                                Text(langManager.s(.loginWithGoogle))
                            }
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }

                    HStack(spacing: 12) {
                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                        Text(langManager.s(.loginOr))
                            .font(DS.Font.ui(13))
                            .foregroundStyle(DS.Colors.muted)
                        Rectangle().fill(DS.Colors.line).frame(height: 1)
                    }
                    .padding(.vertical, 24)

                    // E-posta / şifre
                    VStack(spacing: 12) {
                        TextField(langManager.s(.loginEmail), text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .modifier(PaperFieldStyle())
                        SecureField(langManager.s(.loginPassword), text: $viewModel.password)
                            .textContentType(.password)
                            .modifier(PaperFieldStyle())
                    }

                    Button {
                        Task { await viewModel.loginRequest() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().tint(DS.Colors.paperRaised)
                        } else {
                            Text(langManager.s(.loginButton))
                        }
                    }
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                    .opacity(viewModel.email.isEmpty || viewModel.password.isEmpty ? 0.4 : 1)
                    .padding(.top, 16)

                    ForgotAndSignUpButtonView(onForgotPassword: sendPasswordReset)
                        .font(DS.Font.ui(15, weight: .medium))
                        .tint(DS.Colors.inkSoft)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .paperBackground()
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(DS.Colors.inkSoft)
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

/// Kâğıt üstünde ince çizgili metin alanı
struct PaperFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DS.Font.ui(17))
            .foregroundStyle(DS.Colors.ink)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.button).stroke(DS.Colors.line, lineWidth: 1))
    }
}
