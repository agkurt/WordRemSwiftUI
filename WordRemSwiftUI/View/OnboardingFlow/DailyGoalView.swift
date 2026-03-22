//
//  DailyGoalView.swift
//  WordRemSwiftUI
//
//  Onboarding step: "What is your daily goal for practicing?"
//

import SwiftUI

struct DailyGoalView: View {
    @EnvironmentObject var langManager: LanguageManager
    let selectedLanguageName: String
    let selectedLanguageCode: String
    let proficiencyLevel: Int
    let learningInterest: String
    let nativeLangCode: String

    @State private var selectedGoal: Int?
    @State private var navigateToQuiz = false

    private struct GoalOption {
        let minutes: Int
        let label: String
        let barColor: Color
        let barHeights: [CGFloat]   // 4 bars, increasing height
    }

    private let goals: [GoalOption] = [
        GoalOption(minutes: 5,  label: "Casual",       barColor: Color(hex: "#4ade80"),
                   barHeights: [8, 13, 18, 18]),
        GoalOption(minutes: 10, label: "Regular",      barColor: Color(hex: "#60a5fa"),
                   barHeights: [8, 13, 18, 24]),
        GoalOption(minutes: 15, label: "Accelerated",  barColor: Color(hex: "#c084fc"),
                   barHeights: [8, 13, 20, 28]),
        GoalOption(minutes: 20, label: "Intense",      barColor: Color(hex: "#f472b6"),
                   barHeights: [8, 14, 22, 30]),
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── Progress Bar ───────────────────────────────────────
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(AppTheme.Colors.primaryOrange)
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // ── Mascot + Speech Bubble ─────────────────────────────
            HStack(alignment: .top, spacing: 16) {
                MascotAnimationView(width: 70, height: 70)

                Text("What is your daily goal\nfor practicing?")
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(Color(hex: "#1e293b"))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#f0f4ff"))
                            .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                    )
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 20))
                            path.addLine(to: CGPoint(x: -10, y: 25))
                            path.addLine(to: CGPoint(x: 0, y: 30))
                        }
                        .fill(Color(hex: "#f0f4ff"))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)

            // ── Goal Options ───────────────────────────────────────
            VStack(spacing: 12) {
                ForEach(0..<goals.count, id: \.self) { i in
                    let goal = goals[i]
                    Button {
                        selectedGoal = i
                    } label: {
                        HStack(spacing: 16) {
                            // Bar chart icon
                            HStack(alignment: .bottom, spacing: 3) {
                                ForEach(0..<4, id: \.self) { b in
                                    Capsule()
                                        .fill(selectedGoal == i
                                              ? goal.barColor
                                              : goal.barColor.opacity(0.5))
                                        .frame(width: 5, height: goal.barHeights[b])
                                }
                            }
                            .frame(width: 34, height: 32, alignment: .bottom)

                            Text("\(goal.minutes) min")
                                .font(.custom("Feather-Bold", size: 16))
                                .foregroundStyle(Color(hex: "#1e293b"))

                            Spacer()

                            Text(goal.label)
                                .font(.custom("Feather-Bold", size: 14))
                                .foregroundStyle(Color(hex: "#94a3b8"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedGoal == i
                                      ? goal.barColor.opacity(0.08)
                                      : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedGoal == i
                                        ? goal.barColor
                                        : Color(hex: "#e2e8f0"), lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // ── Continue Button ────────────────────────────────────
            VStack {
                Divider()
                Button {
                    if let g = selectedGoal {
                        UserDefaults.standard.set(goals[g].minutes, forKey: "dailyGoalMinutes")
                    }
                    navigateToQuiz = true
                } label: {
                    Text(langManager.s(.continueButton))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(selectedGoal == nil ? Color(hex: "#94a3b8") : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedGoal == nil
                                    ? Color(hex: "#e2e8f0")
                                    : AppTheme.Colors.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: selectedGoal == nil ? .clear
                                : AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(selectedGoal == nil)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .background(Color(hex: "#f8fafc").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuiz) {
            let minutes = selectedGoal.map { goals[$0].minutes } ?? 10
            OnboardingQuizView(
                languageName: selectedLanguageName,
                languageCode: selectedLanguageCode,
                proficiencyLevel: proficiencyLevel,
                learningInterest: learningInterest,
                dailyGoalMinutes: minutes,
                nativeLangCode: nativeLangCode
            )
        }
    }
}

#Preview {
    NavigationStack {
        DailyGoalView(selectedLanguageName: "English", selectedLanguageCode: "en", proficiencyLevel: 1, learningInterest: "Career", nativeLangCode: "tr")
    }
}
