//
//  PlanSelectionView.swift
//  WordRemSwiftUI
//
//  Step 5 of Duolingo-style Onboarding.
//  Kullanıcı Pro veya Free seçer → Continue ile aksiyon alır.
//

import SwiftUI

struct PlanSelectionView: View {
    @EnvironmentObject var langManager: LanguageManager
    let languageName: String
    let languageCode: String
    let proficiencyLevel: Int
    var learningInterest: String = ""
    var dailyGoalMinutes: Int = 10
    var nativeLangCode: String = OL.nativeLangCode

    // 0 = Pro, 1 = Free. Default Pro (recommended)
    @State private var selectedPlan: Int = 0
    @State private var navigateToLoading = false
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Progress Bar ────────────────────────────────────────
            OBProgressBar(total: 4, filled: 4)

            // ── Header ──────────────────────────────────────────────
            OBHeader(title: langManager.s(.planSpeechBubble))

            // ── Plan Cards ──────────────────────────────────────────
            VStack(spacing: 12) {

                // Pro Plan
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = 0 }
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: langManager.s(.planRecommended), color: DS.Colors.accent)
                            Text("WordRem Pro")
                                .font(DS.Font.display(22, weight: .bold))
                                .foregroundStyle(DS.Colors.ink)
                            Text(langManager.s(.planProSubtitle))
                                .font(DS.Font.ui(15))
                                .foregroundStyle(DS.Colors.inkSoft)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        OBCheckmark(isSelected: selectedPlan == 0)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                    .modifier(OBSelectableCard(isSelected: selectedPlan == 0))
                }
                .buttonStyle(.plain)

                // Free Plan
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = 1 }
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(langManager.s(.planFreeTitle))
                                .font(DS.Font.display(22, weight: .bold))
                                .foregroundStyle(DS.Colors.ink)
                            Text(langManager.s(.planFreeSubtitle))
                                .font(DS.Font.ui(15))
                                .foregroundStyle(DS.Colors.muted)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        OBCheckmark(isSelected: selectedPlan == 1)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                    .modifier(OBSelectableCard(isSelected: selectedPlan == 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .obContentWidth()

            Spacer()

            // ── Continue Button ─────────────────────────────────────
            OBBottomBar {
                Button {
                    if selectedPlan == 0 {
                        // Pro seçili → paywall aç
                        EventManager.shared.logPaywallEvent("pro_selected_onboarding")
                        showPaywall = true
                    } else {
                        // Free seçili → direkt loading
                        EventManager.shared.logPaywallEvent("free_selected_onboarding")
                        navigateToLoading = true
                    }
                } label: {
                    Text(langManager.s(.continueButton))
                }
                .buttonStyle(InkButtonStyle())
            }
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToLoading) {
            OnboardingLoadingView(
                languageName: languageName,
                languageCode: languageCode,
                proficiencyLevel: proficiencyLevel,
                learningInterest: learningInterest,
                dailyGoalMinutes: dailyGoalMinutes,
                nativeLangCode: nativeLangCode
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView {
                showPaywall = false
                navigateToLoading = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlanSelectionView(languageName: "İngilizce", languageCode: "en", proficiencyLevel: 0)
    }
}
