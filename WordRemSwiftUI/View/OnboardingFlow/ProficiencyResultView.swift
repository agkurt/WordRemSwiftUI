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

            // ── Speech Bubble ──────────────────────────────────────
            VStack(spacing: 0) {
                // Bubble body
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#f1f5f9"))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)

                    (Text(langManager.s(.profResultItsOkay))
                        .font(.custom("Feather-Bold", size: 20))
                        .foregroundColor(Color(hex: "#1e293b"))
                    + Text(percentage)
                        .font(.custom("Feather-Bold", size: 20))
                        .foregroundColor(AppTheme.Colors.primaryOrange)
                    + Text(langManager.f(.profResultPeopleAre, levelLabel))
                        .font(.custom("Feather-Bold", size: 20))
                        .foregroundColor(Color(hex: "#1e293b")))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

                // Bubble tail — downward triangle
                PRDownwardTriangle()
                    .fill(Color(hex: "#f1f5f9"))
                    .frame(width: 28, height: 18)
            }
            .padding(.bottom, 8)

           
            MascotAnimationView(width: 260, height: 260)

            Spacer()

            // ── Continue Button ────────────────────────────────────
            VStack(spacing: 0) {
                Divider()
                Button(action: {
                    navigateToBenefits = true
                }) {
                    Text(langManager.s(.continueButton))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.Colors.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .background(Color.white.ignoresSafeArea())
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

// MARK: - Downward triangle shape for bubble tail

private struct PRDownwardTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
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
