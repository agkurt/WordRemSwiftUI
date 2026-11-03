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
    /// Öğretmenin gösterdiği kart, sesi bitince sayfaya yazılır
    @State private var pendingPhrase: (text: String, translation: String)?
    /// Öğrencinin kartı söylediği satırlar: doğru mu (tik) yanlış mı (kırmızı kalem)
    @State private var verdicts: [UUID: Bool] = [:]
    /// Bu sohbetin defterdeki sayfası (Defterlerim'de çevrilir)
    @State private var pageId = UUID()
    /// Yapay zekâ veri paylaşımı izni henüz verilmedi: bağlanmadan önce izin sayfası gösterilir
    @State private var showConsent = false
    /// Ders ekranında o an açık yaprak: ilk satırı (nil = en baştan) ve kaçıncı yaprak olduğu
    /// Ders yaprakları: her yaprağın ilk satırı (ilk yaprak en baştan, nil). Son yaprak canlı.
    @State private var pageStarts: [UUID?] = [nil]
    /// Ekranda açık yaprak (öğrenci eski yapraklara kaydırıp bakabilir)
    @State private var viewPage = 0
    @State private var pageHeight: CGFloat = 0
    /// Profil karnesine yazılmış konuşma süresi (aynı süre iki kez sayılmasın)
    @State private var countedSeconds = 0
    @State private var completionXPGiven = false
    /// Yarım kalan dersin önceki sayfası: defterde kaldığı yerden devam
    @State private var earlierPage: (turns: [RealtimeVoiceSession.Turn], date: Date)?
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
            header
            pageArea
                // Kenar boşluğu çizgisi yalnızca sayfada: üstteki "Bitir" ve alttaki düğmelerin üstünden geçmez
                .background { MarginLine() }
            bottomBar
        }
        .ruledPage(margin: false)
        .task {
            #if DEBUG
            if DemoData.stage == "lesson" {
                let demo = DemoData.lessonPage
                session.debugStage(demo.turns)
                for t in session.turns where t.role == .user { verdicts[t.id] = true }
                phrase = demo.phrase
                showTranslation = true
                return
            }
            #endif
            // Ses, konuşma metni ve ad yapay zekâ servislerine gitmeden önce kullanıcının izni alınır
            guard AIConsent.granted else {
                showConsent = true
                return
            }
            await start()
        }
        .overlay {
            if showConsent {
                AIConsentView {
                    AIConsent.set(true)
                    withAnimation(.easeOut(duration: 0.25)) { showConsent = false }
                    Task { await start() }
                } onDecline: {
                    Track.tutor("ai_consent_decline", mode: modeName)
                    if isDemo { onFinished(false) } else { dismiss() }
                }
                .transition(.opacity)
            }
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
            // Sayfada öğrencinin son satırına tik ya da kırmızı kalem
            if let u = session.turns.last(where: { $0.role == .user }) { verdicts[u.id] = session.lastAnswerCorrect }
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

    /// İzin alındıktan sonra: ücretsiz süresi bitmiş, Pro olmayan kullanıcı sunucuya gitmeden ödeme ekranını görür
    private func start() async {
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

    private func begin() async {
        earlierPage = TutorBrain.savedPage(for: activeMode)
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
        recordPage()
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
    /// Sohbet defterin bir sayfası olarak yazılır (öğrenci en az bir şey söylediyse)
    private func recordPage() {
        let lines = session.turns.compactMap { t -> NotebookPage.Line? in
            guard !t.text.isEmpty else { return nil }
            return NotebookPage.Line(role: t.role == .ai ? .ai : t.role == .user ? .user : .card, text: t.text, detail: t.detail)
        }
        // Konuşma süresi karneye eklenir (yalnızca yeni geçen kısım)
        let talked = max(0, session.elapsedSeconds - countedSeconds)
        if talked > 0 {
            countedSeconds = session.elapsedSeconds
            UserStore.shared.update { $0.voiceSeconds = ($0.voiceSeconds ?? 0) + talked }
        }
        // XP (sıralama): her 10 saniye konuşma 1 XP, tamamlanan ders bir kez +25
        var xp = talked / 10
        if finishedSuccess == true, !completionXPGiven { completionXPGiven = true; xp += 25 }
        if xp > 0 { Task { await DataService.shared.awardXP(xp) } }
        let info = pageInfo
        let language = (RealtimeVoiceSession.targetOverride ?? targetCode).lowercased()
        NotebookStore.shared.save(NotebookPage(id: isDemo ? NotebookPage.demoId(for: language) : pageId,
                                               date: session.startedAt, language: language,
                                               kicker: info.kicker, title: info.title, lines: lines,
                                               done: finishedSuccess == true))
    }

    private func saveAndStop() {
        recordPage()
        if session.turns.contains(where: { $0.role == .user && !$0.text.isEmpty }) { StudyStreak.record() }
        if finishedSuccess != true {
            TutorBrain.saveProgress(for: activeMode, turns: (earlierPage?.turns ?? []) + session.turns, step: session.targetProgress)
        }
        session.stop()
    }

    private var isConnecting: Bool { session.phase == .connecting || session.phase == .idle }

    private func revealPendingPhrase() {
        guard let p = pendingPhrase else { return }
        pendingPhrase = nil
        showTranslation = TutorPrefs.alwaysTranslate
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

    // MARK: - Üst: Bitir · bölüm ve sayfa · ayraç
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Button { close() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                        Text(AL.s(.talkEnd))
                    }
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(height: 44)
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AL.s(.talkEnd))
                // iOS paylaşım sayfası: konuşmayı WhatsApp, Mesajlar, Notlar'a gönder
                if !isDemo, session.turns.contains(where: { $0.role == .user && !$0.text.isEmpty }) {
                    ShareLink(item: transcriptText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .frame(width: 44, height: 44)
                    }
                }
                Spacer()
            }
            Eyebrow(text: pageInfo.kicker, color: DS.Colors.accentText)
                .lineLimit(1)
                .padding(.leading, DS.Page.textX)
                .padding(.trailing, 24)
            Text(pageInfo.title)
                .font(DS.Font.display(22, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(2)
                .padding(.leading, DS.Page.textX)
                .padding(.trailing, 24)
        }
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            BookmarkMark(mood: bookmarkMood, level: session.inputLevel, width: 10)
                .padding(.trailing, 24)
        }
    }

    private func close() {
        if isSetup, !completing, !session.turns.isEmpty, !isConnecting { confirmLeave = true; return }
        saveAndStop()
        if isDemo { onFinished(false) } else { dismiss() }
    }

    private var bookmarkMood: BookmarkMark.Mood {
        if session.isHoldingToTalk { return .listening }
        switch session.phase {
        case .aiSpeaking, .connecting, .idle, .thinking: return .speaking
        case .userSpeaking: return .listening
        default: return .calm
        }
    }

    /// Üstteki künye: bölüm · sayfa ve dersin adı
    private var pageInfo: (kicker: String, title: String) {
        switch activeMode {
        case .goal(let c, let g):
            let store = ScenarioStore.shared
            if let chapter = store.chapters.first(where: { $0.id == c }), let goal = chapter.goals.first(where: { $0.id == g }) {
                return ("\(chapter.localizedTitle) · \(PageText.page(store.pageNumber(of: goal)))", goal.localizedTitle)
            }
        case .demo:
            return (PageText.firstPage, PageText.meetLupa)
        case .languageSetup(let code):
            let name = OL.languageName(for: code.lowercased())
            return (PageText.newNotebook, name.capitalized(with: Locale(identifier: OL.nativeLangCode)))
        case .wordPractice:
            return (AL.s(.tabWords), AL.s(.talkPracticeTitle))
        default:
            break
        }
        let date = Date().formatted(.dateTime.day().month(.wide).locale(Locale(identifier: OL.nativeLangCode)))
        return ("\(PageText.freeChat) · \(date)", PageText.blankPage)
    }

    // MARK: - Sayfa
    @ViewBuilder
    private var pageArea: some View {
        if case .failed(let code) = session.phase {
            failureView(code)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let done = finishedSuccess, session.phase == .ended {
            // Demoda "Hedef tamamlandı / Sıradaki" gösterilmez: doğrudan paywall gelir
            Group { if isDemo { Color.clear } else { completionView(done) } }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            dialoguePage
        }
    }

    /// Konuşma, çizgili sayfaya satır satır yazılır; eski satırlar soluklaşır, sayfa en sona kayar.
    /// Sayfa iyice dolunca (önce bir süre kayar) Lupa yeni söze başlarken yaprak kâğıt gibi çevrilir.
    /// Öğrenci eski yapraklara sürükleyerek dönebilir; sağ altta sayfa numarası.
    private var dialoguePage: some View {
        GeometryReader { geo in
            PageCurlReader(count: pageStarts.count, index: $viewPage, pageColor: DS.Colors.paper, tapToTurn: false) { i in
                AnyView(leafView(i, viewport: geo.size.height))
            }
            .overlay(alignment: .bottomTrailing) {
                Text("— \(viewPage + 1) —")
                    .font(.system(size: 13, design: .serif).italic())
                    .foregroundStyle(DS.Colors.muted)
                    .padding(.trailing, 22)
                    .padding(.bottom, 6)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: viewPage)
                    .allowsHitTesting(false)
            }
            .onChange(of: session.turns.count) { _ in turnPageIfFull(viewport: geo.size.height) }
            .onPreferenceChange(PageHeightKey.self) { pageHeight = $0 }
        }
    }

    /// Bir yaprak: kendi içinde kayar; canlı yaprak hep en sona kayar
    private func leafView(_ i: Int, viewport: CGFloat) -> some View {
        let live = i == pageStarts.count - 1
        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                pageSheet(index: i, minHeight: viewport)
            }
            .defaultScrollAnchor(live ? .bottom : .top)
            .scrollBounceBehavior(.basedOnSize)
            // Yukarı kayan eski satırlar başlığın altında yumuşakça kaybolur
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.04)],
                                 startPoint: .top, endPoint: .bottom))
            .onChange(of: session.caption) { _ in if live { proxy.scrollTo("end", anchor: .bottom) } }
            .onChange(of: session.turns.count) { _ in if live { withAnimation { proxy.scrollTo("end", anchor: .bottom) } } }
            .onChange(of: phrase?.text) { _ in if live { withAnimation { proxy.scrollTo("end", anchor: .bottom) } } }
            .onChange(of: showTranslation) { _ in if live { withAnimation { proxy.scrollTo("end", anchor: .bottom) } } }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if session.phase == .aiSpeaking || session.phase == .thinking {
                Track.tutor("interrupt", mode: modeName)
                session.interrupt()
            }
        }
    }

    /// Defterin bir yaprağı: kendi çizgileri ve kenar boşluğuyla opak bir kâğıt
    private func pageSheet(index: Int, minHeight: CGFloat) -> some View {
        let live = index == pageStarts.count - 1
        let startIdx = pageStarts[index].flatMap { id in session.turns.firstIndex { $0.id == id } } ?? 0
        let endIdx = live ? session.turns.count
            : (pageStarts[index + 1].flatMap { id in session.turns.firstIndex { $0.id == id } } ?? session.turns.count)
        let onPage = Set(session.turns[min(startIdx, session.turns.count)..<max(min(startIdx, session.turns.count), min(endIdx, session.turns.count))].map(\.id))
        let turns = pageTurns.filter { onPage.contains($0.id) }
        let liveFrom = turns.lastIndex { $0.role == .ai } ?? 0
        return VStack(alignment: .leading, spacing: 0) {
            // Önceki oturumdan kalan sayfa soluk, altında "kaldığın yer" ayracı (yalnızca ilk yaprakta)
            if index == 0, let earlier = earlierPage {
                ForEach(earlier.turns) { t in turnLine(t).opacity(0.4) }
                resumeDivider(earlier.date)
            }
            ForEach(Array(turns.enumerated()), id: \.element.id) { i, t in
                turnLine(t).opacity(live && i < liveFrom ? 0.45 : live ? 1 : 0.8)
            }
            if live {
                if showSuggestions { suggestionsView }
                if let phrase {
                    phraseBlock(phrase)
                        .shake(cardShakes)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            Color.clear.frame(height: 1).id("end")
        }
        .background(GeometryReader { g in Color.clear.preference(key: PageHeightKey.self, value: live ? g.size.height : 0) })
        .frame(maxWidth: 560, alignment: .leading)
        .padding(.leading, DS.Page.textX)
        .padding(.trailing, 24)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(alignment: .top) { RuledLines() }
        .background { MarginLine() }
        .background(DS.Colors.paper)
        .animation(.easeOut(duration: 0.3), value: phrase?.text)
    }

    /// Yaprak iyice dolduysa (öğrenci bir süre kaydırarak okudu) ve Lupa yeni söze başlıyorsa sayfa çevrilir.
    /// Öğrenci eski bir yaprağa bakıyorsa, Lupa konuşmaya başlayınca canlı yaprağa dönülür.
    private func turnPageIfFull(viewport: CGFloat) {
        guard let last = session.turns.last, last.role == .ai else { return }
        let liveIndex = pageStarts.count - 1
        let startIdx = pageStarts[liveIndex].flatMap { id in session.turns.firstIndex { $0.id == id } } ?? 0
        let turnsOnPage = session.turns.count - startIdx
        if last.id != pageStarts[liveIndex], pageHeight > viewport * 1.6, turnsOnPage >= 7 {
            Haptics.tap()
            pageStarts.append(last.id)
            withAnimation { viewPage = pageStarts.count - 1 }
        } else if viewPage != liveIndex {
            withAnimation { viewPage = liveIndex }
        }
    }

    /// Sayfaya yazılacak satırlar: o an gösterilen kart ayrıca büyük yazılır
    private var pageTurns: [RealtimeVoiceSession.Turn] {
        var turns = session.turns.filter { !$0.text.isEmpty }
        if let p = phrase, let card = turns.last(where: { $0.role == .card }), card.text == p.text {
            turns.removeAll { $0.id == card.id }
        }
        return turns
    }

    @ViewBuilder
    private func turnLine(_ t: RealtimeVoiceSession.Turn) -> some View {
        switch t.role {
        case .ai:
            let isLive = t.id == session.turns.last(where: { $0.role == .ai })?.id
            let text = isLive && !session.caption.isEmpty ? session.caption : t.text
            // Lupa'nın sözü sayfaya kalemle yazılır; eski satırlar olduğu gibi durur
            PenText(text: text, animate: isLive, note: "Lupa", caret: isLive && session.phase == .aiSpeaking)
        case .user:
            let verdict = verdicts[t.id]
            let line = Text(t.text).underline(verdict == false, pattern: .dot, color: DS.Colors.redPen)
            RuledText(verdict == true
                      ? line + Text("  ✓ \(PageText.correct)").font(DS.Font.ui(13, weight: .semibold)).foregroundColor(DS.Colors.success)
                      : line,
                      size: 19, color: DS.Colors.slate, note: AL.s(.talkYouLabel), noteColor: DS.Colors.slate)
        case .card:
            VStack(alignment: .leading, spacing: 0) {
                RuledText(highlightedText(t.text), size: 19, weight: .semibold)
                if let tr = t.detail, !tr.isEmpty {
                    RuledText(tr, size: 16, italic: true, color: DS.Colors.muted)
                }
            }
        }
    }

    /// Önceki oturumla bugünün arasında: noktalı çizgi, ortada "kaldığın yer · tarih"
    private func resumeDivider(_ date: Date) -> some View {
        HStack(spacing: 10) {
            DottedLeader(color: DS.Colors.margin)
            Text("\(PageText.youLeftOff) · \(date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))))")
                .font(.system(size: 13, design: .serif).italic())
                .foregroundStyle(DS.Colors.accentText)
                .fixedSize()
            DottedLeader(color: DS.Colors.margin)
        }
        // Ayraç yazısı da çizginin hemen üstüne oturur
        .frame(height: DS.Page.pitch - 5, alignment: .bottom)
        .padding(.bottom, 5)
    }

    /// Serbest sohbet açılışı: öğrenci ne yapmak istediğini söyler ya da numaralı bir satıra dokunur
    private var showSuggestions: Bool {
        activeMode == .freeChat && session.caption.isEmpty && !session.turns.contains { $0.role == .user }
    }

    private var suggestionsView: some View {
        let items: [(title: String, sub: String, say: String)] = [
            (AL.s(.talkModeRoleplay), PageText.subRoleplay, AL.s(.talkSayRoleplay)),
            (AL.s(.talkModeNewPhrases), PageText.subPhrases, AL.s(.talkSayNewPhrases)),
            (AL.s(.talkModeQuestion), PageText.subQuestion, AL.s(.talkSayQuestion)),
            (AL.s(.talkModeMyDay), PageText.subMyDay, AL.s(.talkSayMyDay)),
        ]
        return VStack(alignment: .leading, spacing: 0) {
            RuledText(PageText.whatToWrite, note: "Lupa")
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                Button { session.sendText(item.say) } label: {
                    // Her öneri tek satır: numara, başlık ve kısa açıklama, çizginin hemen üstünde
                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text("\(i + 1).")
                            .font(.system(size: 17, design: .serif).italic())
                            .foregroundStyle(DS.Colors.accentText)
                            .frame(width: 20, alignment: .leading)
                        (Text(item.title)
                            .font(.system(size: 18, design: .serif))
                            .foregroundColor(DS.Colors.ink)
                         + Text("  ·  \(item.sub)")
                            .font(DS.Font.ui(12))
                            .foregroundColor(DS.Colors.muted))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .frame(height: DS.Page.pitch - 5, alignment: .bottom)
                    .padding(.bottom, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(session.phase == .listening ? 1 : 0.55)
    }

    /// Ders bitti: sayfaya mühür, sıradaki derse geçir
    private func completionView(_ done: Bool) -> some View {
        VStack(spacing: 14) {
            if done {
                InkStamp(top: Date().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))).uppercased(),
                         title: "✓", bottom: "WORDREM", size: 112)
            } else {
                Image(systemName: "hand.thumbsup").font(.system(size: 40)).foregroundStyle(DS.Colors.accent)
            }
            Text(done ? AL.s(.talkLessonComplete) : AL.s(.talkSessionEnded))
                .font(DS.Font.display(30, weight: .bold)).foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
            if done, let next = ScenarioStore.shared.next {
                VStack(spacing: 6) {
                    Text(AL.s(.talkNextUp))
                        .font(DS.Font.ui(11, weight: .bold)).tracking(1.2)
                        .foregroundStyle(DS.Colors.muted)
                    Text(next.goal.localizedTitle)
                        .font(DS.Font.display(21, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 18)
                Button(AL.s(.talkContinueNext)) { startNext(next.chapter.id, next.goal.id) }
                    .buttonStyle(InkButtonStyle())
                    .frame(maxWidth: 280)
                    .padding(.top, 6)
            }
        }
    }

    private func startNext(_ chapterId: String, _ goalId: String) {
        recordPage()
        pageId = UUID()
        pageStarts = [nil]
        viewPage = 0
        countedSeconds = 0
        completionXPGiven = false
        nextMode = .goal(chapterId: chapterId, goalId: goalId)
        finishedSuccess = nil
        phrase = nil
        pendingPhrase = nil
        verdicts = [:]
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
            #if DEBUG
            // Ham hata metni yalnızca geliştirmede: kullanıcı ve App Store incelemesi görmez
            if let detail = session.errorDetail, code != "limit_reached" {
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(DS.Colors.muted)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }
            #endif
            if code != "limit_reached" && code != "not_configured" {
                Button(AL.s(.paywallRetry)) { Task { await begin() } }
                    .buttonStyle(OutlineButtonStyle())
                    .frame(maxWidth: 220)
            }
        }
    }

    // MARK: - Söylenecek ifade: fosforlu, büyük; altında dinle / deftere kaydet
    private func phraseBlock(_ p: (text: String, translation: String)) -> some View {
        let options = RealtimeVoiceSession.cardOptions(p.text)
        return VStack(alignment: .leading, spacing: 0) {
            // Seçenekli kart (çay mı kahve mi): seçenekler alt alta
            // İfade de kalemle yazılır, fosforlu kalem peşinden gelir
            ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                PenText(text: " \(option) ", size: options.count > 1 ? 28 : 32, weight: .semibold,
                        color: cardCorrect ? DS.Colors.success : DS.Colors.ink,
                        rows: 2, note: i == 0 ? PageText.sayLabel : nil,
                        highlight: cardCorrect ? DS.Colors.successSoft : DS.Colors.highlight, speed: 30)
            }
            .animation(.easeOut(duration: 0.2), value: cardCorrect)
            if showTranslation, !p.translation.isEmpty {
                RuledText(p.translation, size: 18, italic: true, color: DS.Colors.muted)
            }
            HStack(spacing: 22) {
                Button {
                    Track.tutor("card_speak", mode: modeName)
                    TutorVoice.shared.speak(p.text, langCode: targetCode)
                } label: {
                    Label(PageText.listen, systemImage: "speaker.wave.2")
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
                        Label(saved ? PageText.saved : PageText.saveToNotebook, systemImage: saved ? "bookmark.fill" : "bookmark")
                            .symbolEffect(.bounce, value: saved)
                    }
                    .accessibilityLabel(AL.s(.talkSaveToDeck))
                }
                Spacer(minLength: 0)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DS.Colors.success)
                    .scaleEffect(cardCorrect ? 1 : 0.2)
                    .opacity(cardCorrect ? 1 : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.5), value: cardCorrect)
            }
            .font(DS.Font.ui(14, weight: .medium))
            .foregroundStyle(DS.Colors.accentText)
            .buttonStyle(.plain)
            // Düğmeler de satır çizgisinin hemen üstüne oturur
            .frame(height: DS.Page.pitch - 5, alignment: .bottom)
            .padding(.bottom, 5)
        }
    }

    // MARK: - Alt: İpucu · mühür · Çeviri
    /// Sıra kullanıcıdaysa mühür basılı tutulur; Lupa konuşurken dokununca araya girilir
    private var canTalk: Bool {
        switch session.phase {
        case .listening, .userSpeaking: return true
        default: return false
        }
    }

    private var statusLabel: String {
        if session.isHoldingToTalk { return AL.s(.talkReleaseToSend) }
        switch session.phase {
        case .listening, .userSpeaking: return phrase != nil ? PageText.sayIt : AL.s(.talkHoldToTalk)
        case .connecting, .idle: return AL.s(.talkConnecting)
        case .aiSpeaking: return PageText.lupaSpeaking
        case .thinking: return PageText.lupaThinking
        default: return ""
        }
    }

    private var bottomBar: some View {
        let holding = session.isHoldingToTalk
        let freeChat = activeMode == .freeChat
        let canTranslate = !(phrase?.translation.isEmpty ?? true)
        return HStack(alignment: .bottom, spacing: 0) {
            sideButton(freeChat ? PageText.topics : PageText.hint,
                       icon: freeChat ? "square.grid.2x2" : "lightbulb") {
                if freeChat { showTopics = true } else { showHelp = true }
                Track.tutor(freeChat ? "topic_picker_open" : "help_open", mode: modeName)
            }
            .opacity(isConnecting || isSetup ? 0 : 1)
            .disabled(isConnecting || isSetup || holding)
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                StampMic(look: holding ? .holding : canTalk ? .ready : .idle)
                Text(statusLabel)
                    .font(DS.Font.ui(13, weight: canTalk ? .medium : .regular))
                    .foregroundStyle(holding ? DS.Colors.accentText : canTalk ? DS.Colors.ink : DS.Colors.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 200, height: 120, alignment: .bottom)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !session.isHoldingToTalk else { return }
                        if canTalk { session.beginHold() }
                    }
                    .onEnded { _ in
                        if session.isHoldingToTalk { session.endHold() }
                        else if session.phase == .aiSpeaking || session.phase == .thinking {
                            Track.tutor("interrupt", mode: modeName)
                            session.interrupt()
                        }
                    }
            )
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            Spacer(minLength: 0)
            sideButton(PageText.translation, icon: "character.bubble", active: showTranslation && canTranslate) {
                if !showTranslation { Track.tutor("card_translate", mode: modeName) }
                withAnimation { showTranslation.toggle() }
            }
            .opacity(canTranslate ? 1 : 0.35)
            .disabled(!canTranslate || holding)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .animation(.easeOut(duration: 0.2), value: session.phase)
    }

    private func sideButton(_ title: String, icon: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 21, weight: .regular))
                Text(title).font(DS.Font.ui(12, weight: active ? .semibold : .regular))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(active ? DS.Colors.accentText : DS.Colors.inkSoft)
            .frame(width: 72, height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

}

