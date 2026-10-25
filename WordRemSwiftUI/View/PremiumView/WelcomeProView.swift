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

    private let proColor     = Color(hex: "#2F4B5C")
    private let proColorDark = Color(hex: "#243B48")

    private var features: [(String, String)] {[
        ("infinity",     langManager.s(.welcomeProFeature1)),
        ("lightbulb",    langManager.s(.welcomeProFeature2)),
        ("cpu",          langManager.s(.welcomeProFeature3)),
    ]}

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [proColor.opacity(0.18), Color(hex: "#F6F2EA")],
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
                    .font(.system(size: 26, weight: .semibold, design: .serif))
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#6B645A"))
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
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#1C1A17"))
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
                        .font(.system(size: 17, weight: .semibold))
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
