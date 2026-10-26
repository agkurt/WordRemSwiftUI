//
//  AIGrammarVoiceIntroView.swift
//  WordRemSwiftUI
//
//  Kâğıt zemin, serif ders metni (okuma yüzeyi).
//  AI soru sorunca ders kartının altında practice kart açılır.
//  Mikrofon: basılı tut → konuş → bırak → gönder.
//

import SwiftUI
import AVFoundation

struct AIGrammarVoiceIntroView: View {

    let topic: AIQuizTopic
    let targetLangCode: String
    let nativeLangCode: String
    let onProceed: (AIQuizTopic) -> Void

    // MARK: - Phase

    enum Phase: Equatable {
        case generating   // API bekleniyor
        case speaking     // TTS + typewriter
        case idle         // mikrofon bekliyor
        case listening    // kullanıcı konuşuyor
        case processing   // GPT yanıt üretiyor
    }

    @State private var phase: Phase = .generating

    /// Ekranda akan metin
    @State private var displayedText: String = ""
    /// Konuşma geçmişi
    @State private var history: [(role: String, content: String)] = []

    /// Race-condition koruması
    @State private var speakGeneration: Int = 0

    /// AI'ın sormak istediği kelime/cümle (practice kart)
    @State private var practicePhrase: String? = nil

    // Premium / paywall
    @State private var userRequestCount: Int = 0
    @State private var showPaywall: Bool = false
    private let freeRequestLimit = 2

    // Dot bounce
    @State private var dotBounce: [CGFloat] = [1, 1, 1, 1]
    @State private var dotBounceTask: Task<Void, Never>? = nil

    // Mic press state
    @State private var micIsPressed: Bool = false
    @State private var micPulse: Bool = false

    // Transcript
    @State private var showTranscript = false

    @ObservedObject private var srm = SpeechRecognitionManager.shared

    private var targetLang: String { OpenAIQuizService.shared.fullLangName(for: targetLangCode) }
    private var nativeLang:  String { OpenAIQuizService.shared.fullLangName(for: nativeLangCode) }

    // MARK: - Body

