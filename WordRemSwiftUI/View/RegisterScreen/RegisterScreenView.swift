//
//  RegisterScreenView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct RegisterScreenView: View {

    @StateObject var viewModel = RegisterScreenViewModel()
    @FocusState var focusedField: FocusableField?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    // ✅ Access the shared AuthManager to trigger navigation
    @EnvironmentObject var authManager: AuthManager
    @State private var showConfirmEmail = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { _ in
                    VStack {
                        Spacer()
                        VStack {
                            VStack(alignment: .leading, spacing: 15) {
                                Text(" Welcome")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 25, weight: .semibold, design: .serif))
                                Text(" Sign Up")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 25, weight: .semibold, design: .serif))
                            }
                            .padding(.bottom, 30)

                            Text("Sign up with email")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)

                            VStack(spacing: 20) {
                                TextFieldView(text: $viewModel.email, placeholder: "Email")
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)

                                TextFieldView(text: $viewModel.userName, placeholder: "Username")
                                    .focused($focusedField, equals: .username)

                                SecureFieldView(text: $viewModel.password, placeholder: "Password")
                                    .focused($focusedField, equals: .password)
                                    .padding(.bottom, 10)
                            }

                            VStack {
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Text("I already have an account")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }

                                Button {
                                    Task { await viewModel.registerRequest() }
                                } label: {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                LinearGradient(
                                                    colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                                    startPoint: .leading, endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(30)
                                    } else {
                                        Text("Sign Up")
                                            .font(.system(size: 16, weight: .semibold))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding()
                                            .background(
                                                LinearGradient(
                                                    colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                                    startPoint: .leading, endPoint: .trailing
                                                )
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding()

                                if let err = viewModel.errorMessage {
                                    Text(err)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                        .cornerRadius(20)
                        .padding()
                        .animation(.easeOut(duration: 0.35), value: 0)
                        Spacer()
                    }
                }
            }
            .onSubmit {
                viewModel.focusNextField()
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
            // ✅ Navigate to MainTabView after successful registration
            .onReceive(viewModel.$isRegisterSuccess) { success in
                guard success else { return }
                if SupabaseAuthService.shared.isSignedIn {
                    authManager.userIsLoggedIn = true
                    authManager.authState = .signedIn
                    authManager.isAnonymous = false
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                } else {
                    // E-posta doğrulaması açık → oturum yok; kullanıcıyı bilgilendir ve girişe dön
                    showConfirmEmail = true
                }
            }
            .alert(AL.s(.registerCheckEmailTitle), isPresented: $showConfirmEmail) {
                Button(AL.s(.paywallOk), role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text(AL.s(.registerCheckEmail))
            }
        }
    }
}
