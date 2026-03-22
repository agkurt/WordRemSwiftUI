//
//  DailyGoalBreakPopupView.swift
//  WordRemSwiftUI
//
//  Günlük çalışma hedefi dolduğunda gösterilen mola popup'ı.
//  Yeşil/teal gradient, mascot, iki buton (Mola Ver / Devam Et).
//

import SwiftUI
import Lottie

struct DailyGoalBreakPopupView: View {

    let minutesStudied: Int
    let onDismiss: () -> Void

    @EnvironmentObject var langManager: LanguageManager

    // MARK: - Animation state
    @State private var cardScale: CGFloat  = 0.75
    @State private var cardOpacity: Double = 0
    @State private var mascotOffset: CGFloat = 20
    @State private var confettiOpacity: Double = 1

    // MARK: - Theme
    private let gradStart = Color(hex: "#10b981")   // emerald-500
    private let gradEnd   = Color(hex: "#059669")   // emerald-600
    private let bgCard    = Color(hex: "#f0fdf4")   // green-50

    var body: some View {
        ZStack {
            // ── Backdrop ──────────────────────────────────────────
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // ── Card ──────────────────────────────────────────────
            VStack(spacing: 0) {

                // ── Header (teal gradient) ────────────────────────
                ZStack {
                    // Background
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28, topTrailingRadius: 28,
                        bottomLeadingRadius: 0, bottomTrailingRadius: 0
                    )
                    .fill(
                        LinearGradient(colors: [gradStart, gradEnd],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                    // Decorative circles
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 130, height: 130)
                        .offset(x: -80, y: -40)
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 90, height: 90)
                        .offset(x: 90, y: 30)

                    VStack(spacing: 8) {
                        // Mascot
                        LottieView(animation: .named("reeny_waving"))
                            .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .frame(width: 100, height: 100)
                            .offset(y: mascotOffset)

                        // Title
                        Text(langManager.s(.dailyBreakTitle))
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)
                }
                .frame(height: 200)

                // ── Body ──────────────────────────────────────────
                VStack(spacing: 16) {

                    // Minutes badge
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(gradStart)
                        Text(String(format: langManager.s(.dailyBreakBodyFormat), minutesStudied))
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundStyle(Color(hex: "#065f46"))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(bgCard, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(gradStart.opacity(0.25), lineWidth: 1)
                    )

                    // Subtitle — "mola verebilirsin ama devam etmek senin kararın"
                    Text(langManager.s(.dailyBreakSubtitle))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(Color(hex: "#374151"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)

                    // ── Buttons ───────────────────────────────────
                    VStack(spacing: 10) {
                        // Primary: Devam Et
                        Button { dismiss() } label: {
                            Text(langManager.s(.dailyBreakContinue))
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [gradStart, gradEnd],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                        }

                        // Secondary: Mola Ver
                        Button { dismiss() } label: {
                            Text(langManager.s(.dailyBreakRest))
                                .font(.custom("Poppins-SemiBold", size: 15))
                                .foregroundStyle(gradStart)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(gradStart.opacity(0.5), lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(Color.white)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, topTrailingRadius: 0,
                        bottomLeadingRadius: 28, bottomTrailingRadius: 28
                    )
                )
            }
            .frame(maxWidth: 340)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 30, y: 12)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .padding(.horizontal, 24)
        }
        .onAppear { animateIn() }
    }

    // MARK: - Animations

    private func animateIn() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            cardScale   = 1.0
            cardOpacity = 1.0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1)) {
            mascotOffset = 0
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.18)) {
            cardScale   = 0.88
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}
