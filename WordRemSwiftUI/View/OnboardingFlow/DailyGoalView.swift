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
        let barHeights: [CGFloat]   // 4 bars, increasing height
    }

    private var goals: [GoalOption] {
        [
            GoalOption(minutes: 5,  label: langManager.s(.dailyGoalCasual),  barHeights: [8, 13, 18, 18]),
            GoalOption(minutes: 10, label: langManager.s(.dailyGoalRegular), barHeights: [8, 13, 18, 24]),
            GoalOption(minutes: 15, label: langManager.s(.dailyGoalAccel),   barHeights: [8, 13, 20, 28]),
            GoalOption(minutes: 20, label: langManager.s(.dailyGoalIntense), barHeights: [8, 14, 22, 30]),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Progress Bar ───────────────────────────────────────
            OBProgressBar(total: 4, filled: 4)

            // ── Header ─────────────────────────────────────────────
            OBHeader(title: langManager.s(.dailyGoalQuestion))

            // ── Goal Options ───────────────────────────────────────
            VStack(spacing: 10) {
                ForEach(0..<goals.count, id: \.self) { i in
                    let goal = goals[i]
                    let isSelected = selectedGoal == i
                    Button {
                        selectedGoal = i
                    } label: {
                        HStack(spacing: 14) {
                            // Bar chart icon
                            HStack(alignment: .bottom, spacing: 3) {
                                ForEach(0..<4, id: \.self) { b in
                                    Capsule()
                                        .fill(isSelected ? DS.Colors.ink : DS.Colors.muted.opacity(0.45))
                                        .frame(width: 4, height: goal.barHeights[b])
                                }
                            }
                            .frame(width: 30, height: 30, alignment: .bottom)

                            Text(String(format: langManager.s(.dailyGoalMinFormat), goal.minutes))
                                .font(DS.Font.ui(17, weight: .medium))
                                .foregroundStyle(DS.Colors.ink)

                            Spacer()

                            Text(goal.label)
                                .font(DS.Font.ui(15))
                                .foregroundStyle(DS.Colors.muted)

                            OBCheckmark(isSelected: isSelected)
                        }
                        .modifier(OBSelectableCard(isSelected: isSelected))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .obContentWidth()

            Spacer()

            // ── Continue Button ────────────────────────────────────
            OBBottomBar {
                Button {
                    if let g = selectedGoal {
                        UserDefaults.standard.set(goals[g].minutes, forKey: "dailyGoalMinutes")
                    }
                    navigateToQuiz = true
                } label: {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
                .obDisabled(selectedGoal == nil)
            }
        }
        .paperBackground()
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
