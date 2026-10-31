//
//  CardView.swift
//  WordRemSwiftUI
//
//  Kelime defteri satırı (raf): küçük defter kapağı (bayrak etiketli), serif defter adı, kelime sayısı.
//

import SwiftUI

struct CardView: View {
    @Binding var isEditing: Bool
    var title: String
    var image: String
    var wordCount: Int = 0
    var onDelete: () -> Void

    /// Defter kapağı bezleri (yeni defter oluştururken seçilir)
    static let covers: [Color] = [DS.Colors.slate, DS.Colors.accentDeep, DS.Colors.ink, DS.Colors.success,
                                  DS.Colors.gold, Color(hex: "#6B4E71")]

    /// Kapak rengi: oluştururken seçildiyse o; yoksa adından sabit seçilir (her açılışta aynı)
    static func coverColor(for title: String) -> Color {
        let key = "deckCover." + title.trimmingCharacters(in: .whitespaces)
        if let i = UserDefaults.standard.object(forKey: key) as? Int, covers.indices.contains(i) { return covers[i] }
        let sum = title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return covers[sum % 4]
    }

    static func saveCover(_ index: Int, for title: String) {
        UserDefaults.standard.set(index, forKey: "deckCover." + title.trimmingCharacters(in: .whitespaces))
    }
    private var coverColor: Color { Self.coverColor(for: title) }

    var body: some View {
        HStack(spacing: 16) {
            cover

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DS.Font.display(20))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(1)
                Text(wordCount == 0 ? AL.s(.deckNoWords) : (wordCount == 1 ? AL.s(.deckOneWord) : AL.f(.deckWordCount, wordCount)))
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
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    /// Küçük defter kapağı: bez renk, solda sırt çizgisi, ortada kâğıt etiket; bayrak etikete yapışık
    private var cover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(coverColor)
            // Sırt
            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)
            // Etiket
            VStack(spacing: 3) {
                if !image.isEmpty, UIImage(named: image) != nil {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 14, height: 14)
                        .clipShape(Circle())
                } else {
                    Rectangle().fill(DS.Colors.rule).frame(width: 14, height: 1)
                }
                Rectangle().fill(DS.Colors.rule).frame(width: 18, height: 1)
            }
            .frame(width: 26, height: 24)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 1.5))
            .offset(x: 2)
        }
        .frame(width: 40, height: 52)
        .shadow(color: Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.12), radius: 2, x: 1, y: 2)
        .accessibilityHidden(true)
    }
}
