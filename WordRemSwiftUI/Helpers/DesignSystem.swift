//
//  DesignSystem.swift
//  WordRemSwiftUI
//
//  "Kâğıt & mürekkep" tasarım sistemi: sıcak kırık beyaz zemin, koyu mürekkep metin,
//  tek imza rengi (terracotta). Başlıklar ve kelimeler serif, arayüz metni SF Pro.
//  Gradient, parlama ve emoji yok — kahraman kelimenin kendisi.
//

import SwiftUI

enum DS {

    // MARK: - Colors
    enum Colors {
        static let paper       = Color(hex: "#F6F2EA")   // ana zemin
        static let paperRaised = Color(hex: "#FFFDF8")   // kart zemini
        static let paperSunken = Color(hex: "#EFE9DE")   // ikincil alanlar, inputlar
        static let line        = Color(hex: "#E4DDD0")   // ayraç, kart kenarı

        static let ink         = Color(hex: "#1C1A17")   // ana metin
        static let inkSoft     = Color(hex: "#4A453E")   // ikincil metin
        static let muted       = Color(hex: "#8A8277")   // açıklama, pasif

        static let accent      = Color(hex: "#C2512F")   // terracotta — imza rengi
        static let accentDeep  = Color(hex: "#9E3F22")
        static let accentSoft  = Color(hex: "#F3E2D8")

        static let slate       = Color(hex: "#2F4B5C")   // ikincil vurgu (Pro, bilgi)

        static let success     = Color(hex: "#3F7D58")
        static let successSoft = Color(hex: "#E3EEE6")
        static let danger      = Color(hex: "#B4423A")
        static let dangerSoft  = Color(hex: "#F4E1DE")
        static let gold        = Color(hex: "#C8962E")   // seri / ödül
    }

    // MARK: - Typography
    enum Font {
        /// Kelimeler ve büyük başlıklar — New York (sistem serif)
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        /// Arayüz metni — SF Pro
        static func ui(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight)
        }
        /// Küçük büyük harfli etiketler ("BUGÜN", "İSPANYOLCA")
        static let eyebrow = SwiftUI.Font.system(size: 11, weight: .bold)
    }

    // MARK: - Metrics
    enum Radius {
        static let card: CGFloat   = 18
        static let button: CGFloat = 14
    }
}

// MARK: - Components

/// Küçük harf aralıklı üst etiket
struct Eyebrow: View {
    let text: String
    var color: Color = DS.Colors.accent
    var body: some View {
        Text(text.uppercased())
            .font(DS.Font.eyebrow)
            .tracking(1.4)
            .foregroundStyle(color)
    }
}

/// Düz, gölgesiz kart: kâğıt üstünde ince çizgili yüzey
struct PaperCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.line, lineWidth: 1))
    }
}

/// Ana eylem butonu: düz mürekkep ya da imza rengi, gölge yok
struct InkButtonStyle: ButtonStyle {
    var fill: Color = DS.Colors.ink
    var foreground: Color = DS.Colors.paperRaised
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.ui(17, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(fill, in: RoundedRectangle(cornerRadius: DS.Radius.button))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// İkincil buton: çizgili, şeffaf
struct OutlineButtonStyle: ButtonStyle {
    var tint: Color = DS.Colors.ink
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.ui(17, weight: .semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .stroke(DS.Colors.line, lineWidth: 1.5)
                    .background(DS.Colors.paperRaised.opacity(configuration.isPressed ? 1 : 0),
                                in: RoundedRectangle(cornerRadius: DS.Radius.button))
            )
    }
}

extension View {
    /// Ekran zemini
    func paperBackground() -> some View {
        background(DS.Colors.paper.ignoresSafeArea())
    }
}
