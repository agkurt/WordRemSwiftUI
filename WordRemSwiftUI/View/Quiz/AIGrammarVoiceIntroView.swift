//
//  AIGrammarVoiceIntroView.swift
//  WordRemSwiftUI
//
//  Beyaz arka plan. 4 renkli dot (yükleme/konuşma animasyonu).
//  AI soru sorunca üstte practice kart açılır.
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

    private let dotColors: [Color] = [
        Color(hex: "#3B5BDB"),
        Color(hex: "#FF6B6B"),
        Color(hex: "#FFD43B"),
        Color(hex: "#3B5BDB")
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                // Practice kart — AI soru sorduğunda üstte belirir
                if let phrase = practicePhrase, phase == .idle || phase == .listening {
                    practiceCard(phrase: phrase)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.bottom, 12)
                }

                dotsSection

                Spacer(minLength: 20)

                textArea

                Spacer()

                bottomControls
            }
        }
        .animation(.spring(response: 0.4), value: phase)
        .animation(.spring(response: 0.45), value: practicePhrase)
        .task { await startIntro() }
        .onDisappear { cleanup() }
        .sheet(isPresented: $showTranscript) {
            TranscriptSheet(history: history)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(onContinue: { showPaywall = false })
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
        HStack {
            Button { cleanup(); onProceed(topic) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#f1f5f9"), in: Circle())
            }

            Spacer()

            Text(topic.rawValue)
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundStyle(Color(hex: "#1e293b"))

            Spacer()

            Button { showTranscript = true } label: {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#f1f5f9"), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Practice Card

    private func practiceCard(phrase: String) -> some View {
        VStack(spacing: 10) {
            Text(phrase)
                .font(.custom("Poppins-Bold", size: 30))
                .foregroundStyle(Color(hex: "#1e293b"))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(3)

            Button {
                TTSManager.shared.speak(phrase, langCode: targetLangCode)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#94a3b8"))
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 18, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "#e2e8f0"), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - 4 Colored Dots

    private var dotsSection: some View {
        HStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 22)
                    .fill(dotColors[i])
                    .frame(width: 56, height: 72)
                    .scaleEffect(y: dotBounce[i], anchor: .bottom)
                    .shadow(color: dotColors[i].opacity(0.25), radius: 6, y: 3)
            }
        }
    }

    // MARK: - Text Area

    private var textArea: some View {
        VStack(spacing: 10) {
            Group {
                if phase == .generating {
                    Text("Konu anlatımı hazırlanıyor...")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                } else if phase == .processing {
                    HStack(spacing: 7) {
                        ForEach(0..<3, id: \.self) { i in
                            ThinkingDot(delay: Double(i) * 0.18)
                        }
                    }
                } else if !displayedText.isEmpty {
                    Text(displayedText + (phase == .speaking ? "▋" : ""))
                        .font(.custom("Poppins-Regular", size: 17))
                        .foregroundStyle(Color(hex: "#1e293b"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .animation(nil, value: displayedText)
                        .padding(.horizontal, 28)
                }
            }
            .frame(minHeight: 72)

            // Alt ipucu
            switch phase {
            case .speaking:
                Text("Kesmek için dokunun")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(Color(hex: "#cbd5e1"))
            case .idle:
                Text("Konuşmak için basılı tutun")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(Color(hex: "#94a3b8"))
            case .listening:
                Text(srm.recognizedText.isEmpty ? "Seni dinliyorum..." : srm.recognizedText)
                    .font(.custom("Poppins-Italic", size: 13))
                    .foregroundStyle(Color(hex: "#94a3b8"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            default:
                Color.clear.frame(height: 18)
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            if phase == .idle || phase == .listening {
                // Basılı tut-bırak mikrofon
                ZStack {
                    // Pulse halkaları (idle'da)
                    if phase == .idle {
                        Circle()
                            .stroke(Color.black.opacity(0.12), lineWidth: 2.5)
                            .frame(width: micPulse ? 112 : 80, height: micPulse ? 112 : 80)
                            .opacity(micPulse ? 0 : 1)
                            .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: micPulse)

                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 2)
                            .frame(width: micPulse ? 140 : 80, height: micPulse ? 140 : 80)
                            .opacity(micPulse ? 0 : 1)
                            .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false).delay(0.3), value: micPulse)
                    }

                    // Mikrofon butonu — siyah daire
                    Circle()
                        .fill(phase == .listening ? Color(hex: "#ef4444") : Color.black)
                        .frame(width: 80, height: 80)
                        .scaleEffect(micIsPressed ? 0.92 : 1.0)
                        .shadow(
                            color: (phase == .listening ? Color(hex: "#ef4444") : Color.black).opacity(0.25),
                            radius: 16, y: 6
                        )
                        .overlay(
                            Image(systemName: phase == .listening ? "stop.fill" : "mic.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                        .animation(.spring(response: 0.25), value: micIsPressed)
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
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Button { cleanup(); onProceed(topic) } label: {
                HStack(spacing: 8) {
                    Text("Quize Başla")
                        .font(.custom("Poppins-SemiBold", size: 16))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color(hex: "#3B5BDB"), in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color(hex: "#3B5BDB").opacity(0.32), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 44)
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
            displayedText = "Konu anlatımı yüklenemedi. Quize geçmek için aşağıdaki butonu kullanabilirsin."
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
            let fallback = "Seni duyamadım, tekrar dener misin?"
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

// MARK: - Thinking Dot

private struct ThinkingDot: View {
    let delay: Double
    @State private var on = false

    var body: some View {
        Circle()
            .fill(Color(hex: "#94a3b8"))
            .frame(width: 9, height: 9)
            .scaleEffect(on ? 1.0 : 0.5)
            .opacity(on ? 1.0 : 0.35)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true).delay(delay)) {
                    on = true
                }
            }
    }
}

// MARK: - Transcript Sheet

private struct TranscriptSheet: View {
    let history: [(role: String, content: String)]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(history.enumerated()), id: \.0) { idx, item in
                            HStack(alignment: .top, spacing: 10) {
                                Text(item.role == "user" ? "👤" : "🤖")
                                    .font(.system(size: 20))
                                Text(item.content)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundStyle(Color(hex: "#1e293b"))
                                    .lineSpacing(4)
                            }
                            .padding(.horizontal, 20)
                            .id(idx)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .onAppear {
                    if let last = history.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            .background(Color.white)
            .navigationTitle("Konuşma Geçmişi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.custom("Poppins-SemiBold", size: 14))
                }
            }
        }
    }
}
