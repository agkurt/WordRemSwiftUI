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
    /// Öğretmenin gösterdiği kart, sesi bitince ekrana gelir (Pingo gibi)
    @State private var pendingPhrase: (text: String, translation: String)?
    @Namespace private var logoNS
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
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: isConnecting)
        .onChange(of: session.phase) { phase in
            if case .failed(let code) = phase, code == "paywall" { showPaywall = true }
            if phase == .listening { revealPendingPhrase() }
        }
        // Kullanıcı konuştuktan sonra öğretmen cevap vermeye başlayınca kart kalkar
        .onChange(of: session.responseCount) { _ in
            pendingPhrase = nil
            if phrase != nil { withAnimation(.easeOut(duration: 0.25)) { phrase = nil } }
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
                                  pendingPhrase = (text, tr)
                                  if session.phase == .listening { revealPendingPhrase() }
                              },
                              onFinish: { success in
                                  finishedSuccess = success
                                  onFinished(success)
                              })
        }
        await session.start(instructions: TutorBrain.instructions(for: mode), tools: TutorBrain.tools)
    }

    private var isConnecting: Bool { session.phase == .connecting || session.phase == .idle }

    private func revealPendingPhrase() {
        guard let p = pendingPhrase else { return }
        pendingPhrase = nil
        showTranslation = false
        withAnimation(.easeOut(duration: 0.3)) { phrase = p }
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
            if !isConnecting {
                VoiceLogoView(phase: session.phase, level: session.inputLevel)
                    .matchedGeometryEffect(id: "logo", in: logoNS)
            }
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
                // Bağlanırken logo ortada büyük; bağlanınca üste küçülerek yerleşir
                VoiceLogoView(phase: .connecting, level: 0)
                    .scaleEffect(2.4)
                    .matchedGeometryEffect(id: "logo", in: logoNS)
                    .frame(height: 120)
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
                    // En fazla ~6 satır; uzayınca eski satırlar yukarı kayıp soluklaşır
                    let long = session.caption.count > 170
                    captionText
                        .font(DS.Font.ui(22, weight: .medium))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxHeight: 190, alignment: .bottom)
                        .clipped()
                        .mask(LinearGradient(stops: [.init(color: long ? .clear : .black, location: 0),
                                                     .init(color: .black, location: long ? 0.28 : 0)],
                                             startPoint: .top, endPoint: .bottom))
                        .animation(.easeOut(duration: 0.2), value: session.caption)
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
        return Text(shown.isEmpty && next.isEmpty ? " " : shown).foregroundColor(DS.Colors.ink)
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
                .font(DS.Font.ui(32, weight: .semibold))
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
