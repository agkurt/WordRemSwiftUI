//
//  WelcomeProView.swift
//  WordRemSwiftUI
//
//  Satın alma başarılı olduğunda gösterilen hoşgeldin popup'ı.
//

import SwiftUI

struct WelcomeProView: View {

    @EnvironmentObject var langManager: LanguageManager
    var onContinue: () -> Void

    private let proColor     = Color(hex: "#8b5cf6")
    private let proColorDark = Color(hex: "#7c3aed")

    private var features: [(String, String)] {[
        ("infinity",     langManager.s(.welcomeProFeature1)),
        ("lightbulb",    langManager.s(.welcomeProFeature2)),
        ("cpu",          langManager.s(.welcomeProFeature3)),
    ]}

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [proColor.opacity(0.18), Color(hex: "#f8fafc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Crown + Mascot
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [proColor, proColorDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: proColor.opacity(0.4), radius: 20, y: 8)

                    Text("👑")
                        .font(.system(size: 48))
                }
                .padding(.bottom, 28)

                // Title
                Text(langManager.s(.welcomeProTitle))
                    .font(.custom("Feather-Bold", size: 26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [proColor, proColorDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Subtitle
                Text(langManager.s(.welcomeProSubtitle))
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 36)

                // Feature list
                VStack(spacing: 16) {
                    ForEach(features, id: \.0) { icon, text in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(proColor.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(proColor)
                            }
                            Text(text)
                                .font(.custom("Feather-Bold", size: 15))
                                .foregroundStyle(Color(hex: "#1e293b"))
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(proColor)
                        }
                        .padding(.horizontal, 28)
                    }
                }
                .padding(.bottom, 44)

                Spacer()

                // CTA button
                Button(action: onContinue) {
                    Text(langManager.s(.welcomeProCTA))
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [proColor, proColorDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: proColor.opacity(0.4), radius: 10, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    WelcomeProView(onContinue: {})
        .environmentObject(LanguageManager.shared)
}
