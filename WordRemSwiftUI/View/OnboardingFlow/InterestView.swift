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
            OBProgressBar(total: 4, filled: 4)

            // ── Header ─────────────────────────────────────────────
            OBHeader(title: langManager.f(.interestQuestion, selectedLanguageName))

            // ── Interest Options ───────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(0..<interests.count, id: \.self) { i in
                        let item = interests[i]
                        Button {
                            selectedInterest = i
                        } label: {
                            HStack(spacing: 14) {
                                Image(item.asset)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)

                                Text(item.label)
                                    .font(DS.Font.ui(17, weight: .medium))
                                    .foregroundStyle(DS.Colors.ink)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                OBCheckmark(isSelected: selectedInterest == i)
                            }
                            .modifier(OBSelectableCard(isSelected: selectedInterest == i))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .obContentWidth()
            }

            // ── Continue Button ────────────────────────────────────
            OBBottomBar {
                Button {
                    navigateToGoal = true
                } label: {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
                .obDisabled(selectedInterest == nil)
            }
        }
        .paperBackground()
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