    var body: some View {
        ZStack {
            DS.Colors.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            lessonCard

                            // Practice kart — AI soru sorduğunda belirir
                            if let phrase = practicePhrase, phase == .idle || phase == .listening {
                                practiceCard(phrase: phrase)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            Color.clear.frame(height: 1).id("aiLessonBottom")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    .onChange(of: displayedText) { _ in
                        if phase == .speaking {
                            proxy.scrollTo("aiLessonBottom", anchor: .bottom)
                        }
                    }
                }

                bottomControls
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .animation(.easeOut(duration: 0.25), value: phase)
        .animation(.easeOut(duration: 0.3), value: practicePhrase)
        .task { await startIntro() }
        .onDisappear { cleanup() }
        .sheet(isPresented: $showTranscript) {
            AITranscriptSheet(history: history)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(onContinue: { showPaywall = false }, entryPoint: "grammar_voice")
                .environmentObject(LanguageManager.shared)
        }
        // Konuşma sırasında tap → kes (typewriter da durur)
        .contentShape(Rectangle())
        .onTapGesture {
            if phase == .speaking {
                interruptSpeaking()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { cleanup(); onProceed(topic) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            }

            Spacer()

            VStack(spacing: 2) {
                Eyebrow(text: topic.category.rawValue, color: DS.Colors.muted)
                Text(topic.rawValue)
                    .font(DS.Font.display(17))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(1)
            }

            Spacer()

            Button { showTranscript = true } label: {
                Image(systemName: "text.bubble")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            }
            .accessibilityLabel(AL.s(.hcChatHistory))
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Lesson Card

    private var lessonCard: some View {
        PaperCard(padding: 24) {
            Group {
                if phase == .generating {
                    HStack(spacing: 10) {
                        ProgressView().tint(DS.Colors.muted)
                        Text(AL.s(.hcPreparingLesson))
                            .font(DS.Font.ui(15))
                            .foregroundStyle(DS.Colors.muted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else if phase == .processing {
                    VStack(alignment: .leading, spacing: 18) {
                        if !displayedText.isEmpty {
                            lessonText(displayedText)
                                .foregroundStyle(DS.Colors.muted)
                        }
                        ProgressView().tint(DS.Colors.muted)
                    }
                } else if !displayedText.isEmpty {
                    lessonText(displayedText + (phase == .speaking ? "▍" : ""))
                        .foregroundStyle(DS.Colors.ink)
                } else {
                    Color.clear.frame(height: 120)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func lessonText(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.display(22, weight: .regular))
            .lineSpacing(8)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .animation(nil, value: displayedText)
    }

    // MARK: - Practice Card

    private func practiceCard(phrase: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(phrase)
                .font(DS.Font.display(26))
                .foregroundStyle(DS.Colors.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                TTSManager.shared.speak(phrase, langCode: targetLangCode)
            } label: {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(DS.Colors.accent)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Status Label

    @ViewBuilder
    private var statusLabel: some View {
        switch phase {
        case .speaking:
            Text(AL.s(.hcTapToInterrupt))
                .font(DS.Font.ui(13))
                .foregroundStyle(DS.Colors.muted)
        case .idle:
            Text(AL.s(.hcHoldToSpeak))
                .font(DS.Font.ui(13))
                .foregroundStyle(DS.Colors.muted)
        case .listening:
            Text(srm.recognizedText.isEmpty ? AL.s(.hcListening) : srm.recognizedText)
                .font(DS.Font.ui(13).italic())
                .foregroundStyle(DS.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        default:
            Color.clear.frame(height: 16)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            statusLabel
                .padding(.horizontal, 24)

            if phase == .idle || phase == .listening {
                // Basılı tut-bırak mikrofon — tek mürekkep daire
                Circle()
                    .fill(DS.Colors.ink)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: phase == .listening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(DS.Colors.paperRaised)
                    )
                    .overlay(
                        Circle()
                            .stroke(DS.Colors.accent, lineWidth: 2)
                            .padding(-6)
                            .opacity(phase == .listening ? 1 : 0)
                    )
                    .scaleEffect(micIsPressed ? 0.94 : 1.0)
                    .animation(.easeOut(duration: 0.15), value: micIsPressed)
                    .padding(6)
                    .contentShape(Circle())
                    // Basılı tut-bırak
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !micIsPressed && phase == .idle {
                                    micIsPressed = true
                                    startListening()
                                }
                            }
                            .onEnded { _ in
                                if micIsPressed {
                                    micIsPressed = false
                                    if phase == .listening {
                                        stopListeningAndProcess()
                                    }
                                }
                            }
                    )
                    .accessibilityLabel(AL.s(.hcHoldToSpeak))
                    .transition(.opacity)
            }

            Button { cleanup(); onProceed(topic) } label: {
                Text(AL.s(.hcStartQuiz))
            }
            .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
            .padding(.horizontal, 24)
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(DS.Colors.paper)
        .overlay(alignment: .top) {
            Rectangle().fill(DS.Colors.line).frame(height: 1)
        }
    }

    // MARK: - Logic

    private func startIntro() async {
        phase = .generating
        startLoadingDots()   // sadece yüklenirken hafif pulse

        let intro = await OpenAIQuizService.shared.generateGrammarIntro(
            topic: topic,
            targetLang: targetLang,
            nativeLang: nativeLang
        )

        if let text = intro {
            history.append((role: "assistant", content: text))
            await speakWithTypewriter(text)
        } else {
            displayedText = AL.s(.hcLessonLoadFailed)
            phase = .idle
            stopDotBounce()
        }
    }

    private func interruptSpeaking() {
        speakGeneration += 1   // typewriter'ı durdur
        TTSManager.shared.stop()
        displayedText = history.last(where: { $0.role == "assistant" })?.content ?? displayedText
        stopDotBounce()
        withAnimation { phase = .idle }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { micPulse = true }
    }

    /// Audio fetch → .speaking → ses + harf aynı anda, birlikte biter.
    private func speakWithTypewriter(_ text: String) async {
        speakGeneration += 1
        let gen = speakGeneration

        displayedText = ""

        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .default, options: [.duckOthers, .mixWithOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        // Audio indir (phase henüz generating/processing)
        let duration = await TTSManager.shared.fetchForSync(text, langCode: nativeLangCode)

        guard speakGeneration == gen else { return }

        withAnimation(.easeInOut(duration: 0.25)) { phase = .speaking }
        startDotBounce()
        micPulse = false

        let langCode = nativeLangCode
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await TTSManager.shared.playAndAwait(text, langCode: langCode)
            }
            group.addTask { @MainActor in
                await revealChars(text, over: duration, gen: gen)
            }
        }

        guard speakGeneration == gen else { return }

        stopDotBounce()

        // Practice phrase'i extract et
        let phrase = extractPracticePhrase(from: text)
        withAnimation(.spring(response: 0.45)) {
            practicePhrase = phrase
        }

        if phase == .speaking {
            withAnimation(.spring(response: 0.4)) { phase = .idle }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { micPulse = true }
        }
    }

    @MainActor
    private func revealChars(_ text: String, over duration: TimeInterval, gen: Int) async {
        let chars = Array(text)
        guard !chars.isEmpty else { displayedText = text; return }

        let delayNs = UInt64(max(0.008, duration / Double(chars.count)) * 1_000_000_000)

        for i in 0..<chars.count {
            guard speakGeneration == gen, phase == .speaking else {
                displayedText = text
                return
            }
            displayedText = String(chars.prefix(i + 1))
            try? await Task.sleep(nanoseconds: delayNs)
        }
    }

    private func startListening() {
        guard phase == .idle else { return }
        TTSManager.shared.stop()
        phase        = .listening
        micPulse     = false
        practicePhrase = practicePhrase  // kart görünür kalsın

        SpeechRecognitionManager.shared.onAutoStop = {
            Task { @MainActor in
                self.micIsPressed = false
                await processUserInput()
            }
        }
        // "auto" → Whisper otomatik tespit eder; kullanıcı hangi dilde konuşursa konuşsun
        try? SpeechRecognitionManager.shared.startRecording(langCode: "auto")
    }

    private func stopListeningAndProcess() {
        guard phase == .listening else { return }
        SpeechRecognitionManager.shared.stopRecording()
        Task { await processUserInput() }
    }

    private func processUserInput() async {
        let deadline = Date().addingTimeInterval(10)
        while SpeechRecognitionManager.shared.isProcessing, Date() < deadline {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        let userText = SpeechRecognitionManager.shared.recognizedText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Free limit: 2 konuşma hakkı
        if !DailyLimitManager.shared.isPremium && userRequestCount >= freeRequestLimit {
            withAnimation { phase = .idle }
            showPaywall = true
            return
        }
        userRequestCount += 1

        guard !userText.isEmpty else {
            let fallback = AL.s(.hcDidntHear)
            history.append((role: "assistant", content: fallback))
            await speakWithTypewriter(fallback)
            return
        }

        history.append((role: "user", content: userText))
        withAnimation(.easeInOut(duration: 0.2)) { phase = .processing }
        stopDotBounce()

        let response = await OpenAIQuizService.shared.continueGrammarChat(
            topic: topic,
            history: history,
            userText: userText,
            targetLang: targetLang,
            nativeLang: nativeLang
        )

        if let text = response {
            history.append((role: "assistant", content: text))
            await speakWithTypewriter(text)
        } else {
            withAnimation { phase = .idle }
        }
    }

    private func cleanup() {
        dotBounceTask?.cancel()
        dotBounceTask = nil
        TTSManager.shared.stop()
        if SpeechRecognitionManager.shared.isRecording {
            SpeechRecognitionManager.shared.stopRecording()
        }
    }

    // MARK: - Practice Phrase Extractor

    /// AI yanıtından kullanıcının söylemesi gereken kelime/cümleyi çeker.
    private func extractPracticePhrase(from text: String) -> String? {
        // 1. Tırnak içi — "Hello" veya 'Hello'
        let nsText = text as NSString
        let quotePatterns = [#""([^"]{1,60})""#, #"'([^']{1,60})'"#, #"«([^»]{1,60})»"#]
        for pattern in quotePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound,
                   let swiftRange = Range(range, in: text) {
                    let candidate = String(text[swiftRange]).trimmingCharacters(in: .whitespaces)
                    if !candidate.isEmpty { return candidate }
                }
                _ = nsText  // silence warning
            }
        }

        // 2. ":" sonrası ilk cümle/kelime
        if text.contains(":") {
            let parts = text.components(separatedBy: ":")
            if let afterColon = parts.last {
                let candidate = afterColon
                    .components(separatedBy: CharacterSet(charactersIn: ".!?,\n"))
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? ""
                if candidate.count >= 2 && candidate.count <= 60 {
                    return candidate
                }
            }
        }

        return nil
    }

    // MARK: - Dot Animations

    /// Yükleme sırasında hafif, yavaş zıplama
    private func startLoadingDots() {
        dotBounceTask?.cancel()
        dotBounceTask = Task {
            while !Task.isCancelled {
                for i in 0..<4 {
                    guard !Task.isCancelled else { return }
                    let idx = i
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.5)) { dotBounce[idx] = 1.2 }
                    }
                    try? await Task.sleep(nanoseconds: 160_000_000)
                }
                for i in 0..<4 {
                    guard !Task.isCancelled else { return }
                    let idx = i
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.5)) { dotBounce[idx] = 1.0 }
                    }
                    try? await Task.sleep(nanoseconds: 160_000_000)
                }
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }

    /// Konuşma sırasında enerjik zıplama
    private func startDotBounce() {
        dotBounceTask?.cancel()
        dotBounceTask = Task {
            while !Task.isCancelled {
                for i in 0..<4 {
                    guard !Task.isCancelled else { return }
                    let idx = i
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.28)) { dotBounce[idx] = 1.4 }
                    }
                    try? await Task.sleep(nanoseconds: 95_000_000)
                }
                for i in 0..<4 {
                    guard !Task.isCancelled else { return }
                    let idx = i
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.28)) { dotBounce[idx] = 1.0 }
                    }
                    try? await Task.sleep(nanoseconds: 95_000_000)
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    private func stopDotBounce() {
        dotBounceTask?.cancel()
        dotBounceTask = nil
        withAnimation(.spring(response: 0.4)) { dotBounce = [1, 1, 1, 1] }
    }
}

// MARK: - Transcript Sheet

private struct AITranscriptSheet: View {
    let history: [(role: String, content: String)]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(history.enumerated()), id: \.0) { idx, item in
                            AITranscriptRow(isUser: item.role == "user", content: item.content)
                                .id(idx)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }
                .onAppear {
                    if let last = history.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            .paperBackground()
            .navigationTitle(AL.s(.hcChatHistory))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DS.Colors.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AL.s(.commonClose)) { dismiss() }
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                }
            }
        }
    }
}

private struct AITranscriptRow: View {
    let isUser: Bool
    let content: String

    var body: some View {
        if isUser {
            HStack {
                Spacer(minLength: 48)
                Text(content)
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.ink)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 14))
            }
        } else {
            Text(content)
                .font(DS.Font.display(17, weight: .regular))
                .foregroundStyle(DS.Colors.ink)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 24)
        }
    }
}
