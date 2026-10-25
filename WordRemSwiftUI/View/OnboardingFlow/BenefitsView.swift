//
//  BenefitsView.swift
//  WordRemSwiftUI
//
//  Step 3 of Duolingo-style Onboarding.
//

import SwiftUI

struct BenefitsView: View {
    @EnvironmentObject var langManager: LanguageManager
    let selectedLanguageName: String
    let selectedLanguageCode: String
    let proficiencyLevel: Int
    let nativeLangCode: String
    @State private var navigateToQuiz = false
    
    private var benefits: [(icon: String, title: String, desc: String)] {
        [
            ("bubble.left.and.bubble.right", langManager.s(.benefit1Title), langManager.s(.benefit1Desc)),
            ("text.book.closed",             langManager.s(.benefit2Title), langManager.s(.benefit2Desc)),
            ("clock",                        langManager.s(.benefit3Title), langManager.s(.benefit3Desc)),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            OBProgressBar(total: 4, filled: 3)

            // Header
            OBHeader(title: langManager.s(.benefitsTitle))

            // Benefits List
            PaperCard(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(benefits.enumerated()), id: \.offset) { idx, item in
                        if idx > 0 {
                            Rectangle()
                                .fill(DS.Colors.line)
                                .frame(height: 1)
                                .padding(.leading, 68)
                        }
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(DS.Colors.accent)
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(DS.Font.ui(17, weight: .semibold))
                                    .foregroundStyle(DS.Colors.ink)
                                Text(item.desc)
                                    .font(DS.Font.ui(15))
                                    .foregroundStyle(DS.Colors.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .padding(.horizontal, 24)
            .obContentWidth()

            Spacer()

            // Bottom Continue Button
            OBBottomBar {
                Button(action: {
                    navigateToQuiz = true
                }) {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
            }
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuiz) {
            InterestView(
                selectedLanguageName: selectedLanguageName,
                selectedLanguageCode: selectedLanguageCode,
                proficiencyLevel: proficiencyLevel,
                nativeLangCode: nativeLangCode
            )
        }
    }
}

#Preview {
    BenefitsView(selectedLanguageName: "İngilizce", selectedLanguageCode: "en", proficiencyLevel: 0, nativeLangCode: "tr")
}
