//
//  TalkHomeView.swift
//  WordRemSwiftUI
//
//  "Konuş" ana ekranı: üstte dil defteri ve seri, ortada "bugünün sayfası" (tekrar satırı, günün dersi,
//  boş sayfa); aşağı kaydırınca içindekiler.
//

import SwiftUI

struct TalkHomeView: View {
    @EnvironmentObject var langManager: LanguageManager
    @ObservedObject private var scheduler = ReviewScheduler.shared
    var onOpenLeaderboard: () -> Void

    @State private var activeMode: TutorMode?
    @State private var showPlan = false
    @State private var showReview = false
    @State private var refresh = 0   // hedef tamamlanınca kartı yenile
    /// Seri artınca kutla (son görülen değer)

    private var store: ScenarioStore { ScenarioStore.shared }
    private var targetCode: String { UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN" }

    var body: some View {
        // Bugünün sayfası, aşağısında içindekiler yaprağı. Serbest ve akıcı kaydırma: aşağı indikçe
        // bugünün sayfası hafifçe küçülüp geride kalır, içindekiler yaprağı üstüne gelir.
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 12) {
                            AppHeader(onOpenLeaderboard: onOpenLeaderboard, onSwitched: { refresh += 1 })
                                .padding(.horizontal, 20)
                            todayPage {
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) { proxy.scrollTo("plan", anchor: .top) }
                            }
                            .padding(.horizontal, 12)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 14)
                        .frame(maxWidth: 620)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(560, geo.size.height - 22), alignment: .top)
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content
                                .scaleEffect(phase.value < 0 ? 1 + phase.value * 0.06 : 1, anchor: .top)
                                .opacity(phase.value < 0 ? 1 + phase.value * 0.5 : 1)
                        }

                        // İçindekiler yaprağı: bugünün sayfasının üstüne kayar
                        VStack(spacing: 0) {
                            Capsule().fill(DS.Colors.line).frame(width: 40, height: 5).padding(.top, 10).padding(.bottom, 6)
                            ContentsView { chapter, goal in
                                activeMode = .goal(chapterId: chapter.id, goalId: goal.id)
                            }
                            .frame(maxWidth: 620)
                            Spacer(minLength: 40)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height, alignment: .top)
                        .background(
                            DS.Colors.paperRaised
                                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
                                .shadow(color: .black.opacity(0.08), radius: 18, y: -6)
                        )
                        .id("plan")
                    }
                    .id(refresh)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        // Kaydırınca yazılar saat/pil satırının altına girip okunmaz olmasın
        .overlay(alignment: .top) {
            DS.Colors.paper.frame(height: 0).ignoresSafeArea(edges: .top)
        }
        .paperBackground()
        .onAppear { scheduler.reload(); openRoute(AppRouter.shared.route) }
        .onReceive(AppRouter.shared.$route) { openRoute($0) }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: DebugDriver.open)) { n in
            let arg = (n.object as? String ?? "").split(separator: " ").map(String.init)
            switch arg.first {
            case "freechat": activeMode = .freeChat
            case "demo": activeMode = .demo
            case "goal" where arg.count > 1:
                let ids = arg[1].split(separator: "/").map(String.init)
                if ids.count == 2 { activeMode = .goal(chapterId: ids[0], goalId: ids[1]) }
            default: break
            }
        }
        #endif
        // Dersten çıkınca sayfa yenilenir: yarım kalan ders "Devam et" olarak görünür
        .fullScreenCover(item: Binding(get: { activeMode.map(ModeBox.init) }, set: { activeMode = $0?.mode }),
                         onDismiss: { refresh += 1 }) { box in
            VoiceTutorView(mode: box.mode) { ok in
                // Yeni dil kurulumu tamamlandı → öğrenilen dil değişir, plan o dilde baştan
                if case .languageSetup(let code) = box.mode {
                    let from = LearningLanguages.current
                    if ok { LearningLanguages.switchTo(code) }
                    Track.language(ok ? "add_complete" : "add_abandon", from: from, to: code, entryPoint: "learning_sheet")
                }
                refresh += 1
            }
        }
        .sheet(isPresented: $showPlan) {
            TalkPlanSheet { chapter, goal in
                showPlan = false
                activeMode = .goal(chapterId: chapter.id, goalId: goal.id)
            }
        }
        #if DEBUG
        // Mağaza görselleri: -DemoStage lesson → hazır ders sayfası, plan → içindekiler
        .fullScreenCover(isPresented: .constant(DemoData.stage == "lesson")) {
            if let ch = ScenarioStore.shared.chapters.first, ch.goals.count > 2 {
                VoiceTutorView(mode: .goal(chapterId: ch.id, goalId: ch.goals[2].id))
            }
        }
        .sheet(isPresented: .constant(DemoData.stage == "plan")) {
            TalkPlanSheet { _, _ in }
        }
        // Ekran görüntüsü/test: -DemoLessonComplete YES ile ders sonu akışını doğrudan aç
        .fullScreenCover(isPresented: .constant(UserDefaults.standard.bool(forKey: "DemoLessonComplete"))) {
            let demo = DemoData.lessonCompletePreview
            LessonCompleteView(lessonTitle: demo.title, learnerName: "Ahmet",
                               phrases: demo.phrases.map { .init(text: $0.0, translation: $0.1) },
                               mastery: 92, duration: 628) {}
        }
        #endif
        .fullScreenCover(isPresented: $showReview) {
            ReviewSessionView(words: scheduler.dueToday).environmentObject(langManager)
        }
    }

    /// Bildirimden gelen yönlendirme: yarım ders ya da tekrar oturumu
    private func openRoute(_ route: AppRouter.Route?) {
        guard let route, route != .paywall else { return }   // ödeme ekranını ana sekme açar
        switch route {
        case .tutor(let c, let g): activeMode = .goal(chapterId: c, goalId: g)
        case .review:              if !scheduler.dueToday.isEmpty { showReview = true }
        case .lupa(let q):
            TutorBrain.chatOpener = LupaShared.question(q, lang: LearningLanguages.current)
            activeMode = .freeChat
        case .languageSetup(let code): activeMode = .languageSetup(code: code)
        case .talk, .paywall:      break
        }
        AppRouter.shared.route = nil
    }

    // MARK: - Bugünün sayfası: tarih, tekrar satırı, günün dersi, boş sayfa, içindekiler
    private func todayPage(_ openContents: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: HomeText.todayPage, color: DS.Colors.accentText)
                Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: OL.nativeLangCode))))
                    .font(.system(size: 16, design: .serif).italic())
                    .foregroundStyle(DS.Colors.muted)
            }
            .padding(.top, 24)

            if !scheduler.dueToday.isEmpty { reviewRow.padding(.top, 18) }

            Spacer(minLength: 16)
            lessonBlock
            Spacer(minLength: 16)

            Button { activeMode = .freeChat } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(PageText.blankPage)
                            .font(DS.Font.display(18, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                        Text(HomeText.blankPageSub)
                            .font(DS.Font.ui(13))
                            .foregroundStyle(DS.Colors.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
                .frame(minHeight: 64)
                .overlay(alignment: .top) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: openContents) {
                Label(HomeText.contents, systemImage: "list.bullet")
                    .font(DS.Font.ui(14, weight: .semibold))
                    .foregroundStyle(DS.Colors.accentText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
        .padding(.leading, 66 - 12)
        .padding(.trailing, 18)
        .padding(.leading, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DS.Colors.paperRaised, in: UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6,
                                                                      bottomTrailingRadius: 18, topTrailingRadius: 18))
        .overlay(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6, bottomTrailingRadius: 18, topTrailingRadius: 18)
            .stroke(DS.Colors.line))
        .overlay(alignment: .leading) {
            Rectangle().fill(DS.Colors.margin).frame(width: 1.5).padding(.leading, 52)
        }
        .overlay(alignment: .topTrailing) {
            BookmarkMark(width: 12).padding(.trailing, 22)
        }
    }

    // MARK: - Tekrar satırı (dersler ↔ sohbet köprüsü)
    private var reviewRow: some View {
        Button { showReview = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.accentText)
                Text(AL.f(.talkReviewsDue, scheduler.dueToday.count))
                    .font(DS.Font.ui(14, weight: .medium))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 6)
                Text(AL.s(.talkReviewNow))
                    .font(DS.Font.ui(14, weight: .semibold))
                    .foregroundStyle(DS.Colors.accentText)
            }
            .frame(minHeight: 54)
            .overlay(alignment: .top) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Günün dersi (bitti ise serbest sohbet)
    @ViewBuilder
    private var lessonBlock: some View {
        if let next = store.next {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "\(next.chapter.localizedTitle) · \(PageText.page(store.pageNumber(of: next.goal)))", color: DS.Colors.muted)
                    .lineLimit(1)
                Text(next.goal.localizedTitle)
                    .font(DS.Font.display(36, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                let mode = TutorMode.goal(chapterId: next.chapter.id, goalId: next.goal.id)
                // Yarım kalan ders: Lupa'nın son sözü kenar notu gibi, düğme "Devam et"
                if let page = TutorBrain.savedPage(for: mode),
                   let last = page.turns.last(where: { $0.role == .ai })?.text {
                    (Text("“\(last)” ")
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundColor(DS.Colors.inkSoft)
                     + Text("— Lupa").font(.system(size: 14, design: .serif).italic()).foregroundColor(DS.Colors.accentText))
                        .lineLimit(3)
                        .padding(.top, 12)
                } else if !next.chapter.localizedSubtitle.isEmpty {
                    Text(next.chapter.localizedSubtitle)
                        .font(.system(size: 17, design: .serif).italic())
                        .foregroundStyle(DS.Colors.inkSoft)
                        .padding(.top, 12)
                }
                Button { activeMode = mode } label: {
                    Label(TutorBrain.savedPage(for: mode) != nil ? PageText.continueLesson : HomeText.startLesson,
                          systemImage: "mic")
                }
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                .padding(.top, 24)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: PageText.freeChat, color: DS.Colors.muted)
                Text(AL.s(.talkAssistantTitle))
                    .font(DS.Font.display(36, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .padding(.top, 10)
                Text(AL.s(.talkMoreComing))
                    .font(.system(size: 17, design: .serif).italic())
                    .foregroundStyle(DS.Colors.inkSoft)
                    .padding(.top, 12)
                Button { activeMode = .freeChat } label: { Label(AL.s(.talkStart), systemImage: "mic") }
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                    .padding(.top, 24)
            }
        }
    }
}