private struct PageHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

// MARK: - Durum logosu: dört renkli ayraç (eski adla; ekranlar bunu kullanıyor)
struct VoiceLogoView: View {
    let phase: RealtimeVoiceSession.Phase
    let level: Float
    var width: CGFloat = 12

    var body: some View {
        BookmarkMark(mood: mood, level: level, width: width)
    }

    private var mood: BookmarkMark.Mood {
        switch phase {
        case .aiSpeaking, .thinking, .connecting: return .speaking
        case .userSpeaking: return .listening
        default: return .calm
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


// MARK: - Yapay zekâ veri paylaşımı izni

/// Lupa ile ilk konuşmadan önce: ne gönderilir, kime gider, neden. Kabul edilmezse sesli öğretmen bağlanmaz.
struct AIConsentView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void
    @State private var showPrivacy = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                BookmarkMark(width: 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 8)
                Text(ConsentText.title)
                    .font(DS.Font.display(30, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .padding(.top, 8)
                Text(ConsentText.intro)
                    .font(DS.Font.ui(16))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                section(ConsentText.whatTitle, items: ConsentText.whatItems)
                section(ConsentText.whoTitle, items: [ConsentText.who])
                section(ConsentText.whyTitle, items: [ConsentText.why])

                Text(ConsentText.note)
                    .font(.system(size: 14, design: .serif).italic())
                    .foregroundStyle(DS.Colors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 22)
                Button(ConsentText.privacy) { showPrivacy = true }
                    .font(DS.Font.ui(14, weight: .semibold))
                    .foregroundStyle(DS.Colors.accentText)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    Button(ConsentText.accept, action: onAccept)
                        .buttonStyle(InkButtonStyle())
                    Button(ConsentText.decline, action: onDecline)
                        .font(DS.Font.ui(15, weight: .medium))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .padding(.top, 26)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(DS.Colors.paper.ignoresSafeArea())
        .sheet(isPresented: $showPrivacy) {
            SafariWebView(url: URL(string: "https://api.wordremai.app/privacy")!)
        }
    }

    private func section(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: title, color: DS.Colors.accentText)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle().fill(DS.Colors.accent).frame(width: 5, height: 5).offset(y: -3)
                    Text(item)
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.Colors.line, lineWidth: 1))
        .padding(.top, 16)
    }
}

