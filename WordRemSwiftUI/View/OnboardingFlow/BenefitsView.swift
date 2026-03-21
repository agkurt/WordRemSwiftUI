//
//  BenefitsView.swift
//  WordRemSwiftUI
//
//  Step 3 of Duolingo-style Onboarding.
//

import SwiftUI

struct BenefitsView: View {
    let selectedLanguageName: String
    let selectedLanguageCode: String
    let proficiencyLevel: Int
    @State private var navigateToQuiz = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index < 3 ? AppTheme.Colors.primaryOrange : Color(hex: "#e2e8f0"))
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
                Text(OL.s(.benefitsTitle))
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
                    // Push everything up slightly
                    .offset(y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Benefits List
            VStack(alignment: .leading, spacing: 32) {
                // Benefit 1
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.purple)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(OL.s(.benefit1Title))
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundStyle(Color(hex: "#1e293b"))
                        Text(OL.s(.benefit1Desc))
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(Color(hex: "#64748b"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Benefit 2
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.blue)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(OL.s(.benefit2Title))
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundStyle(Color(hex: "#1e293b"))
                        Text(OL.s(.benefit2Desc))
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(Color(hex: "#64748b"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Benefit 3
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.orange)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(OL.s(.benefit3Title))
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundStyle(Color(hex: "#1e293b"))
                        Text(OL.s(.benefit3Desc))
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(Color(hex: "#64748b"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Bottom Continue Button
            VStack {
                Divider()
                Button(action: {
                    navigateToQuiz = true
                }) {
                    Text(OL.s(.continueButton))
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
        .navigationDestination(isPresented: $navigateToQuiz) {
            InterestView(
                selectedLanguageName: selectedLanguageName,
                selectedLanguageCode: selectedLanguageCode,
                proficiencyLevel: proficiencyLevel
            )
        }
    }
}

#Preview {
    BenefitsView(selectedLanguageName: "İngilizce", selectedLanguageCode: "en", proficiencyLevel: 0)
}
