//
//  QuizResultView.swift
//  WordRemSwiftUI
//
//  Shown after a quiz is completed — displays score, stars, XP earned.
//

import SwiftUI
import Lottie

struct QuizResultView: View {

    let score: Int       // 0–100
    let stars: Int       // 0–3
    let xpEarned: Int
    let levelTitle: String
    let onDone: () -> Void

    @State private var starScale: CGFloat = 0.1
    @State private var showDetails = false
    @State private var confettiCount = 0

    private var passed: Bool { stars > 0 }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundStart.ignoresSafeArea()

            // Confetti particles
            if passed {
                ForEach(0..<confettiCount, id: \.self) { i in
                    ConfettiParticle(index: i)
                }
            }

            VStack(spacing: 32) {
                Spacer()

                // Mascot animation
                LottieView(animation: .named("reeny_waving"))
                    .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 160, height: 160)

                // Title
                Text(passed ? AL.s(.resultLevelComplete) : AL.s(.resultKeepPracticing))
                    .font(.custom("Feather-Bold", size: 28))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(levelTitle)
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

               
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.system(size: 40))
                            .foregroundStyle(i <= stars ? Color.yellow : AppTheme.Colors.inputBorder)
                            .scaleEffect(starScale)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.5)
                                    .delay(Double(i) * 0.15),
                                value: starScale
                            )
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        starScale = 1.0
                        if passed { confettiCount = 30 }
                        withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
                            showDetails = true
                        }
                    }
                }

                // Score chips
                if showDetails {
                    HStack(spacing: 16) {
                        ResultChip(
                            icon: "percent",
                            label: AL.s(.resultScore),
                            value: "\(score)%",
                            color: scoreColor
                        )
                        ResultChip(
                            icon: "bolt.fill",
                            label: AL.s(.resultXPEarned),
                            value: "+\(xpEarned)",
                            color: .orange
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Action button
                Button(action: onDone) {
                    Text(passed ? AL.s(.resultContinue) : AL.s(.resultTryAgain))
                        .font(.custom("Feather-Bold", size: 18))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: AppTheme.Shadows.vibrantColor,
                                radius: AppTheme.Shadows.vibrantRadius,
                                y: AppTheme.Shadows.vibrantY)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private var scoreColor: Color {
        switch score {
        case 90...100: return .green
        case 70...89:  return AppTheme.Colors.primaryOrange
        default:       return .red
        }
    }
}

// MARK: - Result Chip
private struct ResultChip: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.custom("Feather-Bold", size: 20))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(label)
                .font(.custom("Feather-Bold", size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(width: 120, height: 96)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppTheme.Shadows.cardColor,
                radius: AppTheme.Shadows.cardRadius,
                y: AppTheme.Shadows.cardY)
    }
}

// MARK: - Confetti Particle
private struct ConfettiParticle: View {
    let index: Int
    @State private var yOffset: CGFloat = -100
    @State private var xOffset: CGFloat = CGFloat.random(in: -150...150)
    @State private var opacity: Double = 1

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    private var color: Color { colors[index % colors.count] }
    private var size: CGFloat { CGFloat.random(in: 6...12) }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.8).delay(Double(index) * 0.04)) {
                    yOffset = CGFloat.random(in: 300...700)
                    xOffset = CGFloat.random(in: -180...180)
                }
                withAnimation(.easeIn(duration: 0.4).delay(Double(index) * 0.04 + 1.4)) {
                    opacity = 0
                }
            }
    }
}
