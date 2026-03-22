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
            HStack(spacing: 8) {
                Capsule()
                    .fill(AppTheme.Colors.primaryOrange)
                    .frame(height: 12)
                Capsule()
                    .fill(AppTheme.Colors.primaryOrange)
                    .frame(height: 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Character & Speech Bubble
            HStack(alignment: .top, spacing: 16) {
                // Mascot
                MascotAnimationView(width: 70, height: 70)
                
                // Speech Bubble
                Text(langManager.f(.howMuchFormat, selectedLanguageName))
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(Color(hex: "#1e293b"))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    )
                    .overlay(
                        // Tail
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 20))
                            path.addLine(to: CGPoint(x: -10, y: 25))
                            path.addLine(to: CGPoint(x: 0, y: 30))
                        }
                        .fill(Color.white)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Proficiency List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(0..<proficiencyLevels.count, id: \.self) { index in
                        Button(action: {
                            selectedLevel = index
                        }) {
                            HStack(spacing: 16) {
                                // Level icon (level1-level4 assets)
                                Image("level\(min(index + 1, 4))")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                
                                Text(proficiencyLevels[index])
                                    .font(.custom("Feather-Bold", size: 15))
                                    .foregroundStyle(Color(hex: "#1e293b"))
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedLevel == index ? AppTheme.Colors.primaryOrange.opacity(0.1) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedLevel == index ? AppTheme.Colors.primaryOrange : Color(hex: "#e2e8f0"), lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            
            // Bottom Continue Button
            VStack {
                Divider()
                Button(action: {
                    navigateToResult = true
                }) {
                    Text(langManager.s(.continueButton))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(selectedLevel == nil ? Color(hex: "#94a3b8") : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedLevel == nil ? Color(hex: "#e2e8f0") : AppTheme.Colors.primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: selectedLevel == nil ? .clear : AppTheme.Colors.primaryOrange.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(selectedLevel == nil)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .background(Color(hex: "#f8fafc").ignoresSafeArea())
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
