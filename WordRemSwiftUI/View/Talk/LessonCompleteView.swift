//
//  LessonCompleteView.swift
//  WordRemSwiftUI
//
//  Sesli ders bitince (Pingo gibi): "İstatistiklerin toparlanıyor" → kutlama → özet
//  (ifade sayısı, ustalık, süre, öğrenilen ifadeler sesli) → Devam → ana sayfa (sıradaki ders).
//

import SwiftUI

struct LessonCompleteView: View {
    struct Phrase: Identifiable {
        let id = UUID()
        let text: String
        let translation: String?
    }

    let lessonTitle: String
    let learnerName: String
    let phrases: [Phrase]
    let mastery: Int          // yüzde
    let duration: TimeInterval
    var onContinue: () -> Void

    private enum Stage { case gathering, celebrate, summary }
    @State private var stage: Stage = .gathering
    @State private var burst = false

    private var targetCode: String { UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN" }

    var body: some View {
        ZStack {
            switch stage {
            case .gathering: gathering.transition(.opacity)
            case .celebrate: celebrate.transition(.opacity)
            case .summary:   summary.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: stage)
        .task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            stage = .celebrate
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { burst = true }
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if stage == .celebrate { stage = .summary }
        }
    }

    // MARK: 1. Toparlanıyor
    private var gathering: some View {
        VStack(spacing: 0) {
            Spacer()
            VoiceLogoView(phase: .thinking, level: 0).scaleEffect(2.2).frame(height: 100)
            Spacer()
            Text(AL.s(.lcGathering))
                .font(DS.Font.ui(24, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .padding(.bottom, 90)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
    }

    // MARK: 2. Kutlama
    private var celebrate: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                // Logonun renk çubukları dışa doğru açılır
                ForEach(0..<8, id: \.self) { i in
                    Capsule()
                        .fill([DS.Colors.paper, DS.Colors.ink, DS.Colors.slate, DS.Colors.paper.opacity(0.55)][i % 4])
                        .frame(width: 22, height: 46)
                        .offset(y: burst ? -58 : 0)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .opacity(burst ? 1 : 0)
                }
            }
            .frame(height: 170)
            Text(AL.f(.lcCongrats, learnerName))
                .font(DS.Font.ui(18, weight: .medium))
                .foregroundStyle(DS.Colors.paper.opacity(0.75))
                .padding(.top, 36)
            Text(AL.f(.lcCompletedBang, lessonTitle))
                .font(DS.Font.display(34, weight: .bold))
                .foregroundStyle(DS.Colors.paper)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .padding(.top, 10)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colors.accent.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { stage = .summary }
    }

    // MARK: 3. Özet
    private var summary: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text(AL.f(.lcCompleted, lessonTitle))
                        .font(DS.Font.ui(16))
                        .foregroundStyle(DS.Colors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 36)
                    Text(AL.s(.lcGreatJob))
                        .font(DS.Font.display(34, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    HStack(spacing: 12) {
                        statTile("\(phrases.count)", AL.s(.lcPhrases), "checkmark.circle")
                        statTile("\(mastery)%", AL.s(.lcMastery), "target")
                        statTile(durationText, AL.s(.lcTime), "clock")
                    }
                    .padding(.top, 30)

                    if !phrases.isEmpty {
                        Text(AL.f(.lcNewPhrases, phrases.count))
                            .font(DS.Font.ui(16, weight: .semibold))
                            .foregroundStyle(DS.Colors.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 34)
                            .padding(.bottom, 12)
                        VStack(spacing: 10) {
                            ForEach(phrases) { phraseRow($0) }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .paperBackground()
        .overlay(alignment: .bottom) {
            Button(AL.s(.talkContinueNext), action: onContinue)
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                .frame(maxWidth: 560)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }

    private func statTile(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(DS.Font.ui(24, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
                .minimumScaleFactor(0.7)
            Label(label, systemImage: icon)
                .font(DS.Font.ui(13))
                .foregroundStyle(DS.Colors.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 20))
    }

    private func phraseRow(_ p: Phrase) -> some View {
        Button { TTSManager.shared.speak(p.text, langCode: targetCode) } label: {
            HStack(spacing: 14) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DS.Colors.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.text)
                        .font(DS.Font.ui(17, weight: .medium))
                        .foregroundStyle(DS.Colors.ink)
                    if let tr = p.translation {
                        Text(tr).font(DS.Font.ui(14)).foregroundStyle(DS.Colors.muted)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(DS.Colors.line))
        }
        .buttonStyle(.plain)
    }

    private var durationText: String {
        let s = Int(duration)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
