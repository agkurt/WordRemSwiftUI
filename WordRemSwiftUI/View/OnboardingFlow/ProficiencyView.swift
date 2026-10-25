//
//  ProficiencyView.swift
//  WordRemSwiftUI
//
//  Step 2 of Duolingo-style Onboarding.
//

import SwiftUI

struct ProficiencyView: View {
    @EnvironmentObject var langManager: LanguageManager
    let selectedLanguageName: String
    let selectedLanguageCode: String
    let nativeLangCode: String
    @State private var selectedLevel: Int?
    @State private var navigateToResult = false
    
    var proficiencyLevels: [String] {
        [
            langManager.s(.level1),
            langManager.s(.level2),
            langManager.s(.level3),
            langManager.s(.level4)
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            OBProgressBar(total: 2, filled: 2)

            // Header
            OBHeader(title: langManager.f(.howMuchFormat, selectedLanguageName))

            // Proficiency List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(0..<proficiencyLevels.count, id: \.self) { index in
                        Button(action: {
                            selectedLevel = index
                        }) {
                            HStack(spacing: 14) {
                                // Level icon (level1-level4 assets)
                                Image("level\(min(index + 1, 4))")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)

                                Text(proficiencyLevels[index])
                                    .font(DS.Font.ui(17, weight: .medium))
                                    .foregroundStyle(DS.Colors.ink)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                OBCheckmark(isSelected: selectedLevel == index)
                            }
                            .modifier(OBSelectableCard(isSelected: selectedLevel == index))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .obContentWidth()
            }

            // Bottom Continue Button
            OBBottomBar {
                Button(action: {
                    navigateToResult = true
                }) {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
                .obDisabled(selectedLevel == nil)
            }
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            ProficiencyResultView(
                selectedLanguageName: selectedLanguageName,
                selectedLanguageCode: selectedLanguageCode,
                proficiencyLevel: selectedLevel ?? 0,
                nativeLangCode: nativeLangCode
            )
        }
    }
}

#Preview {
    ProficiencyView(selectedLanguageName: "İngilizce", selectedLanguageCode: "en", nativeLangCode: "tr")
}
