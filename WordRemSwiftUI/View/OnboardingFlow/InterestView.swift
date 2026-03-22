//
//  InterestView.swift
//  WordRemSwiftUI
//
//  Onboarding step: "Why do you want to learn [language]?"
//

import SwiftUI

struct InterestView: View {
    @EnvironmentObject var langManager: LanguageManager
    let selectedLanguageName: String
    let selectedLanguageCode: String
    let proficiencyLevel: Int
    let nativeLangCode: String

    @State private var selectedInterest: Int?
    @State private var navigateToGoal = false

    private var interests: [(label: String, asset: String)] {
        [
            (langManager.s(.interestCareer),     "career"),
            (langManager.s(.interestEducation),  "education"),
            (langManager.s(.interestFunCulture), "funandculture"),
            (langManager.s(.interestDaily),      "daily"),
            (langManager.s(.interestTravel),     "travel"),
            (langManager.s(.interestFamily),     "friendsandfamily"),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Progress Bar ───────────────────────────────────────
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i < 4 ? AppTheme.Colors.primaryOrange : Color(hex: "#e2e8f0"))
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // ── Mascot + Speech Bubble ─────────────────────────────
            HStack(alignment: .top, spacing: 16) {
                MascotAnimationView(width: 70, height: 70)

                Text(langManager.f(.interestQuestion, selectedLanguageName))
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

            // ── Interest Options ───────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(0..<interests.count, id: \.self) { i in
                        let item = interests[i]
                        Button {
                            selectedInterest = i
                        } label: {
                            HStack(spacing: 16) {
                                Image(item.asset)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)

                                Text(item.label)
                                    .font(.custom("Feather-Bold", size: 15))
                                    .foregroundStyle(Color(hex: "#1e293b"))

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedInterest == i
                                          ? AppTheme.Colors.primaryOrange.opacity(0.1)
                                          : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedInterest == i
                                            ? AppTheme.Colors.primaryOrange
                                            : Color(hex: "#e2e8f0"), lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            // ── Continue Button ────────────────────────────────────
            VStack {
                Divider()
                Button {
                    navigateToGoal = true
                } label: {
                    Text(langManager.s(.continueButton))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(selectedInterest == nil ? Color(hex: "#94a3b8") : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedInterest == nil
                                    ? Color(hex: "#e2e8f0")
                                    : AppTheme.Colors.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: selectedInterest == nil ? .clear
                                : AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(selectedInterest == nil)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .background(Color(hex: "#f8fafc").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToGoal) {
            let label = selectedInterest.map { interests[$0].label } ?? ""
            DailyGoalView(
                selectedLanguageName: selectedLanguageName,
                selectedLanguageCode: selectedLanguageCode,
                proficiencyLevel: proficiencyLevel,
                learningInterest: label,
                nativeLangCode: nativeLangCode
            )
        }
    }
}

#Preview {
    NavigationStack {
        InterestView(selectedLanguageName: "English", selectedLanguageCode: "en", proficiencyLevel: 1, nativeLangCode: "tr")
    }
}
