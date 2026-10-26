//
//  Effects.swift
//  WordRemSwiftUI
//
//  Uygulamaya gömülü canlı efektler (ek paket yok): konfeti, titreşim, yanlışta sallanma,
//  doğruda parlama. Renkler uygulamanın paletinden + birkaç neşeli vurgu.
//

import SwiftUI
import UIKit

// MARK: - Titreşim
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func tap() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
}

// MARK: - Konfeti
/// Bir kez patlayan konfeti. `trigger` değişince yeniden patlar.
struct ConfettiBurst: View {
    enum Origin { case center, top }
    var origin: Origin = .center
    var count = 90
    var trigger: Int = 0

    static let colors: [Color] = [
        DS.Colors.accent, DS.Colors.slate, DS.Colors.ink,
        Color(red: 0.96, green: 0.73, blue: 0.24),   // altın
        Color(red: 0.29, green: 0.62, blue: 0.52),   // yeşil
        Color(red: 0.93, green: 0.55, blue: 0.47),   // şeftali
    ]

    @State private var start = Date.distantPast
    private let lifetime = 2.8

    var body: some View {
        TimelineView(.animation(paused: Date().timeIntervalSince(start) > lifetime)) { ctx in
            Canvas { gc, size in
                let t = ctx.date.timeIntervalSince(start)
                guard t >= 0, t < lifetime else { return }
                let fade = t > lifetime - 0.6 ? (lifetime - t) / 0.6 : 1
                for i in 0..<count {
                    var r = SplitMix(seed: UInt64(i &* 7919 &+ trigger &* 104_729))
                    let angle = origin == .center ? r.next(in: 0...(2 * .pi)) : r.next(in: (.pi * 0.15)...(.pi * 0.85))
                    let speed = r.next(in: 260...620)
                    let x0 = origin == .center ? size.width / 2 : r.next(in: 0...size.width)
                    let y0 = origin == .center ? size.height * 0.42 : -20
                    let vx = cos(angle) * speed * (origin == .center ? 1 : 0.35)
                    let vy = origin == .center ? -abs(sin(angle)) * speed - 120 : sin(angle) * speed * 0.4
                    let x = x0 + vx * t + sin(t * r.next(in: 2...6)) * 14
                    let y = y0 + vy * t + 0.5 * 900 * t * t
                    guard y < size.height + 30 else { continue }
                    let spin = Angle(radians: t * r.next(in: -9...9))
                    let w = r.next(in: 6...11), h = r.next(in: 9...16)
                    var piece = gc
                    piece.opacity = fade
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: spin)
                    let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                    let shape = Int(r.next(in: 0...2.99))
                    let path = shape == 0 ? Path(ellipseIn: rect.insetBy(dx: 0, dy: (h - w) / 2))
                             : shape == 1 ? Path(roundedRect: rect, cornerRadius: 2)
                             : Path(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w * 0.55, height: h), cornerRadius: w)
                    piece.fill(path, with: .color(Self.colors[i % Self.colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { start = Date() }
        .onChange(of: trigger) { _ in start = Date() }
    }
}

/// Tekrarlanabilir rastgele sayı (her parçanın yolu sabit kalsın diye)
private struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Double(z ^ (z >> 31)) / Double(UInt64.max)
    }
    mutating func next(in range: ClosedRange<Double>) -> Double { range.lowerBound + next() * (range.upperBound - range.lowerBound) }
}

// MARK: - Yanlışta sallanma
struct Shake: GeometryEffect {
    var amount: CGFloat = 9
    var shakes: CGFloat = 3
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakes * 2), y: 0))
    }
}

// MARK: - Doğruda parlama
/// `isOn` true olunca kenarda yeşil bir ışık + hafif büyüme
struct SuccessGlow: ViewModifier {
    var isOn: Bool
    var cornerRadius: CGFloat = 24
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DS.Colors.success, lineWidth: isOn ? 3 : 0)
                    .shadow(color: DS.Colors.success.opacity(isOn ? 0.55 : 0), radius: 14)
            )
            .scaleEffect(isOn ? 1.03 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isOn)
    }
}

extension View {
    func successGlow(_ isOn: Bool, cornerRadius: CGFloat = 24) -> some View {
        modifier(SuccessGlow(isOn: isOn, cornerRadius: cornerRadius))
    }
    func shake(_ trigger: Int) -> some View {
        modifier(Shake(animatableData: CGFloat(trigger)))
    }
}

// MARK: - Canlı alev (seri)
struct LiveFlame: View {
    var size: CGFloat = 16
    @State private var flicker = false
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(LinearGradient(colors: [Color(red: 0.98, green: 0.78, blue: 0.25), DS.Colors.accent],
                                            startPoint: .top, endPoint: .bottom))
            .scaleEffect(x: flicker ? 0.94 : 1.04, y: flicker ? 1.08 : 0.97, anchor: .bottom)
            .rotationEffect(.degrees(flicker ? -4 : 3), anchor: .bottom)
            .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: flicker)
            .onAppear { flicker = true }
    }
}
