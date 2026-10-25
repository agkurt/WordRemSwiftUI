//
//  CardView.swift
//  WordRemSwiftUI
//
//  Deste listesi satırı: bayrak, serif deste adı, kelime sayısı, chevron.
//

import SwiftUI

struct CardView: View {
    @Binding var isEditing: Bool
    var title: String
    var image: String
    var wordCount: Int = 0
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if !image.isEmpty, UIImage(named: image) != nil {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DS.Font.display(20))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(1)
                Text(wordCount == 0 ? "No words yet" : "\(wordCount) word\(wordCount == 1 ? "" : "s")")
                    .font(DS.Font.ui(14))
                    .foregroundStyle(DS.Colors.muted)
            }

            Spacer(minLength: 8)

            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(DS.Colors.danger)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.muted)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
