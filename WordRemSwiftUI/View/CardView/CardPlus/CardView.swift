//
//  CardView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct CardView: View {
    @Binding var isEditing: Bool
    var title: String
    var image: String
    var wordCount: Int = 0
    var onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Shadows.cardRadius)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Shadows.cardRadius)
                        .stroke(AppTheme.Colors.inputBorder, lineWidth: 1)
                )

            // Orange glow blob (subdued for light theme)
            Circle()
                .fill(AppTheme.Colors.primaryOrange.opacity(0.08))
                .frame(width: 140, height: 140)
                .blur(radius: 25)
                .offset(x: 60, y: -20)

            // Row content
            HStack(spacing: 16) {
                // Flag circle
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 68, height: 68)
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                }

                // Texts
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.custom("Feather-Bold", size: 17))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.Colors.primaryOrange)
                        Text(wordCount == 0 ? "No words yet" : "\(wordCount) word\(wordCount == 1 ? "" : "s")")
                            .font(.custom("Feather-Bold", size: 12))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#f97316").opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)

            // Delete badge
            if isEditing {
                Button(action: onDelete) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.9))
                            .frame(width: 26, height: 26)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .offset(x: 10, y: -10)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .shadow(color: AppTheme.Shadows.cardColor, radius: AppTheme.Shadows.cardRadius, x: 0, y: AppTheme.Shadows.cardY)
    }
}
