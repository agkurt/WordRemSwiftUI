//
//  StreakCelebrationView.swift
//  WordRemSwiftUI
//
//  Full-screen streak celebration shown once per day after the user
//  opens the app following midnight.
//

import SwiftUI

// MARK: - View
struct StreakCelebrationView: View {

    let streakDays: Int
    let onContinue: () -> Void

    // MARK: - Animation states
    @State private var imageScale:     CGFloat = 0.5
    @State private var imageOpacity:   CGFloat = 0
    @State private var contentOpacity: CGFloat = 0
    @State private var glowRadius:     CGFloat = 0
    @State private var dotAnimations   = Array(repeating: false, count: 7)

    // MARK: - Week helpers
    /// ISO weekday index: Mon=0 … Sun=6
    private var todayISO: Int {
        let wd = Calendar.current.component(.weekday, from: Date()) // 1=Sun … 7=Sat
        return (wd + 5) % 7
    }

    private var days: [String] { AL.weekDayAbbreviations }

    private enum DayState { case today, streaked, missed, future }

    private func dayState(_ i: Int) -> DayState {
        if i == todayISO           { return .today }
        if i > todayISO            { return .future }
        let daysAgo = todayISO - i
        return daysAgo < streakDays ? .streaked : .missed
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()
                headerTexts
                    .opacity(contentOpacity)
                Spacer(minLength: 28)
                energyImage
                Spacer(minLength: 28)
                weekRow
                    .opacity(contentOpacity)
                    .padding(.horizontal, 20)
                Spacer(minLength: 44)
                continueButton
                    .opacity(contentOpacity)
                    .padding(.horizontal, 24)
                Spacer(minLength: 44)
            }
        }
        .onAppear { runEntrance() }
    }

    // MARK: - Background
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#1e0a5e"),
                    Color(hex: "#2d1b69"),
                    Color(hex: "#0d062a")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative blurred orbs
            Circle()
                .fill(Color(hex: "#7c3aed").opacity(0.25))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -80, y: -180)

            Circle()
                .fill(Color(hex: "#E8409C").opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: 100, y: 200)
        }
    }

    // MARK: - Header
    private var headerTexts: some View {
        VStack(spacing: 10) {
            Text(streakDays == 1
                 ? AL.s(.streakStartedTitle)
                 : AL.f(.streakContinuedTitle, streakDays))
                .font(.custom("Poppins-Bold", size: 30))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(AL.s(.streakSubtitle))
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
    }

    // MARK: - Energy image
    private var energyImage: some View {
        Image("energy")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .scaleEffect(imageScale)
            .opacity(imageOpacity)
            .shadow(color: Color(hex: "#FFD700").opacity(0.6), radius: glowRadius, y: 8)
    }

    // MARK: - Week row
    private var weekRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 8) {
                    dayCircle(i)
                    Text(days[i])
                        .font(.custom("Poppins-Bold", size: 10))
                        .foregroundStyle(
                            dayState(i) == .future
                            ? Color.white.opacity(0.25)
                            : Color.white.opacity(0.85)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func dayCircle(_ i: Int) -> some View {
        let state = dayState(i)

        ZStack {
            // Background circle
            Circle()
                .fill(circleFill(state))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle().stroke(circleBorder(state), lineWidth: 2)
                )

            // Icon
            switch state {
            case .today:
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color(hex: "#1a0a4a"))
                    .scaleEffect(dotAnimations[i] ? 1.0 : 0.3)

            case .streaked:
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color(hex: "#FFD700"))
                    .scaleEffect(dotAnimations[i] ? 1.0 : 0.0)

            default:
                EmptyView()
            }
        }
        .scaleEffect(state == .today && dotAnimations[i] ? 1.08 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: dotAnimations[i])
    }

    private func circleFill(_ state: DayState) -> Color {
        switch state {
        case .today:    return Color(hex: "#FFD700")
        case .streaked: return Color(hex: "#FFD700").opacity(0.15)
        case .missed:   return Color.white.opacity(0.05)
        case .future:   return Color(hex: "#2d1b69").opacity(0.6)
        }
    }

    private func circleBorder(_ state: DayState) -> Color {
        switch state {
        case .today:    return Color(hex: "#FFD700")
        case .streaked: return Color(hex: "#FFD700").opacity(0.55)
        case .missed:   return Color.white.opacity(0.08)
        case .future:   return Color.white.opacity(0.08)
        }
    }

    // MARK: - Continue button
    private var continueButton: some View {
        Button(action: onContinue) {
            Text(AL.s(.streakContinue))
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#E8409C"), Color(hex: "#9333ea")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "#E8409C").opacity(0.45), radius: 14, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Entrance animations
    private func runEntrance() {
        // Image bounce in
        withAnimation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.1)) {
            imageScale   = 1.0
            imageOpacity = 1.0
        }
        // Glow pulse
        withAnimation(.easeInOut(duration: 1.2).delay(0.5).repeatForever(autoreverses: true)) {
            glowRadius = 40
        }
        // Text & week row fade in
        withAnimation(.easeOut(duration: 0.45).delay(0.35)) {
            contentOpacity = 1.0
        }
        // Staggered dot animations
        for i in 0..<7 {
            let state = dayState(i)
            guard state == .streaked || state == .today else { continue }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55 + Double(i) * 0.08) {
                dotAnimations[i] = true
            }
        }
    }
}

// MARK: - Scale button style (local)
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

#Preview {
    StreakCelebrationView(streakDays: 5) {}
}