/// fullScreenCover(item:) için Identifiable sarmalayıcı
private struct ModeBox: Identifiable {
    let mode: TutorMode
    var id: String { String(describing: mode) }
}

// MARK: - Planım: tüm içindekiler (sayfa)
struct TalkPlanSheet: View {
    var onStart: (VoiceChapter, VoiceGoal) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ContentsView(onStart: onStart).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
            .background(DS.Colors.paperRaised.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }
}

// MARK: - İçindekiler
/// Kitap içindekiler sayfası: bulunduğun bölüm açık (hedefler noktalı satırlarla, sayfa numaralı,
/// kaldığın yerde terrakota ayraç), sonraki iki bölüm yalnızca başlık, daha ilerisi silikleşir.
struct ContentsView: View {
    var onStart: (VoiceChapter, VoiceGoal) -> Void
    private var store: ScenarioStore { ScenarioStore.shared }

    var body: some View {
        let chapters = store.chapters
        let ci = chapters.firstIndex { $0.id == store.next?.chapter.id } ?? max(0, chapters.count - 1)
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(HomeText.contents)
                    .font(DS.Font.display(34, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                Text(HomeText.notebookOf(OL.languageName(for: LearningLanguages.current.lowercased())
                        .capitalized(with: Locale(identifier: OL.nativeLangCode)),
                     level: LearningLanguages.level(LearningLanguages.current.lowercased())))
                    .font(.system(size: 16, design: .serif).italic())
                    .foregroundStyle(DS.Colors.muted)
            }
            .padding(.leading, 66)
            .padding(.top, 20)
            .padding(.bottom, 22)

            ForEach(Array(chapters.enumerated()).filter { $0.offset <= ci + 2 }, id: \.element.id) { i, chapter in
                if i == ci {
                    chapterOpen(i, chapter)
                } else {
                    chapterLine(i, chapter, done: i < ci)
                }
            }
            if chapters.count > ci + 3 {
                ForEach(Array(chapters.dropFirst(ci + 3).prefix(3).enumerated()), id: \.element.id) { j, chapter in
                    chapterLine(ci + 3 + j, chapter, done: false)
                        .opacity(max(0.25, 0.7 - Double(j) * 0.2))
                }
            }
            Text(AL.s(.talkMoreComing))
                .font(.system(size: 15, design: .serif).italic())
                .foregroundStyle(DS.Colors.muted)
                .padding(.leading, 66)
                .padding(.top, 26)
        }
        .padding(.trailing, 22)
        .padding(.bottom, 24)
        .background(alignment: .leading) {
            Rectangle().fill(DS.Colors.margin).frame(width: 1.5).padding(.leading, 52)
        }
    }