/// İzin sayfasının metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
enum ConsentText {
    static var title: String { PageText.t(["Lupa ile konuşmadan önce", "Before you talk with Lupa", "Bevor du mit Lupa sprichst", "Avant de parler avec Lupa", "Antes de hablar con Lupa", "Prima di parlare con Lupa", "Прежде чем говорить с Лупой", "在和 Lupa 对话之前"]) }
    static var intro: String { PageText.t([
        "Lupa yapay zekâ ile çalışan sesli bir öğretmen. Seninle konuşabilmesi için bazı verilerin sunucumuz üzerinden üçüncü taraf yapay zekâ servislerine gönderilmesi gerekiyor.",
        "Lupa is an AI voice tutor. To talk with you, some of your data has to be sent through our server to third-party AI services.",
        "Lupa ist ein KI-Sprachtutor. Damit Lupa mit dir sprechen kann, müssen einige deiner Daten über unseren Server an KI-Dienste von Drittanbietern gesendet werden.",
        "Lupa est un tuteur vocal IA. Pour parler avec toi, certaines de tes données doivent être envoyées via notre serveur à des services d'IA tiers.",
        "Lupa es un tutor de voz con IA. Para hablar contigo, algunos de tus datos tienen que enviarse a través de nuestro servidor a servicios de IA de terceros.",
        "Lupa è un tutor vocale IA. Per parlare con te, alcuni tuoi dati devono essere inviati tramite il nostro server a servizi di IA di terze parti.",
        "Лупа — голосовой ИИ-репетитор. Чтобы разговаривать с вами, часть ваших данных нужно передать через наш сервер сторонним ИИ-сервисам.",
        "Lupa 是一位 AI 语音老师。为了和你对话，你的部分数据需要通过我们的服务器发送给第三方 AI 服务。"]) }
    static var whatTitle: String { PageText.t(["NE GÖNDERİLİR", "WHAT IS SENT", "WAS GESENDET WIRD", "CE QUI EST ENVOYÉ", "QUÉ SE ENVÍA", "COSA VIENE INVIATO", "ЧТО ПЕРЕДАЁТСЯ", "发送哪些数据"]) }
    static var whatItems: [String] { [
        PageText.t(["Sesin, yalnızca mikrofon düğmesine basılı tuttuğunda", "Your voice, only while you hold the mic button", "Deine Stimme, nur solange du die Mikrofontaste gedrückt hältst", "Ta voix, uniquement pendant que tu maintiens le bouton micro", "Tu voz, solo mientras mantienes pulsado el botón del micrófono", "La tua voce, solo mentre tieni premuto il pulsante del microfono", "Ваш голос — только пока вы удерживаете кнопку микрофона", "你的声音，仅在你按住麦克风按钮时"]),
        PageText.t(["Konuşmanın metni ve öğretmene kendinle ilgili anlattıkların", "The conversation text and what you tell the tutor about yourself", "Der Gesprächstext und was du Lupa über dich erzählst", "Le texte de la conversation et ce que tu racontes de toi au tuteur", "El texto de la conversación y lo que le cuentas al tutor sobre ti", "Il testo della conversazione e ciò che racconti di te al tutor", "Текст разговора и то, что вы рассказываете о себе", "对话文字，以及你向老师讲述的关于自己的内容"]),
        PageText.t(["Adın, ana dilin, öğrendiğin dil ve seviyen", "Your name, your native language, the language you learn and your level", "Dein Name, deine Muttersprache, die Sprache, die du lernst, und dein Niveau", "Ton prénom, ta langue maternelle, la langue que tu apprends et ton niveau", "Tu nombre, tu idioma nativo, el idioma que aprendes y tu nivel", "Il tuo nome, la tua lingua madre, la lingua che impari e il tuo livello", "Ваше имя, родной язык, изучаемый язык и уровень", "你的名字、母语、正在学习的语言和水平"]),
    ] }
    static var whoTitle: String { PageText.t(["KİME GİDER", "WHO RECEIVES IT", "WER SIE ERHÄLT", "QUI LES REÇOIT", "QUIÉN LOS RECIBE", "CHI LI RICEVE", "КТО ПОЛУЧАЕТ", "接收方"]) }
    static var who: String { PageText.t([
        "OpenAI ve Google (Gemini): konuşmanı anlayan ve Lupa'nın cevabını üreten yapay zekâ servisleri.",
        "OpenAI and Google (Gemini): the AI services that understand your speech and generate Lupa's replies.",
        "OpenAI und Google (Gemini): die KI-Dienste, die deine Sprache verstehen und Lupas Antworten erzeugen.",
        "OpenAI et Google (Gemini) : les services d'IA qui comprennent ta voix et génèrent les réponses de Lupa.",
        "OpenAI y Google (Gemini): los servicios de IA que entienden tu voz y generan las respuestas de Lupa.",
        "OpenAI e Google (Gemini): i servizi di IA che capiscono la tua voce e generano le risposte di Lupa.",
        "OpenAI и Google (Gemini): ИИ-сервисы, которые распознают вашу речь и создают ответы Лупы.",
        "OpenAI 和 Google（Gemini）：理解你的语音并生成 Lupa 回复的 AI 服务。"]) }
    static var whyTitle: String { PageText.t(["NEDEN", "WHY", "WOZU", "POURQUOI", "PARA QUÉ", "PERCHÉ", "ЗАЧЕМ", "用途"]) }
    static var why: String { PageText.t([
        "Söylediğini anlamak, sana sesli cevap vermek ve hatalarını düzeltmek için. Kayıtlarını sunucumuzda saklamayız ve veriler reklam için kullanılmaz.",
        "To understand what you say, answer you by voice and correct your mistakes. We don't store your recordings on our servers, and the data is not used for advertising.",
        "Um zu verstehen, was du sagst, dir per Stimme zu antworten und deine Fehler zu korrigieren. Wir speichern deine Aufnahmen nicht auf unseren Servern, und die Daten werden nicht für Werbung verwendet.",
        "Pour comprendre ce que tu dis, te répondre à voix haute et corriger tes erreurs. Nous ne conservons pas tes enregistrements sur nos serveurs et les données ne servent pas à la publicité.",
        "Para entender lo que dices, responderte por voz y corregir tus errores. No guardamos tus grabaciones en nuestros servidores y los datos no se usan para publicidad.",
        "Per capire cosa dici, risponderti a voce e correggere i tuoi errori. Non conserviamo le tue registrazioni sui nostri server e i dati non vengono usati per la pubblicità.",
        "Чтобы понимать, что вы говорите, отвечать голосом и исправлять ошибки. Мы не храним ваши записи на наших серверах, и данные не используются для рекламы.",
        "用于理解你说的话、用语音回答你并纠正你的错误。我们不会在服务器上保存你的录音，这些数据也不会用于广告。"]) }
    static var note: String { PageText.t(["İznini istediğin zaman Profil › Ayarlar'dan geri alabilirsin.", "You can withdraw your permission anytime in Profile › Settings.", "Du kannst deine Erlaubnis jederzeit unter Profil › Einstellungen widerrufen.", "Tu peux retirer ton autorisation à tout moment dans Profil › Réglages.", "Puedes retirar tu permiso cuando quieras en Perfil › Ajustes.", "Puoi revocare il permesso in qualsiasi momento da Profilo › Impostazioni.", "Вы можете отозвать разрешение в любой момент: Профиль › Настройки.", "你可以随时在“个人资料 › 设置”中撤回许可。"]) }
    static var privacy: String { PageText.t(["Gizlilik Politikası", "Privacy Policy", "Datenschutzerklärung", "Politique de confidentialité", "Política de privacidad", "Informativa sulla privacy", "Политика конфиденциальности", "隐私政策"]) }
    static var accept: String { PageText.t(["Kabul ediyorum, devam et", "I agree, continue", "Einverstanden, weiter", "J'accepte, continuer", "Acepto, continuar", "Accetto, continua", "Согласен, продолжить", "同意并继续"]) }
    static var decline: String { PageText.t(["Şimdi değil", "Not now", "Jetzt nicht", "Pas maintenant", "Ahora no", "Non ora", "Не сейчас", "暂不"]) }
    static var settingsTitle: String { PageText.t(["Yapay zekâ ile konuşma izni", "AI conversation permission", "Erlaubnis für KI-Gespräche", "Autorisation des conversations IA", "Permiso para conversar con la IA", "Permesso per le conversazioni IA", "Разрешение на разговоры с ИИ", "AI 对话许可"]) }
    static var settingsHint: String { PageText.t([
        "Konuşurken sesin, konuşma metni ve adın OpenAI ve Google'a gönderilir. Kapatırsan Lupa ile konuşamazsın.",
        "While you talk, your voice, the conversation text and your name are sent to OpenAI and Google. Turn it off and you can't talk with Lupa.",
        "Beim Sprechen werden deine Stimme, der Gesprächstext und dein Name an OpenAI und Google gesendet. Ohne Erlaubnis kannst du nicht mit Lupa sprechen.",
        "Pendant que tu parles, ta voix, le texte de la conversation et ton prénom sont envoyés à OpenAI et Google. Sans autorisation, tu ne peux pas parler avec Lupa.",
        "Mientras hablas, tu voz, el texto de la conversación y tu nombre se envían a OpenAI y Google. Sin permiso no puedes hablar con Lupa.",
        "Mentre parli, la tua voce, il testo della conversazione e il tuo nome vengono inviati a OpenAI e Google. Senza permesso non puoi parlare con Lupa.",
        "Во время разговора ваш голос, текст разговора и имя передаются OpenAI и Google. Без разрешения говорить с Лупой нельзя.",
        "对话时，你的声音、对话文字和名字会发送给 OpenAI 和 Google。关闭后将无法与 Lupa 对话。"]) }
}
