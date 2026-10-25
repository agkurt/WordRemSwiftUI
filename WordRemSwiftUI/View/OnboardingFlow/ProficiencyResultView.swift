//
//  ProficiencyResultView.swift
//  WordRemSwiftUI
//
//  Shown after proficiency level selection — encourages the user.
//

import SwiftUI

struct ProficiencyResultView: View {
    @EnvironmentObject var langManager: LanguageManager
    let selectedLanguageName: String
    let selectedLanguageCode: String
    let proficiencyLevel: Int
    let nativeLangCode: String
    @State private var navigateToBenefits = false

    // MARK: - Dynamic content based on selected level

    private var percentage: String {
        let values = ["70%", "55%", "40%", "25%", "10%"]
        let index = min(proficiencyLevel, values.count - 1)
        return values[index]
    }

    private var levelLabel: String {
        let keys: [OL.Key] = [
            .profResultBeginner, .profResultElementary, .profResultIntermediate,
            .profResultUpperInter, .profResultAdvanced
        ]
        let index = min(proficiencyLevel, keys.count - 1)
        return langManager.s(keys[index])
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // ── Typographic statement ──────────────────────────────
            VStack(alignment: .leading, spacing: 20) {
                Eyebrow(text: levelLabel)

                Rectangle()
                    .fill(DS.Colors.ink)
                    .frame(width: 32, height: 2)

                (Text(langManager.s(.profResultItsOkay))
                    .foregroundColor(DS.Colors.ink)
                + Text(percentage)
                    .foregroundColor(DS.Colors.accent)
                + Text(langManager.f(.profResultPeopleAre, levelLabel))
                    .foregroundColor(DS.Colors.ink))
                    .font(DS.Font.display(32, weight: .bold))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .obContentWidth()

            Spacer()
            Spacer()

            // ── Continue Button ────────────────────────────────────
            OBBottomBar {
                Button(action: {
                    navigateToBenefits = true
                }) {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
            }
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToBenefits) {
            BenefitsView(
                selectedLanguageName: selectedLanguageName,
                selectedLanguageCode: selectedLanguageCode,
                proficiencyLevel: proficiencyLevel,
                nativeLangCode: nativeLangCode
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProficiencyResultView(
            selectedLanguageName: "İngilizce",
            selectedLanguageCode: "en",
            proficiencyLevel: 0,
            nativeLangCode: "tr"
        )
    }
}
