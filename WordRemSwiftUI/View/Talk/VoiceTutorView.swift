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
    /// "Devam et" ile sıradaki derse geçince değişir
    @State private var nextMode: TutorMode?
    @State private var showSummary = false
    @State private var cardCorrect = false
    @State private var cardShakes = 0
    private var activeMode: TutorMode { nextMode ?? mode }
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
                if let phrase {
                    phraseCard(phrase)
                        .shake(cardShakes)
                        .transition(.asymmetric(insertion: .scale(scale: 0.82).combined(with: .opacity),
                                                removal: .opacity.combined(with: .move(edge: .top))))
                }
                else { captionView.transition(.opacity) }
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 28)
            .animation(.spring(response: 0.42, dampingFraction: 0.68), value: phrase?.text)
            .contentShape(Rectangle())
            .onTapGesture { if phrase == nil { session.interrupt() } }
            Spacer(minLength: 0)
            bottomArea
        }
        .paperBackground()
        .task { await begin() }
        .onDisappear { saveAndStop() }
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: isConnecting)
        .onChange(of: session.phase) { phase in
            if case .failed(let code) = phase, code == "paywall" { showPaywall = true }
            guard phase == .listening else { return }
            // Hedefler bitti ve öğretmen kapanışı yaptı → ders tamamlandı
            if session.lessonComplete || finishedSuccess == true { completeLesson(); return }
            revealPendingPhrase()
        }
        // Kullanıcı konuştuktan sonra öğretmen cevap vermeye başlayınca kart kalkar
        // Cevaba anında tepki: doğruysa ✓ ve titreşim, değilse kart sallanır
        .onChange(of: session.answerCount) { _ in
            guard phrase != nil else { return }
            if session.lastAnswerCorrect {
                Haptics.success()
                cardCorrect = true
            } else {
                Haptics.warning()
                withAnimation(.linear(duration: 0.45)) { cardShakes += 1 }
            }
        }
        .onChange(of: session.responseCount) { _ in
            // Tepki görünsün diye kart biraz sonra kalkar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if phrase != nil { withAnimation(.easeOut(duration: 0.25)) { phrase = nil } }
                cardCorrect = false
            }
        }
        .sheet(isPresented: $showTranscript) { transcriptSheet }
        .fullScreenCover(isPresented: $showSummary) { lessonSummary }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: { dismiss() }) {
            OnboardingPaywallView(onContinue: { showPaywall = false })
        }
    }

    private func begin() async {
        session.onToolCall = { name, args in
            TutorBrain.handle(tool: name, args: args, mode: activeMode,
                              onPhrase: { text, tr in
                                  pendingPhrase = (text, tr)
                                  if session.phase == .listening { revealPendingPhrase() }
                              },
                              onFinish: { success in
                                  finishedSuccess = success
                                  onFinished(success)
                              })
        }
        await session.start(instructions: TutorBrain.instructions(for: activeMode), tools: TutorBrain.tools,
                            targets: TutorBrain.targets(for: activeMode), startStep: TutorBrain.savedStep(for: activeMode))
    }

    private func completeLesson() {
        if finishedSuccess != true {
            _ = TutorBrain.handle(tool: "finish_lesson", args: ["success": true, "summary": ""], mode: activeMode,
                                  onPhrase: { _, _ in },
                                  onFinish: { success in
                                      finishedSuccess = success
                                      onFinished(success)
                                  })
        }
        phrase = nil
        session.stop()
        showSummary = true
    }

    /// Ders özeti: kartlarda öğretilen ifadeler, ustalık, süre
    private var lessonSummary: LessonCompleteView {
        var seen = Set<String>()
        let phrases = session.turns.filter { $0.role == .card && seen.insert($0.text.lowercased()).inserted }
            .map { LessonCompleteView.Phrase(text: $0.text, translation: $0.detail) }
        let mastery = session.totalAnswers > 0 ? Int((Double(session.correctAnswers) / Double(session.totalAnswers) * 100).rounded()) : 100
        var title = ""
        if case .goal(let c, let g) = activeMode {
            title = ScenarioStore.shared.chapters.first { $0.id == c }?.goals.first { $0.id == g }?.localizedTitle ?? ""
        }
        return LessonCompleteView(lessonTitle: title, learnerName: UserStore.shared.snapshot.username,
                                  phrases: phrases, mastery: mastery,
                                  duration: Date().timeIntervalSince(session.startedAt)) {
            showSummary = false
            dismiss()      // ana sayfa sıradaki dersi gösterir
        }
    }

    /// Ders yarım kaldıysa son konuşmaları sakla (bir dahaki sefere oradan devam)
    private func saveAndStop() {
        if finishedSuccess != true { TutorBrain.saveProgress(for: activeMode, turns: session.turns, step: session.targetProgress) }
        session.stop()
    }

    private var isConnecting: Bool { session.phase == .connecting || session.phase == .idle }

    private func revealPendingPhrase() {
        guard let p = pendingPhrase else { return }
        pendingPhrase = nil
        showTranslation = false
        session.appendCard(p.text, translation: p.translation)
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
            Button { saveAndStop(); dismiss() } label: {
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
                    completionView(done)
                } else {
                    // En fazla ~6 satır; uzayınca eski satırlar yukarı kayıp soluklaşır
                    let long = session.caption.count > 170
                    Text(session.caption.isEmpty ? " " : session.caption)
                        .foregroundStyle(DS.Colors.ink)
                        .font(DS.Font.ui(22, weight: .medium))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxHeight: 190, alignment: .bottom)
                        .clipped()
                        .mask(LinearGradient(stops: [.init(color: long ? .clear : .black, location: 0),
                                                     .init(color: .black, location: long ? 0.28 : 0)],
                                             startPoint: .top, endPoint: .bottom))

                }
            }
        }
    }

    /// Ders bitti: kutla ve sıradaki derse geçir
    private func completionView(_ done: Bool) -> some View {
        VStack(spacing: 14) {
            Image(systemName: done ? "checkmark.seal.fill" : "hand.thumbsup.fill")
                .font(.system(size: 48)).foregroundStyle(DS.Colors.accent)
            Text(done ? AL.s(.talkLessonComplete) : AL.s(.talkSessionEnded))
                .font(DS.Font.display(30, weight: .bold)).foregroundStyle(DS.Colors.ink)
            if done, let next = ScenarioStore.shared.next {
                VStack(spacing: 6) {
                    Text(AL.s(.talkNextUp))
                        .font(DS.Font.ui(11, weight: .bold)).tracking(1.2)
                        .foregroundStyle(DS.Colors.muted)
                    Text(next.goal.localizedTitle)
                        .font(DS.Font.ui(20, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 18)
                Button(AL.s(.talkContinueNext)) { startNext(next.chapter.id, next.goal.id) }
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                    .frame(maxWidth: 280)
                    .padding(.top, 6)
            }
        }
    }

    private func startNext(_ chapterId: String, _ goalId: String) {
        nextMode = .goal(chapterId: chapterId, goalId: goalId)
        finishedSuccess = nil
        phrase = nil
        pendingPhrase = nil
        Task { await begin() }
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
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(DS.Colors.success)
                .scaleEffect(cardCorrect ? 1 : 0.2)
                .opacity(cardCorrect ? 1 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: cardCorrect)
                .frame(height: 44)
            Text(p.text)
                .font(DS.Font.ui(32, weight: .semibold))
                .foregroundStyle(cardCorrect ? DS.Colors.success : DS.Colors.ink)
                .animation(.easeOut(duration: 0.2), value: cardCorrect)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if showTranslation {
                Text(p.translation)
                    .font(DS.Font.ui(19))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 36) {
                if !p.translation.isEmpty {
                    Button { withAnimation { showTranslation.toggle() } } label: {
                        Image(systemName: "character.bubble").font(.system(size: 24, weight: .medium))
                    }
                    .accessibilityLabel(AL.s(.talkTranslate))
                }
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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if session.turns.filter({ !$0.text.isEmpty }).isEmpty {
                            Text(AL.s(.talkTranscriptEmpty))
                                .font(DS.Font.ui(15))
                                .foregroundStyle(DS.Colors.muted)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        }
                        ForEach(session.turns.filter { !$0.text.isEmpty }) { t in
                            transcriptRow(t).id(t.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }
                .defaultScrollAnchor(.bottom)
                .onAppear { if let last = session.turns.last { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
            .paperBackground()
            .navigationTitle(AL.s(.talkTranscript))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showTranscript = false } label: { Image(systemName: "xmark") }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func transcriptRow(_ t: RealtimeVoiceSession.Turn) -> some View {
        switch t.role {
        case .ai:
            VStack(alignment: .leading, spacing: 6) {
                Label(AL.s(.talkTutorLabel), systemImage: "waveform")
                    .font(DS.Font.ui(12, weight: .semibold))
                    .foregroundStyle(DS.Colors.accent)
                Text(t.text)
                    .font(DS.Font.ui(16))
                    .foregroundStyle(DS.Colors.ink)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(DS.Colors.paperRaised, in: UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 18,
                                                                                  bottomTrailingRadius: 18, topTrailingRadius: 18))
                    .overlay(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 18,
                                                    bottomTrailingRadius: 18, topTrailingRadius: 18).stroke(DS.Colors.line))
            }
            .padding(.trailing, 48)
        case .user:
            VStack(alignment: .trailing, spacing: 6) {
                Text(AL.s(.talkYouLabel))
                    .font(DS.Font.ui(12, weight: .semibold))
                    .foregroundStyle(DS.Colors.muted)
                Text(t.text)
                    .font(DS.Font.ui(16))
                    .foregroundStyle(DS.Colors.paper)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(DS.Colors.accent, in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18,
                                                                             bottomTrailingRadius: 18, topTrailingRadius: 4))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, 48)
        case .card:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AL.s(.talkSayThis))
                        .font(DS.Font.ui(10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(DS.Colors.accent)
                    Text(t.text)
                        .font(DS.Font.ui(18, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    if let tr = t.detail {
                        Text(tr).font(DS.Font.ui(14)).foregroundStyle(DS.Colors.muted)
                    }
                }
                Spacer(minLength: 0)
                Button { TTSManager.shared.speak(t.text, langCode: targetCode) } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                        .frame(width: 38, height: 38)
                        .background(DS.Colors.accent.opacity(0.1), in: Circle())
                }
                .accessibilityLabel(AL.s(.quizTapToHear))
            }
            .padding(14)
            .background(DS.Colors.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(DS.Colors.accent.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        }
    }
}

// MARK: - Durum logosu (uygulama renkleriyle)
struct VoiceLogoView: View {
    let phase: RealtimeVoiceSession.Phase
    let level: Float

    private let colors: [Color] = [DS.Colors.ink, DS.Colors.accent, DS.Colors.slate, DS.Colors.accent.opacity(0.55)]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { ctx in
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
