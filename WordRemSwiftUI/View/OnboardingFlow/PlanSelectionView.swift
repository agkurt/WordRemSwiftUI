//
//  PlanSelectionView.swift
//  WordRemSwiftUI
//
//  Step 5 of Duolingo-style Onboarding.
//  Kullanıcı Pro veya Free seçer → Continue ile aksiyon alır.
//

import SwiftUI

struct PlanSelectionView: View {
    let languageName: String
    let languageCode: String
    let proficiencyLevel: Int
    var learningInterest: String = ""
    var dailyGoalMinutes: Int = 10
    var nativeLangCode: String = OL.phoneCode

    // 0 = Pro, 1 = Free. Default Pro (recommended)
    @State private var selectedPlan: Int = 0
    @State private var navigateToLoading = false
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Progress Bar ────────────────────────────────────────
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(AppTheme.Colors.primaryOrange)
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // ── Mascot & Speech Bubble ──────────────────────────────
            HStack(alignment: .top, spacing: 16) {
                MascotAnimationView(width: 70, height: 70)

                Text(OL.s(.planSpeechBubble))
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(Color(hex: "#1e293b"))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    )
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 20))
                            path.addLine(to: CGPoint(x: -10, y: 25))
                            path.addLine(to: CGPoint(x: 0, y: 30))
                        }
                        .fill(Color.white)
                    )
                    .offset(y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)

            // ── Plan Cards ──────────────────────────────────────────
            VStack(spacing: 16) {

                // Pro Plan
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = 0 }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WordRem Pro")
                            .font(.custom("Feather-Bold", size: 18))
                            .foregroundStyle(Color.white)
                        Text(OL.s(.planProSubtitle))
                            .font(.custom("Feather-Bold", size: 15))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#8b5cf6"), Color(hex: "#7c3aed")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedPlan == 0 ? Color.white : Color.clear,
                                lineWidth: 2.5
                            )
                    )
                    .shadow(
                        color: Color(hex: "#8b5cf6").opacity(selectedPlan == 0 ? 0.5 : 0.25),
                        radius: selectedPlan == 0 ? 14 : 8,
                        y: 5
                    )
                    .overlay(alignment: .topTrailing) {
                        Text(OL.s(.planRecommended))
                            .font(.custom("Feather-Bold", size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#f97316"))
                            .clipShape(Capsule())
                            .offset(y: -12)
                    }
                    // Seçim checkmark
                    .overlay(alignment: .trailing) {
                        if selectedPlan == 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .padding(.trailing, 20)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }

                // Free Plan
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = 1 }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(OL.s(.planFreeTitle))
                                .font(.custom("Feather-Bold", size: 18))
                                .foregroundStyle(Color(hex: "#1e293b"))
                            Text(OL.s(.planFreeSubtitle))
                                .font(.custom("Feather-Bold", size: 15))
                                .foregroundStyle(Color(hex: "#64748b"))
                        }
                        Spacer()
                        if selectedPlan == 1 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AppTheme.Colors.primaryOrange)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedPlan == 1 ? AppTheme.Colors.primaryOrange : Color(hex: "#e2e8f0"),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: .black.opacity(selectedPlan == 1 ? 0.08 : 0.04),
                        radius: 8, y: 3
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // ── Continue Button ─────────────────────────────────────
            VStack(spacing: 0) {
                Divider()
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
                    Text(OL.s(.continueButton))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(.white)
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
        .background(Color(hex: "#f8fafc").ignoresSafeArea())
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
