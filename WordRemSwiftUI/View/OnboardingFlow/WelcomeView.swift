//
//  WelcomeView.swift
//  WordRemSwiftUI
//
//  Duolingo-style welcome screen using App's Light & Alive theme colors.
//

import SwiftUI

struct WelcomeView: View {
    
    @State private var navigateToLanguage = false
    @State private var navigateToLogin = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#fdf4f4"), Color(hex: "#fff9f9"), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo Space
                    VStack(spacing: 16) {
                        WordRemLogoText(size: 42)

                        Text(AL.s(.welcomeTagline))
                            .font(.custom("Feather-Bold", size: 18))
                            .foregroundStyle(Color(hex: "#64748b"))
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        // Start Button
                        Button(action: {
                            navigateToLanguage = true
                        }) {
                            Text(AL.s(.welcomeStart))
                                .font(.custom("Feather-Bold", size: 17))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.Colors.primaryOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                        }
                        
                        // Login Button
                        Button(action: {
                            navigateToLogin = true
                        }) {
                            Text(AL.s(.welcomeHaveAccount))
                                .font(.custom("Feather-Bold", size: 17))
                                .foregroundStyle(AppTheme.Colors.primaryOrange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.Colors.primaryOrange, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            // Logic for Navigation Links
            .navigationDestination(isPresented: $navigateToLanguage) {
                NativeLanguageSelectionView()
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginScreenView()
                    .navigationBarBackButtonHidden(false) // Give access back if they cancel
            }
        }
    }
}

#Preview {
    WelcomeView()
}
