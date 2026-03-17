//
//  PlanSelectionView.swift
//  WordRemSwiftUI
//
//  Step 5 of Duolingo-style Onboarding.
//  Offers Premium / Free choices before final loading step.
//

import SwiftUI

struct PlanSelectionView: View {
    let languageName: String
    @State private var navigateToLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(AppTheme.Colors.primaryOrange)
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Mascot & Speech Bubble
            HStack(alignment: .top, spacing: 16) {
                // Mascot
                MascotAnimationView(width: 70, height: 70)
                
                // Speech Bubble
                Text("Harika! İstediğin zaman\nplanını yükseltebilirsin.")
                    .font(.custom("Poppins-Bold", size: 16))
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
                    // Push up
                    .offset(y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
            
            // Plans List
            VStack(spacing: 24) {
                // Pro Plan
                Button(action: {
                    // Logic to subscribe
                    navigateToLoading = true
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WordRem Pro")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundStyle(Color.white)
                        Text("Daha hızlı ilerleme, reklamsız deneyim")
                            .font(.custom("Poppins-Regular", size: 15))
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
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color(hex: "#8b5cf6").opacity(0.4), radius: 10, y: 5)
                    .overlay(
                        Text("TAVSİYE EDİLEN")
                            .font(.custom("Poppins-Bold", size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#f97316"))
                            .clipShape(Capsule())
                            .offset(y: -12),
                        alignment: .topTrailing
                    )
                }
                
                // Free Plan
                Button(action: {
                    navigateToLoading = true
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ücretsiz Öğrenim")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundStyle(Color(hex: "#1e293b"))
                        Text("Reklamlarla birlikte ana öğrenim özellikleri")
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundStyle(Color(hex: "#64748b"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#cbd5e1"), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Bottom Continue Button (Hidden/Optional if we use direct cards, but let's keep consistent)
            VStack {
                Divider()
                Button(action: {
                    navigateToLoading = true
                }) {
                    Text("DEVAM ET")
                        .font(.custom("Poppins-Bold", size: 17))
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
            OnboardingLoadingView(languageName: languageName)
        }
    }
}

#Preview {
    PlanSelectionView(languageName: "İngilizce")
}
