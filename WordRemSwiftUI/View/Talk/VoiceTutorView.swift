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
                                  session.setPushToTalk(true)
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
                    Text(session.caption.isEmpty ? " " : lastLines(session.caption))
                        .font(DS.Font.display(30, weight: .medium))
                        .foregroundStyle(DS.Colors.ink)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .mask(LinearGradient(colors: [.black.opacity(0.35), .black, .black],
                                             startPoint: .top, endPoint: .bottom))
                        .animation(.linear(duration: 0.05), value: session.caption)
                }
            }
        }
    }

    /// Uzun konuşmalarda ekranda son ~220 karakter kalsın (kelime sınırından)
    private func lastLines(_ text: String) -> String {
        guard text.count > 220 else { return text }
        let tail = text.suffix(220)
        if let sp = tail.firstIndex(of: " ") { return String(tail[tail.index(after: sp)...]) }
        return String(tail)
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
                Button {
                    phrase = nil
                    session.setPushToTalk(false)
                } label: {
                    Image(systemName: "arrow.uturn.backward").font(.system(size: 22, weight: .medium))
                }
                .accessibilityLabel(AL.s(.talkBackToChat))
            }
            .foregroundStyle(DS.Colors.accent)
        }
    }

    // MARK: - Bottom
    private var bottomArea: some View {
        VStack(spacing: 10) {
            if phrase != nil {
                holdToTalk
            } else {
                Text(statusText)
                    .font(DS.Font.ui(15, weight: .medium))
                    .foregroundStyle(DS.Colors.accent)
                    .frame(height: 22)
                if session.allowedSeconds > 0, session.phase != .ended {
                    Text(timeLeftText)
                        .font(DS.Font.ui(12))
                        .foregroundStyle(DS.Colors.muted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 22)
        .padding(.bottom, 26)
        .background(
            (session.phase == .userSpeaking || session.isHoldingToTalk ? DS.Colors.accent.opacity(0.10) : DS.Colors.paperSunken)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 40, topTrailingRadius: 40))
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.easeOut(duration: 0.2), value: session.phase)
    }

    private var holdToTalk: some View {
        Text(session.isHoldingToTalk ? AL.s(.talkReleaseToSend) : AL.s(.talkHoldToTalk))
            .font(DS.Font.ui(16, weight: .semibold))
            .foregroundStyle(DS.Colors.paper)
            .frame(maxWidth: 420, minHeight: 58)
            .background(session.isHoldingToTalk ? DS.Colors.accent : DS.Colors.ink, in: Capsule())
            .scaleEffect(session.isHoldingToTalk ? 1.04 : 1)
            .padding(.horizontal, 24)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !session.isHoldingToTalk { session.beginHold() } }
                    .onEnded { _ in session.endHold() }
            )
            .accessibilityAddTraits(.isButton)
            .animation(.spring(response: 0.25), value: session.isHoldingToTalk)
    }

    private var statusText: String {
        switch session.phase {
        case .listening:    return AL.s(.talkListening)
        case .userSpeaking: return AL.s(.talkHearing)
        case .thinking:     return "…"
        default:            return " "
        }
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
