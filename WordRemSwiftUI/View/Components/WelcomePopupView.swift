//
//  WelcomePopupView.swift
//  WordRemSwiftUI
//
//  Hesap bazlı hoşgeldin popup'ı.
//  - İlk giriş → yeni kullanıcı karşılama (mor gradient, özellik listesi)
//  - Sonraki girişler → geri dönüş mesajı (turuncu, "Seni özledik")
//

import SwiftUI
import Lottie

// MARK: - Popup Türü

enum WelcomePopupType {
    case newUser(name: String)
    case returning(name: String)

    var name: String {
        switch self {
        case .newUser(let n), .returning(let n): return n
        }
    }

    var isNew: Bool {
        if case .newUser = self { return true }
        return false
    }
}

// MARK: - WelcomePopupView

struct WelcomePopupView: View {

    @EnvironmentObject var langManager: LanguageManager

    let type: WelcomePopupType
    let onDismiss: () -> Void

    @State private var cardScale: CGFloat = 0.75
    @State private var cardOpacity: Double = 0
    @State private var mascotOffset: CGFloat = 20
    @State private var contentOffset: CGFloat = 16

    // MARK: - Computed

    private var isNew: Bool { type.isNew }
    private var name: String { type.name }

    private var headerGradient: LinearGradient {
        isNew
            ? LinearGradient(
                colors: [Color(hex: "#8b5cf6"), Color(hex: "#6d28d9")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(
                colors: [Color(hex: "#f97316"), Color(hex: "#ea580c")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var ctaColor: Color {
        isNew ? Color(hex: "#8b5cf6") : AppTheme.Colors.primaryOrange
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Card
            VStack(spacing: 0) {

                // ── Header ──────────────────────────────────────
                ZStack {
                    headerGradient

                    VStack(spacing: 0) {
                        // Mascot
                        LottieView(animation: .named("reeny_waving"))
                            .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                            .looping()
                            .frame(width: 130, height: 130)
                            .offset(y: mascotOffset)

                        Spacer().frame(height: 12)
                    }

                    // Decorative circles
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 140, height: 140)
                        .offset(x: -70, y: -50)
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 100, height: 100)
                        .offset(x: 80, y: 30)
                }
                .frame(height: 160)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28
                ))

                // ── Content ──────────────────────────────────────
                VStack(spacing: 20) {

                    if isNew {
                        newUserContent
                    } else {
                        returningUserContent
                    }

                    // CTA Button
                    Button(action: dismiss) {
                        Text(isNew
                             ? langManager.s(.welcomeNewCTA)
                             : langManager.s(.welcomeBackCTA))
                            .font(.custom("Feather-Bold", size: 17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(ctaColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: ctaColor.opacity(0.35), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 28)
                .offset(y: contentOffset)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 20)
            .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear { animateIn() }
    }

    // MARK: - New User Content

    @ViewBuilder
    private var newUserContent: some View {
        VStack(spacing: 6) {
            Text(langManager.s(.welcomeNewTitle))
                .font(.custom("Feather-Bold", size: 22))
                .foregroundStyle(Color(hex: "#1a1a2e"))
                .multilineTextAlignment(.center)

            Text(langManager.s(.welcomeNewSubtitle))
                .font(.custom("Feather-Bold", size: 14))
                .foregroundStyle(Color(hex: "#64748b"))
                .multilineTextAlignment(.center)
        }

        // Feature bullets
        VStack(spacing: 12) {
            featureRow(langManager.s(.welcomeNewFeature1))
            featureRow(langManager.s(.welcomeNewFeature2))
            featureRow(langManager.s(.welcomeNewFeature3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#f8f0ff"))
        )
    }

    // MARK: - Returning User Content

    @ViewBuilder
    private var returningUserContent: some View {
        VStack(spacing: 8) {
            Text(langManager.s(.welcomeBackTitle))
                .font(.custom("Feather-Bold", size: 24))
                .foregroundStyle(Color(hex: "#1a1a2e"))
                .multilineTextAlignment(.center)

            Text(langManager.f(.welcomeBackMessageFormat, name))
                .font(.custom("Feather-Bold", size: 16))
                .foregroundStyle(AppTheme.Colors.primaryOrange)
                .multilineTextAlignment(.center)
        }

        // Motivation card
        HStack(spacing: 14) {
            Text("💪")
                .font(.system(size: 36))
            Text(langManager.s(.welcomeBackMotivation))
                .font(.custom("Feather-Bold", size: 15))
                .foregroundStyle(Color(hex: "#1a1a2e"))
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#fff7ed"))
        )
    }

    // MARK: - Helpers

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.custom("Feather-Bold", size: 14))
                .foregroundStyle(Color(hex: "#1a1a2e"))
            Spacer()
        }
    }

    // MARK: - Animations

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            mascotOffset = 0
            contentOffset = 0
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.18)) {
            cardScale = 0.88
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
