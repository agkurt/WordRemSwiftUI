//
//  VoiceTutorView.swift
//  WordRemSwiftUI
//
//  Sesli öğretmen ekranı: canlı altyazı, durum logosu, ifade kartı (bas-konuş),
//  transkript çekmecesi. Süre/paywall sınırları sunucudan gelir.
//

import SwiftUI

struct VoiceTutorView: View {
    let mode: TutorMode
    var onFinished: (Bool) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = RealtimeVoiceSession()
    @State private var phrase: (text: String, translation: String)?
    @State private var showTranslation = false
    @State private var showTranscript = false
    @State private var showPaywall = false
    @State private var finishedSuccess: Bool?

    private var targetCode: String { UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN" }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 0)
            ZStack {
                if let phrase { phraseCard(phrase).transition(.opacity.combined(with: .scale(scale: 0.96))) }
                else { captionView.transition(.opacity) }
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 28)
            .animation(.easeOut(duration: 0.25), value: phrase?.text)
            .contentShape(Rectangle())
            .onTapGesture { if phrase == nil { session.interrupt() } }
            Spacer(minLength: 0)
            bottomArea
        }
        .paperBackground()
        .task { await begin() }
        .onDisappear { session.stop() }
        .onChange(of: session.phase) { phase in
            if case .failed(let code) = phase, code == "paywall" { showPaywall = true }
        }
        // Kullanıcı kartı söyledikten sonra öğretmen cevap vermeye başlayınca kart kalkar
        .onChange(of: session.responseCount) { _ in
            if phrase != nil { withAnimation { phrase = nil } }
        }
        .sheet(isPresented: $showTranscript) { transcriptSheet }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: { dismiss() }) {
            OnboardingPaywallView(onContinue: { showPaywall = false })
        }
    }

    private func begin() async {
        session.onToolCall = { name, args in
            TutorBrain.handle(tool: name, args: args, mode: mode,
                              onPhrase: { text, tr in
                                  showTranslation = false
                                  phrase = (text, tr)
                              },
                              onFinish: { success in
                                  finishedSuccess = success
                                  onFinished(success)
                              })
        }
        await session.start(instructions: TutorBrain.instructions(for: mode), tools: TutorBrain.tools)
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Button { showTranscript = true } label: {
                Image(systemName: "text.bubble")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 44, height: 44)
                    .background(DS.Colors.paperSunken, in: Circle())
            }
            .accessibilityLabel(AL.s(.talkTranscript))
            Spacer()
            VoiceLogoView(phase: session.phase, level: session.inputLevel)
            Spacer()
            Button { session.stop(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 44, height: 44)
                    .background(DS.Colors.paperSunken, in: Circle())
            }
            .accessibilityLabel(AL.s(.talkEnd))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Caption (son satırlar, eskiler soluk)
    private var captionView: some View {
        Group {
            switch session.phase {
            case .connecting, .idle:
                VStack(spacing: 14) {
                    ProgressView().tint(DS.Colors.inkSoft)
                    Text(AL.s(.talkConnecting)).font(DS.Font.ui(15)).foregroundStyle(DS.Colors.muted)
                }
            case .failed(let code):
                failureView(code)
            default:
                if let done = finishedSuccess, session.phase == .ended {
                    VStack(spacing: 12) {
                        Image(systemName: done ? "checkmark.seal.fill" : "hand.thumbsup.fill")
                            .font(.system(size: 44)).foregroundStyle(DS.Colors.accent)
                        Text(done ? AL.s(.talkLessonComplete) : AL.s(.talkSessionEnded))
                            .font(DS.Font.display(28, weight: .bold)).foregroundStyle(DS.Colors.ink)
                    }
                } else {
                    captionText
                        .font(DS.Font.ui(24, weight: .medium))
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeOut(duration: 0.15), value: session.caption)
                }
            }
        }
    }

    /// Söylenmiş kelimeler koyu, sıradaki kelime soluk (Pingo gibi). Uzun cevapta son ~240 karakter.
    private var captionText: Text {
        let shown = session.caption
        let full = session.captionFull
        let rest = full.count > shown.count ? String(full.dropFirst(shown.count)) : ""
        let next = rest.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        var visible = shown
        if visible.count > 240, let sp = visible.dropFirst(visible.count - 240).firstIndex(of: " ") {
            visible = String(visible[visible.index(after: sp)...])
        }
        return Text(visible.isEmpty && next.isEmpty ? " " : visible).foregroundColor(DS.Colors.ink)
            + Text(next).foregroundColor(DS.Colors.muted.opacity(0.45))
    }

    private func failureView(_ code: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: code == "limit_reached" ? "hourglass" : "wifi.exclamationmark")
                .font(.system(size: 36)).foregroundStyle(DS.Colors.muted)
            Text(code == "limit_reached" ? AL.s(.talkLimitReached)
                 : code == "not_configured" ? AL.s(.talkNotConfigured) : AL.s(.talkError))
                .font(DS.Font.display(22, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Colors.ink)
            if code != "limit_reached" && code != "not_configured" {
                Button(AL.s(.paywallRetry)) { Task { await begin() } }
                    .buttonStyle(OutlineButtonStyle())
                    .frame(maxWidth: 220)
            }
        }
    }

    // MARK: - Phrase card
    private func phraseCard(_ p: (text: String, translation: String)) -> some View {
        VStack(spacing: 22) {
            Text(p.text)
                .font(DS.Font.display(36, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if showTranslation {
                Text(p.translation)
                    .font(DS.Font.ui(19))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 36) {
                Button { withAnimation { showTranslation.toggle() } } label: {
                    Image(systemName: "character.bubble").font(.system(size: 24, weight: .medium))
                }
                .accessibilityLabel(AL.s(.talkTranslate))
                Button { TTSManager.shared.speak(p.text, langCode: targetCode) } label: {
                    Image(systemName: "speaker.wave.2").font(.system(size: 24, weight: .medium))
                }
                .accessibilityLabel(AL.s(.quizTapToHear))
            }
            .foregroundStyle(DS.Colors.accent)
        }
    }

    // MARK: - Bottom
    /// Sıra kullanıcıdaysa alt panelin tamamı bas-konuş alanı; öğretmen konuşurken "Transkript"
    private var canTalk: Bool {
        switch session.phase {
        case .listening, .userSpeaking: return true
        default: return false
        }
    }

    private var bottomArea: some View {
        let holding = session.isHoldingToTalk
        return VStack(spacing: 8) {
            Image(systemName: "chevron.up")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
                .opacity(canTalk ? 0 : 1)
            Text(canTalk ? (holding ? AL.s(.talkReleaseToSend) : AL.s(.talkHoldToTalk))
                 : session.phase == .thinking ? "…"
                 : session.phase == .connecting || session.phase == .idle ? AL.s(.talkConnecting)
                 : AL.s(.talkTranscript))
                .font(DS.Font.ui(17, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
            if session.allowedSeconds > 0, session.phase != .ended {
                Text(timeLeftText)
                    .font(DS.Font.ui(12))
                    .foregroundStyle(DS.Colors.muted)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.bottom, 12)
        .background(
            (holding ? DS.Colors.accent.opacity(0.18) : canTalk ? DS.Colors.accent.opacity(0.08) : DS.Colors.paperSunken)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 44, topTrailingRadius: 44))
                .ignoresSafeArea(edges: .bottom)
        )
        .scaleEffect(holding ? 1.02 : 1, anchor: .bottom)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !session.isHoldingToTalk else { return }
                    if canTalk { session.beginHold() }
                }
                .onEnded { v in
                    if session.isHoldingToTalk { session.endHold() }
                    else if !canTalk, abs(v.translation.height) < 10 { showTranscript = true }
                }
        )
        .accessibilityAddTraits(.isButton)
        .animation(.spring(response: 0.25), value: holding)
        .animation(.easeOut(duration: 0.2), value: session.phase)
    }

    private var timeLeftText: String {
        let left = max(0, session.allowedSeconds - session.elapsedSeconds)
        return AL.f(.talkMinutesLeft, Int((Double(left) / 60).rounded(.up)))
    }

    // MARK: - Transcript
    private var transcriptSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(session.turns.filter { !$0.text.isEmpty }) { t in
                        HStack {
                            if t.role == .user { Spacer(minLength: 40) }
                            Text(t.text)
                                .font(DS.Font.ui(16))
                                .foregroundStyle(DS.Colors.ink)
                                .padding(12)
                                .background(t.role == .user ? DS.Colors.accent.opacity(0.12) : DS.Colors.paperRaised,
                                            in: RoundedRectangle(cornerRadius: 16))
                            if t.role == .ai { Spacer(minLength: 40) }
                        }
                    }
                }
                .padding(20)
            }
            .paperBackground()
            .navigationTitle(AL.s(.talkTranscript))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Durum logosu (uygulama renkleriyle)
struct VoiceLogoView: View {
    let phase: RealtimeVoiceSession.Phase
    let level: Float

    private let colors: [Color] = [DS.Colors.ink, DS.Colors.accent, DS.Colors.slate, DS.Colors.accent.opacity(0.55)]

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(colors[i])
                        .frame(width: 11, height: height(i, t))
                }
            }
            .frame(height: 40)
        }
        .accessibilityHidden(true)
    }

    private func height(_ i: Int, _ t: Double) -> CGFloat {
        switch phase {
        case .aiSpeaking:
            return 14 + 22 * CGFloat(abs(sin(t * 2.4 + Double(i) * 0.9)))
        case .userSpeaking:
            return 12 + 26 * CGFloat(level) * CGFloat(0.6 + 0.4 * abs(sin(t * 3.5 + Double(i))))
        case .thinking, .connecting:
            return 11 + 6 * CGFloat(abs(sin(t * 1.5 + Double(i) * 0.6)))
        case .listening:
            return 11 + 10 * CGFloat(level)
        default:
            return 11
        }
    }
}
