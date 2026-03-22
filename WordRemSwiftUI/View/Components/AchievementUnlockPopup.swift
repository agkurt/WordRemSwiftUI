//
//  AchievementUnlockPopup.swift
//  WordRemSwiftUI
//
//  Full-screen overlay shown when the user earns a new achievement.
//  Uses Lottie (reeny_waving) + achievement icon + rarity badge.
//  Auto-dismisses after 4 seconds or on tap.
//

import SwiftUI
import Lottie

struct AchievementUnlockPopup: View {

    @EnvironmentObject var langManager: LanguageManager
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var appear = false
    @State private var scale: CGFloat = 0.7
    @State private var iconScale: CGFloat = 0.4

    var body: some View {
        ZStack {
            // ── Dimmed background ─────────────────────────────────────
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // ── Card ─────────────────────────────────────────────────
            VStack(spacing: 0) {

                // Lottie mascot (compact, sits above the card)
                LottieView(animation: .named("reeny_waving"))
                    .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 130, height: 130)
                    .offset(y: 10)
                    .zIndex(1)

                // Main card
                VStack(spacing: 20) {

                    // Rarity badge
                    Text(achievement.rarity.label.uppercased())
                        .font(.custom("Poppins-Bold", size: 11))
                        .foregroundStyle(.white)
                        .tracking(1.5)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: achievement.rarity.gradientColors,
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                        )

                    // Achievement icon circle
                    ZStack {
                        Circle()
                            .fill(achievement.color.opacity(0.15))
                            .frame(width: 90, height: 90)

                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [achievement.color.opacity(0.6), achievement.color],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 90, height: 90)

                        Image(systemName: achievement.icon)
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(achievement.color)
                    }
                    .shadow(color: achievement.color.opacity(0.45), radius: 16, y: 6)
                    .scaleEffect(iconScale)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6).delay(0.15),
                        value: iconScale
                    )

                    // "New Achievement!" header
                    VStack(spacing: 4) {
                        Text(langManager.s(.achievementNewUnlocked))
                            .font(.custom("Poppins-Bold", size: 13))
                            .foregroundStyle(achievement.rarity.color)

                        Text(achievement.title)
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundStyle(Color(hex: "#1a1a2e"))
                            .multilineTextAlignment(.center)
                    }

                    // Description
                    Text(achievement.description)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(Color(hex: "#64748b"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    // Dismiss hint
                    Text(langManager.s(.achievementTapToDismiss))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                        .padding(.bottom, 4)
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.18), radius: 32, y: 10)
                )
                .zIndex(0)
            }
            .scaleEffect(scale)
            .padding(.horizontal, 28)
        }
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appear = true
                scale = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                iconScale = 1.0
            }
            // Auto-dismiss after 4.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 4_500_000_000)
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            appear = false
            scale = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }
}