    /// Bulunduğun bölüm: başlık + hedef satırları
    private func chapterOpen(_ i: Int, _ chapter: VoiceChapter) -> some View {
        let currentId = store.next?.goal.id
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(i + 1)")
                    .font(DS.Font.display(22, weight: .bold))
                    .foregroundStyle(DS.Colors.accentText)
                    .frame(width: 66 - 22, alignment: .center)
                Text(chapter.localizedTitle)
                    .font(DS.Font.display(21, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
            }
            .padding(.leading, 22)
            if !chapter.localizedSubtitle.isEmpty {
                Text(chapter.localizedSubtitle)
                    .font(DS.Font.ui(13))
                    .foregroundStyle(DS.Colors.muted)
                    .padding(.leading, 66)
                    .padding(.top, 2)
            }
            VStack(spacing: 0) {
                ForEach(Array(chapter.goals.enumerated()), id: \.element.id) { g, goal in
                    goalLine(i, g, chapter, goal, current: goal.id == currentId)
                }
            }
            .padding(.top, 12)
        }
        .padding(.bottom, 22)
    }

    private func goalLine(_ c: Int, _ g: Int, _ chapter: VoiceChapter, _ goal: VoiceGoal, current: Bool) -> some View {
        let done = store.isDone(goal)
        let locked = !done && !current
        return Button { onStart(chapter, goal) } label: {
            HStack(alignment: .center, spacing: 8) {
                Text("\(c + 1).\(g + 1)  \(goal.localizedTitle)")
                    .font(DS.Font.display(current ? 18 : 17, weight: current ? .bold : .regular))
                    .foregroundStyle(locked ? Color(hex: "#9A9286") : done ? DS.Colors.muted : DS.Colors.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .layoutPriority(1)
                if current {
                    Spacer(minLength: 8)
                    Text(TutorBrain.savedPage(for: .goal(chapterId: chapter.id, goalId: goal.id)) != nil
                         ? PageText.continueLesson : AL.s(.talkStart))
                        .font(DS.Font.ui(14, weight: .semibold))
                        .foregroundStyle(DS.Colors.paperRaised)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(DS.Colors.accent, in: RoundedRectangle(cornerRadius: 10))
                } else {
                    DottedLeader(color: Color(hex: "#D3CBBE"))
                    Text("\(store.pageNumber(of: goal))")
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                }
            }
            .padding(.leading, 66)
            .padding(.trailing, current ? 12 : 0)
            .frame(minHeight: current ? 58 : 46)
            .background(current ? DS.Colors.note : .clear)
            .overlay(alignment: .leading) {
                if done {
                    PenTick()
                        .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .frame(width: 20, height: 18)
                        .padding(.leading, 20)
                } else if current {
                    RibbonShape().fill(DS.Colors.accent)
                        .frame(width: 16, height: 44)
                        .padding(.leading, 18)
                        .offset(y: -6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityAddTraits(current ? .isSelected : [])
    }

    /// Kapalı bölüm satırı: numara · ad ....... sayfa
    private func chapterLine(_ i: Int, _ chapter: VoiceChapter, done: Bool) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(chapter.localizedTitle)
                .font(DS.Font.display(19, weight: .semibold))
                .lineLimit(1)
            DottedLeader(color: Color(hex: "#D3CBBE"))
            Text("\(chapter.goals.first.map { store.pageNumber(of: $0) } ?? 0)")
                .font(.system(size: 16, design: .serif).italic())
        }
        .foregroundStyle(DS.Colors.muted)
        .padding(.leading, 66)
        .overlay(alignment: .leading) {
            Text("\(i + 1)")
                .font(DS.Font.display(20, weight: .bold))
                .foregroundStyle(DS.Colors.muted)
                .frame(width: 44)
                .padding(.leading, 22)
        }
        .frame(minHeight: 44)
    }
}

/// Ana sayfanın defter metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
enum HomeText {
    static var todayPage: String { PageText.t(["Bugünün sayfası", "Today's page", "Heutige Seite", "Page du jour", "Página de hoy", "Pagina di oggi", "Страница дня", "今日一页"]) }
    static var contents: String { PageText.t(["İçindekiler", "Contents", "Inhalt", "Sommaire", "Índice", "Indice", "Содержание", "目录"]) }
    static var startLesson: String { PageText.t(["Derse başla", "Start lesson", "Lektion starten", "Commencer", "Empezar lección", "Inizia lezione", "Начать урок", "开始上课"]) }
    static var blankPageSub: String { PageText.t(["Lupa ile istediğin konuda konuş", "Talk with Lupa about anything", "Sprich mit Lupa über alles", "Parle de tout avec Lupa", "Habla con Lupa de lo que quieras", "Parla con Lupa di ciò che vuoi", "Говори с Лупой о чём угодно", "和 Lupa 随便聊聊"]) }
    static func level(_ n: Int) -> String { PageText.t(["Sv. \(n)", "Lv. \(n)", "Nv. \(n)", "Nv. \(n)", "Nv. \(n)", "Lv. \(n)", "Ур. \(n)", "\(n) 级"]) }
    static func notebookOf(_ language: String, level n: Int) -> String {
        PageText.t(["\(language) defteri · Seviye \(n)", "\(language) notebook · Level \(n)", "\(language)heft · Niveau \(n)",
                    "Carnet de \(language) · Niveau \(n)", "Cuaderno de \(language) · Nivel \(n)", "Quaderno di \(language) · Livello \(n)",
                    "Тетрадь: \(language) · Уровень \(n)", "\(language)笔记本 · \(n) 级"])
    }
}

extension ScenarioStore {
    /// Hedefin defterdeki sayfa numarası: önceki bölümlerin hedefleri + sırası
    func pageNumber(of goal: VoiceGoal) -> Int {
        var n = 0
        for chapter in chapters {
            if let i = chapter.goals.firstIndex(where: { $0.id == goal.id }) { return n + i + 1 }
            n += chapter.goals.count
        }
        return n
    }
}

// MARK: - Uygulamanın ortak üst satırı (Konuş, Defterlerim, Profil): dil defteri + seviye · sıralama · seri
struct AppHeader: View {
    var onOpenLeaderboard: () -> Void
    /// Dil değiştiğinde sayfa yenilensin
    var onSwitched: () -> Void = {}

    @AppStorage("talk.lastSeenStreak") private var lastSeenStreak = 0
    @State private var streakCelebration = 0
    @State private var showLanguages = false
    @State private var pendingSetup: String?

    var body: some View {
        let streak = StudyStreak.current
        let code = LearningLanguages.current
        return HStack(spacing: 6) {
            // Dile dokununca defterlerim: öğrenilen diller / yeni dil ekleme
            Button { showLanguages = true } label: {
                HStack(spacing: 8) {
                    Text(code.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(DS.Colors.paperRaised)
                        .frame(width: 22, height: 28)
                        .background(DS.Colors.slate, in: UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 3,
                                                                                  bottomTrailingRadius: 5, topTrailingRadius: 5))
                    Text(OL.languageName(for: code).capitalized(with: Locale(identifier: OL.nativeLangCode)))
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    Text("· \(HomeText.level(LearningLanguages.level(code)))")
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.muted)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onOpenLeaderboard) {
                Image(systemName: "trophy")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(AL.s(.tabRank))

            HStack(spacing: 7) {
                TallyMarks(count: 5, color: DS.Colors.accent, accentLast: nil, height: 15)
                Text("\(streak)")
                    .font(DS.Font.ui(15, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .contentTransition(.numericText(value: Double(streak)))
            }
            .frame(height: 44)
            .phaseAnimator([1.0, 1.25, 1.0], trigger: streakCelebration) { v, scale in v.scaleEffect(scale) }
            .accessibilityElement(children: .combine)
            .onAppear {
                // Seri arttıysa kutla
                if streak > lastSeenStreak, lastSeenStreak > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        Haptics.success()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { streakCelebration += 1 }
                    }
                }
                lastSeenStreak = streak
            }
        }
        // Kurulum konuşması, dil sayfası tamamen kapandıktan sonra Konuş sekmesinde açılır
        .onChange(of: showLanguages) { open in
            if open { Track.language("sheet_open", from: LearningLanguages.current); Track.screen("learning_sheet") }
        }
        .sheet(isPresented: $showLanguages, onDismiss: {
            if let code = pendingSetup { pendingSetup = nil; AppRouter.shared.route = .languageSetup(code: code) }
        }) {
            LearningLanguageSheet(onSwitch: { code in
                Track.language("switch", from: LearningLanguages.current, to: code, entryPoint: "learning_sheet")
                LearningLanguages.switchTo(code)
                onSwitched()
            }, onSetup: { code in
                Track.language("add_start", from: LearningLanguages.current, to: code, entryPoint: "learning_sheet")
                pendingSetup = code
            })
        }
    }
}
