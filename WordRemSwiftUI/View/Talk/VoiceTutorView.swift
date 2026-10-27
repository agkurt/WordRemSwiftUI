//
//  VoiceTutorView.swift
//  WordRemSwiftUI
//
//  Sesli öğretmen ekranı: canlı altyazı, durum logosu, ifade kartı (bas-konuş),
//  transkript çekmecesi. Süre/paywall sınırları sunucudan gelir.
//

import SwiftUI
import AVFoundation
import ReplayKit

struct VoiceTutorView: View {
    let mode: TutorMode
    var onFinished: (Bool) -> Void = { _ in }
    /// Onboarding demosu: özet ekranı yok, kapatınca/bitince doğrudan onFinished
    var isDemo = false

    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = RealtimeVoiceSession()
    #if DEBUG
    @State private var debugQueue: [String] = []
    #endif
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
    /// Yeni dil kurulumu: kartsız, özet ekranı yok; yarıda çıkarken onay sorulur
    private var isSetup: Bool { if case .languageSetup = mode { return true }; return false }
    @State private var confirmLeave = false
    @State private var showTranslation = false
    @State private var showTranscript = false
    @State private var showPaywall = false
    @State private var finishedSuccess: Bool?
    @State private var completing = false
    @State private var showHelp = false
    @State private var showTopics = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// Bu oturumda desteye kaydedilen kartlar (yer imi dolu görünür)
    @State private var savedPhrases: Set<String> = []

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
            .onTapGesture {
                if phrase == nil, session.phase == .aiSpeaking || session.phase == .thinking {
                    Track.tutor("interrupt", mode: modeName)
                    session.interrupt()
                }
            }
            Spacer(minLength: 0)
            bottomArea
        }
        .paperBackground()
        .task {
            // Ücretsiz süresi bitmiş, Pro olmayan kullanıcı: sunucuya gitmeden ödeme ekranı
            if FreeTrial.exhausted, !InAppPurchaseManager.shared.isPremium {
                await InAppPurchaseManager.shared.syncPremiumStatus()   // yeni alınmış Pro geç görünmesin
                if !InAppPurchaseManager.shared.isPremium {
                    Track.tutor("trial_exhausted_gate", mode: modeName)
                    if isDemo { onFinished(true) } else { showPaywall = true }
                    return
                }
            }
            await begin()
        }
        .onDisappear { saveAndStop() }
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: isConnecting)
        .onChange(of: session.phase) { phase in
            // Pro kullanıcıya asla paywall yok: aylık süresi bittiyse yalnızca bilgi gösterilir
            if case .failed(let code) = phase, code == "paywall", !InAppPurchaseManager.shared.isPremium {
                FreeTrial.markExhausted()
                showPaywall = true
            }
            guard phase == .listening else { return }
            // Hedefler bitti ve öğretmen kapanışı yaptı → ders tamamlandı
            if session.lessonComplete || finishedSuccess == true {
                // Son kelime hoparlörde biraz gecikmeli çalar: hemen kapatırsak veda yarıda kesilir.
                // Ses ve yazı tamamen bitsin, bir nefes sonra ekran değişsin.
                guard !completing else { return }
                completing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { completeLesson() }
                return
            }
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
        // Kurulum yarıda bırakılırsa dil değişmez
        .alert(LearningText.leaveTitle, isPresented: $confirmLeave) {
            Button(LearningText.stay, role: .cancel) {}
            Button(LearningText.leave, role: .destructive) {
                session.stop()
                onFinished(false)
                dismiss()
            }
        } message: {
            Text(LearningText.leaveMessage)
        }
        .sheet(isPresented: $showHelp) {
            StuckHelpSheet { need in
                Track.tutor(need == .slower ? "help_slower" : "help_explain", mode: modeName)
                session.requestHelp(slower: need == .slower)
            }
        }
        .sheet(isPresented: $showTopics) {
            TopicPickerSheet { display, topic in
                Track.tutor("topic_pick", mode: modeName, item: display)
                session.startTopic(display: display, topic: topic)
            }
        }
        .fullScreenCover(isPresented: $showSummary) { lessonSummary }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: DebugDriver.say)) { n in
            debugQueue.append(n.object as? String ?? "")
            flushDebugQueue()
        }
        .onReceive(NotificationCenter.default.publisher(for: DebugDriver.close)) { _ in
            saveAndStop()
            if isDemo { onFinished(false) } else { dismiss() }
        }
        .onChange(of: session.phase) { _ in
            flushDebugQueue()
            StudioDirector.shared.observe(session)
        }
        .onChange(of: session.turns.count) { _ in StudioDirector.shared.turnAdded(session) }
        #endif
        .fullScreenCover(isPresented: $showPaywall, onDismiss: { dismiss() }) {
            OnboardingPaywallView(onContinue: { showPaywall = false }, entryPoint: "lesson_limit")
        }
    }

    private func begin() async {
        session.onAnswer = { card, ok in
            TutorBrain.noteAnswer(card: card, correct: ok)
            StudyStreak.record()
            // Yanlış söylenen cümle "Telaffuz çalış" destesine kendiliğinden düşer
            if !ok, !isDemo {
                let tr = phrase?.text == card ? phrase?.translation ?? "" : ""
                saveToDeck(card, tr, .pronunciation)
            }
        }
        session.answerCardsOnly = isDemo
        session.noCards = isSetup
        session.completeAfterUserTurns = isSetup ? 3 : nil
        session.cardAfterUserTurns = isSetup ? 2 : nil
        if case .languageSetup(let code) = mode { RealtimeVoiceSession.targetOverride = code } else { RealtimeVoiceSession.targetOverride = nil }
        // Önceki sohbette başka dile geçildiyse bu konuşmaya taşınmasın
        TutorBrain.sessionLanguage = nil
        session.allowLanguageSwitch = activeMode == .freeChat
        switch activeMode {
        case .languageSetup, .levelReview, .wordPractice: session.allowModelFinish = true
        default: session.allowModelFinish = false
        }
        session.isPro = InAppPurchaseManager.shared.isPremium
        // Günlük süre doldu: AI vedalaştıktan sonra paywall (demoda onboarding'in paywall'ı)
        session.onLimitReached = {
            phrase = nil
            if !InAppPurchaseManager.shared.isPremium { FreeTrial.markExhausted() }
            if isDemo { onFinished(true) }
            else if InAppPurchaseManager.shared.isPremium { dismiss() }
            else { showPaywall = true }
        }
        session.onToolCall = { name, args in
            TutorBrain.handle(tool: name, args: args, mode: activeMode,
                              onPhrase: { text, tr in
                                  // Aynı kartın sonradan gelen çevirisi: kartı değiştirme, çeviriyi ekle
                                  if let cur = phrase, cur.text == text {
                                      if !tr.isEmpty, cur.translation.isEmpty {
                                          phrase = (text, tr)
                                          session.updateCardTranslation(text, translation: tr)
                                      }
                                      return
                                  }
                                  if let p = pendingPhrase, p.text == text, tr.isEmpty || !p.translation.isEmpty { return }
                                  pendingPhrase = (text, tr)
                                  if session.phase == .listening { revealPendingPhrase() }
                              },
                              onFinish: { success in
                                  finishedSuccess = success
                                  if !isDemo, !isSetup { onFinished(success) }
                              })
        }
        let tools = isSetup
            ? TutorBrain.tools.filter { ["show_phrase", "remember_fact", "finish_lesson"].contains($0["name"] as? String ?? "") }
            : activeMode == .freeChat ? TutorBrain.tools
            : TutorBrain.tools.filter { ($0["name"] as? String) != "switch_language" }
        session.analyticsContext = analyticsContext
        Track.screen("lesson")
        let opensWithQuestion = activeMode == .freeChat && TutorBrain.chatOpener != nil
        let instructions = TutorBrain.instructions(for: activeMode)
        TutorBrain.chatOpener = nil
        await session.start(instructions: instructions, tools: tools,
                            targets: TutorBrain.targets(for: activeMode), startStep: TutorBrain.savedStep(for: activeMode),
                            roleplay: !isDemo && !isSetup, aiSpeaksFirst: activeMode != .freeChat || opensWithQuestion,
                            quality: usesHighModel ? "high" : "standard")
    }

    private func completeLesson() {
        if isSetup {
            phrase = nil
            session.stop()
            onFinished(true)
            dismiss()
            return
        }
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
        if isDemo { onFinished(true) } else { showSummary = true }
    }

    /// Özette her ifade bir kez: kartlar cümlelere bölünür, neredeyse aynı olanlardan uzun olan kalır
    /// ("Nice to meet you." + "Nice to meet you, Emma." + "Nice to meet you too." → tek satır)
    static func distinctPhrases(_ cards: [(String, String)]) -> [(String, String)] {
        var out: [(text: String, tr: String, words: [String])] = []
        for (text, tr) in cards {
            let parts = PhraseKey.sentences(text)
            let trParts = PhraseKey.sentences(tr)
            for (i, part) in parts.enumerated() {
                let words = PhraseKey.words(part)
                guard !words.isEmpty else { continue }
                let meaning = parts.count == 1 ? tr : (trParts.count == parts.count ? trParts[i] : "")
                if let j = out.firstIndex(where: { PhraseKey.isNearDuplicate($0.words, words) }) {
                    if words.count > out[j].words.count { out[j] = (part, meaning, words) }
                } else {
                    out.append((part, meaning, words))
                }
            }
        }
        return out.map { (Self.withPeriod($0.text), $0.tr) }
    }
    private static func withPeriod(_ s: String) -> String {
        guard let last = s.last, !".!?。！？".contains(last) else { return s }
        return s + "."
    }

    /// Ders özeti: kartlarda öğretilen ifadeler, ustalık, süre
    private var lessonSummary: LessonCompleteView {
        let phrases = Self.distinctPhrases(session.turns.filter { $0.role == .card }.map { ($0.text, $0.detail ?? "") })
            .map { LessonCompleteView.Phrase(text: $0.0, translation: $0.1) }
        let mastery = session.totalAnswers > 0 ? Int((Double(session.correctAnswers) / Double(session.totalAnswers) * 100).rounded()) : 100
        var title = ""
        if case .goal(let c, let g) = activeMode {
            title = ScenarioStore.shared.chapters.first { $0.id == c }?.goals.first { $0.id == g }?.localizedTitle ?? ""
        }
        return LessonCompleteView(lessonTitle: title, learnerName: UserStore.shared.snapshot.username,
                                  phrases: phrases, mastery: mastery,
                                  duration: Date().timeIntervalSince(session.startedAt),
                                  asksForReview: true) {
            showSummary = false
            dismiss()      // ana sayfa sıradaki dersi gösterir
        }
    }

    /// Ders yarım kaldıysa son konuşmaları sakla (bir dahaki sefere oradan devam)
    private func saveAndStop() {
        if session.turns.contains(where: { $0.role == .user && !$0.text.isEmpty }) { StudyStreak.record() }
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

    #if DEBUG
    private func flushDebugQueue() {
        guard session.phase == .listening, !debugQueue.isEmpty else { return }
        session.debugLearnerSays(debugQueue.removeFirst())
    }
    #endif

    /// Analitikte dersin kimliği: mod + hangi ders
    private var analyticsContext: [String: Any?] {
        switch activeMode {
        case .goal(let c, let g): return ["mode": "goal", "lesson_id": "\(c)/\(g)"]
        case .levelReview(let id): return ["mode": "level_review", "lesson_id": id.uuidString]
        case .languageSetup(let code): return ["mode": "setup", "lesson_id": code]
        case .freeChat: return ["mode": "free_chat"]
        case .demo: return ["mode": "demo"]
        case .wordPractice: return ["mode": "word_practice"]
        default: return ["mode": "\(activeMode)"]
        }
    }
    /// Demo satışı belirler, derslerde talimat takibi önemli: tam model. Serbest sohbet ve kelime pratiği mini.
    private var usesHighModel: Bool {
        switch activeMode {
        // Yalnızca onboarding demosu (satın alma kararının verildiği ilk konuşma); dersler maliyet için standart modelde
        case .demo: return true
        default: return false
        }
    }
    private var modeName: String { (analyticsContext["mode"] as? String) ?? "other" }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            // Pingo gibi: serbest sohbette konu seç, derste "Takıldın mı?" (transkript alttaki çubukta)
            Button {
                if activeMode == .freeChat { showTopics = true } else { showHelp = true }
                Track.tutor(activeMode == .freeChat ? "topic_picker_open" : "help_open", mode: modeName)
            } label: {
                Image(systemName: activeMode == .freeChat ? "square.grid.2x2" : "questionmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 44, height: 44)
                    .background(DS.Colors.paperSunken, in: Circle())
            }
            .opacity(isConnecting || isSetup ? 0 : 1)
            .disabled(isSetup)
            Spacer()
            if !isConnecting {
                VoiceLogoView(phase: session.phase, level: session.inputLevel)
                    .matchedGeometryEffect(id: "logo", in: logoNS)
            }
            Spacer()
            Button {
                if isSetup, !completing, !session.turns.isEmpty, !isConnecting { confirmLeave = true; return }
                saveAndStop()
                if isDemo { onFinished(false) } else { dismiss() }
            } label: {
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
                    // Demoda "Hedef tamamlandı / Sıradaki" gösterilmez: doğrudan paywall gelir
                    if isDemo { Color.clear } else { completionView(done) }
                } else if showSuggestions {
                    suggestionsView
                } else {
                    // Metin ekranın tam ortasından başlar; satır eklendikçe blok yumuşakça yukarı kayar,
                    // hep ortada kalır. En fazla ~6 satır; uzayınca eski satırlar yukarıda soluklaşır.
                    let long = session.caption.count > 170
                    Text(session.caption.isEmpty ? " " : session.caption)
                        .foregroundStyle(DS.Colors.ink)
                        .font(DS.Font.ui(22, weight: .medium))
                        .lineSpacing(6)
                        .contentTransition(.identity)   // kelimeler solmadan, direkt
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxHeight: 190, alignment: .bottom)
                        .fixedSize(horizontal: false, vertical: true)   // kutu metin kadar: boşluk alttan doldurulmaz
                        .clipped()
                        .animation(.easeOut(duration: 0.22), value: session.caption)
                        .mask(LinearGradient(stops: [.init(color: long ? .clear : .black, location: 0),
                                                     .init(color: .black, location: long ? 0.28 : 0)],
                                             startPoint: .top, endPoint: .bottom))

                }
            }
        }
    }

    /// Serbest sohbet açılışı (Pingo gibi): öğrenci ne yapmak istediğini söyler ya da bir balona dokunur
    private var showSuggestions: Bool {
        activeMode == .freeChat && session.caption.isEmpty && !session.turns.contains { $0.role == .user }
    }

    private var suggestionsView: some View {
        VStack(spacing: 14) {
            Text(AL.s(.talkWhatToPractice))
                .font(DS.Font.display(28, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .padding(.bottom, 10)
            ForEach(Array([AL.s(.talkSayRoleplay), AL.s(.talkSayNewPhrases), AL.s(.talkSayQuestion), AL.s(.talkSayMyDay)].enumerated()),
                    id: \.offset) { i, line in
                Button { session.sendText(line) } label: {
                    Text("“\(line)”")
                        .font(DS.Font.ui(16, weight: .medium))
                        .foregroundStyle(DS.Colors.accent)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(DS.Colors.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                // Pingo'daki gibi balonlar hafif sağa-sola kayık dizilir
                .frame(maxWidth: .infinity, alignment: i % 2 == 0 ? .leading : .trailing)
                .padding(.horizontal, i % 2 == 0 ? 0 : 6)
            }
        }
        .opacity(session.phase == .listening ? 1 : 0.55)
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
            let code = code == "paywall" ? "limit_reached" : code   // Pro'nun aylık süresi doldu
            Image(systemName: code == "limit_reached" ? "hourglass" : "wifi.exclamationmark")
                .font(.system(size: 36)).foregroundStyle(DS.Colors.muted)
            Text(code == "limit_reached" ? AL.s(.talkLimitReached)
                 : code == "not_configured" ? AL.s(.talkNotConfigured) : AL.s(.talkError))
                .font(DS.Font.display(22, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Colors.ink)
            if let detail = session.errorDetail, code != "limit_reached" {
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(DS.Colors.muted)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }
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
            // Seçenekli kart (çay mı kahve mi): seçenekler alt alta, aralarında ince bir çizgi
            VStack(spacing: 14) {
                let options = RealtimeVoiceSession.cardOptions(p.text)
                ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                    if i > 0 {
                        Capsule().fill(DS.Colors.line).frame(width: 36, height: 2)
                    }
                    Text(option)
                        .font(DS.Font.ui(options.count > 1 ? 28 : 32, weight: .semibold))
                        .foregroundStyle(cardCorrect ? DS.Colors.success : DS.Colors.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .animation(.easeOut(duration: 0.2), value: cardCorrect)
            if showTranslation {
                Text(p.translation)
                    .font(DS.Font.ui(19))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 36) {
                // Çeviri birkaç yüz ms sonra gelebilir: düğme hep yerinde, gelene kadar soluk
                Button {
                    if !showTranslation { Track.tutor("card_translate", mode: modeName) }
                    withAnimation { showTranslation.toggle() }
                } label: {
                    Image(systemName: "character.bubble").font(.system(size: 24, weight: .medium))
                }
                .disabled(p.translation.isEmpty)
                .opacity(p.translation.isEmpty ? 0.35 : 1)
                .accessibilityLabel(AL.s(.talkTranslate))
                Button {
                    Track.tutor("card_speak", mode: modeName)
                    TutorVoice.shared.speak(p.text, langCode: targetCode)
                } label: {
                    Image(systemName: "speaker.wave.2").font(.system(size: 24, weight: .medium))
                }
                .accessibilityLabel(AL.s(.quizTapToHear))
                // Beğendiği ifadeyi tek dokunuşla "Kaydettiklerim" destesine at (tekrar dokununca çıkar)
                if !isDemo {
                    let saved = savedPhrases.contains(p.text)
                    Button {
                        if saved {
                            DeckService.shared.remove(phrase: p.text, from: .saved)
                            savedPhrases.remove(p.text)
                        } else {
                            saveToDeck(p.text, p.translation, .saved)
                            savedPhrases.insert(p.text)
                            Track.tutor("card_save", mode: modeName)
                            Haptics.success()
                        }
                    } label: {
                        Image(systemName: saved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 23, weight: .medium))
                            .symbolEffect(.bounce, value: saved)
                    }
                    .accessibilityLabel(AL.s(.talkSaveToDeck))
                }
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
                 : session.phase == .connecting || session.phase == .idle ? AL.s(.talkConnecting)
                 : AL.s(.talkTranscript))
                .font(DS.Font.ui(17, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
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
                    else if !canTalk, abs(v.translation.height) < 10 { showTranscript = true; Track.tutor("transcript_open", mode: modeName) }
                }
        )
        .accessibilityAddTraits(.isButton)
        .animation(.spring(response: 0.25), value: holding)
        .animation(.easeOut(duration: 0.2), value: session.phase)
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
                // iOS paylaşım sayfası: WhatsApp, Mesajlar, Notlar…
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: transcriptText) { Image(systemName: "square.and.arrow.up") }
                        .disabled(session.turns.allSatisfy { $0.text.isEmpty })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showTranscript = false } label: { Image(systemName: "xmark") }
                }
            }
        }
        // iPhone'da alttan yarım sayfa; iPad'de ekranın ortasında form penceresi
        .presentationDetents(sizeClass == .regular ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// Sesli dersteki kartı kullanıcının destelerine yazar
    private func saveToDeck(_ text: String, _ translation: String, _ deck: DeckService.VoiceDeck) {
        let code = targetCode.uppercased()
        let flag: FlagModel = ["FR": .french, "DE": .german, "IT": .italian, "RU": .russian, "ZH": .chinese, "TR": .turkey][code] ?? .english
        let options = RealtimeVoiceSession.cardOptions(text)
        for (i, option) in options.enumerated() {
            let trOptions = translation.components(separatedBy: " / ")
            let tr = trOptions.count == options.count ? trOptions[i] : translation
            DeckService.shared.save(phrase: option, translation: tr, to: deck,
                                    name: AL.s(deck == .saved ? .deckSavedPhrases : .deckPronunciation),
                                    flag: flag, nativeCode: OL.nativeLangCode.uppercased(), targetCode: code)
        }
        NotificationCenter.default.post(name: .pathMistakesDeckCreated, object: nil)
    }

    /// Paylaşılacak düz metin: yalnızca konuşma ("Öğretmen: …", "Sen: …")
    private var transcriptText: String {
        session.turns.filter { !$0.text.isEmpty && $0.role != .card }.map { t in
            "\(t.role == .ai ? AL.s(.talkTutorLabel) : AL.s(.talkYouLabel)): \(t.text)"
        }.joined(separator: "\n\n") + "\n\n— WordRem AI"
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
                Button { TutorVoice.shared.speak(t.text, langCode: targetCode) } label: {
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
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { ctx in
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
        // Yumuşak dalga (0…1): abs(sin) gibi sıfırda sekmez, takılma hissi vermez
        func wave(_ speed: Double, _ shift: Double) -> CGFloat { CGFloat(0.5 + 0.5 * sin(t * speed + Double(i) * shift)) }
        switch phase {
        case .aiSpeaking:
            return 16 + 20 * wave(2.2, 0.9)
        case .userSpeaking:
            // Sürekli akan dalga; sesin gücü yalnızca genliği (yumuşakça) büyütür — zıplama yok
            let amp = 10 + 18 * CGFloat(min(1, level * 1.6))
            return 13 + amp * wave(2.6, 0.9)
        case .thinking, .connecting:
            // Ana sayfa, bağlanma ve düşünme: aynı sakin, orta seviye örüntü
            return 13 + 14 * wave(1.8, 0.8)
        case .listening:
            return 11 + 10 * CGFloat(level)
        default:
            return 11
        }
    }
}

#if DEBUG
/// Gece testleri için komut dosyası: Documents/debug_cmd.txt
///   open goal <chapter>/<goal> | open freechat | open demo
///   say <öğrencinin söylediği>
///   close
enum DebugDriver {
    static let open = Notification.Name("debug.open")
    static let say = Notification.Name("debug.say")
    static let close = Notification.Name("debug.close")
    private static var timer: Timer?

    static func start() {
        guard timer == nil, let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let file = dir.appendingPathComponent("debug_cmd.txt")
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { return }
            try? FileManager.default.removeItem(at: file)
            for line in text.split(separator: "\n").map(String.init) {
                let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
                guard let cmd = parts.first else { continue }
                let arg = parts.count > 1 ? parts[1] : ""
                switch cmd {
                case "open": NotificationCenter.default.post(name: open, object: arg)
                case "say": NotificationCenter.default.post(name: say, object: arg)
                case "close": NotificationCenter.default.post(name: close, object: nil)
                case "studio":
                    Task { @MainActor in
                        if let s = StudioDirector.scripts().first(where: { $0.id == arg }) { StudioDirector.shared.arm(s) }
                    }
                default: break
                }
            }
        }
    }
}

/// Sosyal medya videoları için senaryo: Documents/studio/<id>.json (repoda marketing/studio/)
struct StudioScript: Codable, Identifiable {
    let id: String
    let title: String
    /// "freechat" (varsayılan) · "goal <chapter>/<goal>" · "demo"
    var mode: String?
    /// Serbest sohbette Lupa'nın soracağı ilk soru; canlandırma sahnesini kurar
    var opener: String?
    /// Lupa'ya bu kayda özel yönerge (ör. sahne boyunca yalnızca İngilizce); boşsa varsayılan canlandırma yönergesi
    var note: String?
    /// Kayıt süresince uygulamanın dili (öğrencinin ana dili, ör. "en") ve öğrenilen dil (ör. "es"); kayıt bitince eskisine döner
    var native: String?
    var target: String?
    /// Öğrencinin sesi: dil kodu ("en-US", "es-ES") ya da cihazdaki ses kimliği
    var voice: String?
    /// Konuşma hızı (0.4–0.55 doğal)
    var rate: Float?
    /// Öğrencinin sırayla söyleyecekleri; "@card" ekrandaki kartı okur
    let lines: [String]
}

/// Stüdyo: senaryoyu oynatır ve kaydeder. Öğrenci replikleri cihazın sesiyle okunur, sonra test sürücüsüyle
/// Lupa'ya verilir; Lupa'nın cevapları, kartları ve düzeltmeleri gerçektir. Ekran sesiyle birlikte uygulamanın içinden
/// kaydedilir (Documents/studio-out/<id>.mp4); kurgu için zaman çizelgesi yanına yazılır (<id>.json).
@MainActor
final class StudioDirector: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = StudioDirector()
    private var script: StudioScript?
    private var next = 0
    private var busy = false
    private var pending: String?
    private let synth = AVSpeechSynthesizer()
    private var onSpoken: (() -> Void)?

    // Kayıt ve zaman çizelgesi
    private var recordingStart: Date?
    private var events: [[String: Any]] = []
    private var lastPhase: RealtimeVoiceSession.Phase = .idle
    private var lineIndex = -1
    private var lineText = ""
    private weak var session: RealtimeVoiceSession?
    /// Kaydın adı (senaryo bitince script boşalır, kayıt bu adla yazılır)
    private var scriptId: String?
    /// Kayıttan önceki ana dil / öğrenilen dil (kayıt bitince geri yüklenir)
    private var savedLanguages: (native: String, target: String?, targetName: String?)?

    override private init() {
        super.init()
        synth.delegate = self
    }

    /// Videoda sahne bölünmesin: Lupa karakterden çıkmaz, çeviri ve övgü yok, her tur öğrencinin sıradaki cümlesi kartta
    static let rolePlayNote = """
    This is a short role-play recording. Stay in character for the whole scene and speak ONLY the language the learner is studying, \
    even though they are a beginner: no translations, no explanations, no comments on pronunciation, no praise. Keep every line short \
    and natural, like the real person you are playing. After each line, show the learner's natural next line as the card. \
    After three exchanges, close the scene naturally (say goodbye in character) and show the learner's goodbye line as the card.
    """

    private static var documents: URL? { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first }

    static func scripts() -> [StudioScript] {
        guard let dir = documents?.appendingPathComponent("studio"),
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return files.filter { $0.pathExtension == "json" }
            .compactMap { (try? Data(contentsOf: $0)).flatMap { try? JSONDecoder().decode(StudioScript.self, from: $0) } }
            .sorted { $0.id < $1.id }
    }

    /// Kaydı başlatır (iOS bir kez "Ekranı kaydet" izni sorar), izin gelince dersi açar
    func arm(_ s: StudioScript) {
        script = s
        scriptId = s.id
        next = 0
        busy = false
        pending = nil
        events = []
        lineIndex = -1
        recordingStart = nil
        lastPhase = .idle
        // Kayıtta kimse ekrana dokunmaz: otomatik kilit dersi (ve bağlantıyı) yarıda keser
        UIApplication.shared.isIdleTimerDisabled = true
        useLanguages(native: s.native, target: s.target)
        let recorder = RPScreenRecorder.shared()
        recorder.isMicrophoneEnabled = false
        recorder.startRecording { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error { voiceLog.error("studio recording failed: \(error.localizedDescription, privacy: .public)") }
                else { self.recordingStart = Date(); voiceLog.info("studio recording started") }
                self.open(s)
            }
        }
        // Kayıt güvenlik sınırı: 4 dakika
        DispatchQueue.main.asyncAfter(deadline: .now() + 240) { [weak self] in
            if self?.recordingStart != nil { self?.finish() }
        }
    }

    /// Videonun dili: uygulama arayüzü ve kart çevirileri ana dilde, Lupa öğrenilen dilde konuşur
    private func useLanguages(native: String?, target: String?) {
        guard native != nil || target != nil else { return }
        let d = UserDefaults.standard
        savedLanguages = (LanguageManager.shared.currentLanguageCode, d.string(forKey: "selectedTargetLanguageCode"),
                          d.string(forKey: "selectedTargetLanguageName"))
        if let native { LanguageManager.shared.setLanguage(native) }
        if let target {
            d.set(target, forKey: "selectedTargetLanguageCode")
            d.set(LanguageManager.shared.languageName(for: target), forKey: "selectedTargetLanguageName")
        }
    }

    private func restoreLanguages() {
        guard let saved = savedLanguages else { return }
        savedLanguages = nil
        let d = UserDefaults.standard
        LanguageManager.shared.setLanguage(saved.native)
        d.set(saved.target, forKey: "selectedTargetLanguageCode")
        d.set(saved.targetName, forKey: "selectedTargetLanguageName")
    }

    private func open(_ s: StudioScript) {
        if let opener = s.opener { TutorBrain.chatOpener = opener }
        TutorBrain.studioNote = s.note ?? Self.rolePlayNote
        TutorBrain.studioNameless = true
        AppRouter.shared.route = .talk
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NotificationCenter.default.post(name: DebugDriver.open, object: s.mode ?? "freechat")
        }
    }

    private func mark(_ event: [String: Any]) {
        guard let start = recordingStart else { return }
        var e = event
        e["t"] = (Date().timeIntervalSince(start) * 1000).rounded() / 1000
        events.append(e)
    }

    /// Ders ekranı her faz ve yeni satırda çağırır: zaman çizelgesi + sıradaki replik
    func observe(_ session: RealtimeVoiceSession) {
        guard script != nil || recordingStart != nil else { return }
        self.session = session
        if session.phase != lastPhase {
            mark(["ev": "phase", "v": "\(session.phase)"])
            lastPhase = session.phase
        }
        step(session)
    }

    func turnAdded(_ session: RealtimeVoiceSession) {
        guard recordingStart != nil, let last = session.turns.last else { return }
        mark(["ev": "turn", "i": session.turns.count - 1, "role": "\(last.role)"])
    }

    /// Lupa susup sırayı verince sıradaki repliği (kısa, doğal bir duraklamayla) okur
    private func step(_ session: RealtimeVoiceSession) {
        guard let s = script, !busy, session.phase == .listening, Self.learnersTurn(session) else { return }
        // Okunduğu sırada Lupa araya girdiyse replik kaybolmaz: sıra gelince yalnızca gönderilir
        if let line = pending {
            pending = nil
            session.debugLearnerSays(line)
            return
        }
        guard next < s.lines.count else {
            script = nil
            // Lupa'nın son cümlesi ve kartı ekranda biraz kalsın
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.finish() }
            return
        }
        busy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self, weak session] in
            guard let self, let session else { return }
            var line = s.lines[self.next]
            if line == "@card" {
                // Seçenekli kartta ilk seçenek; boşluklu kart senaryoda açıkça yazılmalı
                line = Self.currentCard(session).map {
                    String($0.components(separatedBy: " / ")[0]).replacingOccurrences(of: "...", with: "")
                } ?? ""
            }
            guard session.phase == .listening, Self.learnersTurn(session), !line.isEmpty else { self.busy = false; return }
            self.next += 1
            voiceLog.info("studio says: \(line, privacy: .public)")
            session.studioSpeaking(true)
            self.say(line, voice: s.voice, rate: s.rate) {
                session.studioSpeaking(false)
                self.busy = false
                if session.phase == .listening { session.debugLearnerSays(line) } else { self.pending = line }
                // Öğrenci veda ettiyse sahne biter: Lupa'nın vedasından sonra yeni kart okunmaz
                if line.range(of: Self.farewell, options: [.regularExpression, .caseInsensitive]) != nil {
                    self.next = s.lines.count
                }
            }
        }
    }

    /// Kaydı durdurur; video ve zaman çizelgesi Documents/studio-out içine yazılır
    private func finish() {
        guard let id = scriptId, recordingStart != nil, let dir = Self.documents?.appendingPathComponent("studio-out") else {
            UIApplication.shared.isIdleTimerDisabled = false
            restoreLanguages()
            return
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let video = dir.appendingPathComponent("\(id).mp4")
        try? FileManager.default.removeItem(at: video)
        let turns: [[String: Any]] = session?.turns.map { ["role": "\($0.role)", "text": $0.text, "detail": $0.detail ?? ""] } ?? []
        let timeline: [String: Any] = ["id": id, "events": events, "turns": turns]
        if JSONSerialization.isValidJSONObject(timeline), let data = try? JSONSerialization.data(withJSONObject: timeline, options: [.prettyPrinted]) {
            try? data.write(to: dir.appendingPathComponent("\(id).json"))
        }
        recordingStart = nil
        script = nil
        TutorBrain.studioNameless = false
        RPScreenRecorder.shared().stopRecording(withOutput: video) { error in
            Task { @MainActor in
                UIApplication.shared.isIdleTimerDisabled = false
                self.restoreLanguages()
                if let error { voiceLog.error("studio save failed: \(error.localizedDescription, privacy: .public)") }
                else { voiceLog.info("studio saved \(id, privacy: .public)") }
            }
        }
    }

    /// Öğrencinin veda cümlesi (senaryonun dillerinde)
    private static let farewell = #"\b(bye|goodbye|have a (nice|great|good) (day|one|evening)|see you|thank you for your time|"#
        + #"adi[oó]s|hasta (luego|pronto|mañana)|buen d[ií]a|chao|au revoir|bonne (journée|soirée)|à bientôt|tschüss|"#
        + #"auf wiedersehen|sch[öo]nen tag|arrivederci|buona giornata|ciao|до свидания|пока|再见|güle güle|hoşça kal)"#

    /// Lupa en az bir kez konuşmuş ve son söz öğrencide değil
    private static func learnersTurn(_ session: RealtimeVoiceSession) -> Bool {
        session.turns.contains { $0.role == .ai } && session.turns.last?.role != .user
    }

    /// Öğrencinin son repliğinden sonra gösterilen kart
    private static func currentCard(_ session: RealtimeVoiceSession) -> String? {
        let afterUser = session.turns.lastIndex { $0.role == .user }.map { session.turns.index(after: $0) } ?? session.turns.startIndex
        return session.turns[afterUser...].last { $0.role == .card }?.text
    }

    private func say(_ text: String, voice: String?, rate: Float?, done: @escaping () -> Void) {
        let u = AVSpeechUtterance(string: text)
        let v = voice ?? "en-US"
        u.voice = AVSpeechSynthesisVoice(identifier: v) ?? Self.bestVoice(language: v)
        u.rate = rate ?? 0.48
        voiceLog.info("studio voice: \(u.voice?.name ?? "-", privacy: .public) q\(u.voice?.quality.rawValue ?? 0, privacy: .public)")
        lineIndex += 1
        lineText = text
        mark(["ev": "learner_start", "line": lineIndex, "text": text])
        onSpoken = done
        synth.speak(u)
    }

    /// Dil için cihazdaki en kaliteli ses (Ayarlar → Erişilebilirlik → Oku ve Konuş → Sesler'den "Premium" ses indirilebilir)
    private static func bestVoice(language: String) -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == language }
            .max { $0.quality.rawValue < $1.quality.rawValue }
            ?? AVSpeechSynthesisVoice(language: language)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let word = (utterance.speechString as NSString).substring(with: characterRange)
        Task { @MainActor in self.mark(["ev": "word", "line": self.lineIndex, "w": word]) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.mark(["ev": "learner_end", "line": self.lineIndex])
            let done = self.onSpoken
            self.onSpoken = nil
            done?()
        }
    }
}
#endif
