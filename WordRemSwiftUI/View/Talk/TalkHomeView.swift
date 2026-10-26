//
//  TalkHomeView.swift
//  WordRemSwiftUI
//
//  "Konuş" ana ekranı: üstte dil/seviye ve seri, bugünün tekrar şeridi, ortada tek ders kartı
//  ("Başla") ile "Asistanınla konuş" yana kaydırılır; altında "Planım" yol haritası.
//

import SwiftUI

struct TalkHomeView: View {
    @EnvironmentObject var langManager: LanguageManager
    @ObservedObject private var scheduler = ReviewScheduler.shared
    var onOpenLeaderboard: () -> Void
    var onOpenSettings: () -> Void = {}

    @State private var activeMode: TutorMode?
    @State private var showPlan = false
    @State private var showReview = false
    @State private var refresh = 0   // hedef tamamlanınca kartı yenile
    /// Seri artınca kutla (son görülen değer)
    @AppStorage("talk.lastSeenStreak") private var lastSeenStreak = 0
    @State private var streakCelebration = 0
    /// Yana kaydırılan kartlar: 0 = sıradaki ders, 1 = asistanla serbest sohbet
    @State private var page = 0
    @State private var showLanguages = false
    @State private var pendingSetup: String?

    private var store: ScenarioStore { ScenarioStore.shared }
    private var targetCode: String { UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN" }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 1. ekran: ders/asistan kartları
                        VStack(spacing: 26) {
                            topBar
                            if !scheduler.dueToday.isEmpty { reviewStrip }
                            pager
                            planHint { withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { proxy.scrollTo("plan", anchor: .top) } }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .frame(maxWidth: 620)
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height, alignment: .top)

                        // 2. ekran: plan, alttan gelen ayrı bir yaprak gibi (kaydırınca yerine oturur)
                        VStack(spacing: 0) {
                            Capsule().fill(DS.Colors.line).frame(width: 40, height: 5).padding(.top, 12).padding(.bottom, 18)
                            planSection
                                .padding(.horizontal, 24)
                                .frame(maxWidth: 620)
                            Spacer(minLength: 40)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height, alignment: .top)
                        .background(
                            DS.Colors.paperSunken
                                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 36, topTrailingRadius: 36))
                                .shadow(color: .black.opacity(0.06), radius: 18, y: -6)
                        )
                        .id("plan")
                    }
                    .scrollTargetLayout()
                    .id(refresh)
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
        .paperBackground()
        .onAppear { scheduler.reload(); openRoute(AppRouter.shared.route) }
        .onReceive(AppRouter.shared.$route) { openRoute($0) }
        .fullScreenCover(item: Binding(get: { activeMode.map(ModeBox.init) }, set: { activeMode = $0?.mode })) { box in
            VoiceTutorView(mode: box.mode) { ok in
                // Yeni dil kurulumu tamamlandı → öğrenilen dil değişir, plan o dilde baştan
                if ok, case .languageSetup(let code) = box.mode { LearningLanguages.switchTo(code) }
                refresh += 1
            }
        }
        // Kurulum konuşması, dil sayfası tamamen kapandıktan sonra açılır (üst üste sunum oturumu bozuyor)
        .sheet(isPresented: $showLanguages, onDismiss: {
            if let code = pendingSetup { pendingSetup = nil; activeMode = .languageSetup(code: code) }
        }) {
            LearningLanguageSheet(onSwitch: { code in
                LearningLanguages.switchTo(code)
                refresh += 1
            }, onSetup: { code in
                pendingSetup = code
            }, onSettings: onOpenSettings)
        }
        .sheet(isPresented: $showPlan) {
            TalkPlanSheet { chapter, goal in
                showPlan = false
                activeMode = .goal(chapterId: chapter.id, goalId: goal.id)
            }
        }
        #if DEBUG
        // Ekran görüntüsü/test: -DemoLessonComplete YES ile ders sonu akışını doğrudan aç
        .fullScreenCover(isPresented: .constant(UserDefaults.standard.bool(forKey: "DemoLessonComplete"))) {
            LessonCompleteView(lessonTitle: "Selamlaşma ve kendini tanıtma", learnerName: "Ahmet",
                               phrases: [.init(text: "Nice to meet you.", translation: "Tanıştığıma memnun oldum."),
                                         .init(text: "Hello, my name is Ahmet.", translation: "Merhaba, benim adım Ahmet."),
                                         .init(text: "I'm good, thank you.", translation: "İyiyim, teşekkür ederim.")],
                               mastery: 92, duration: 628) {}
        }
        #endif
        .fullScreenCover(isPresented: $showReview) {
            ReviewSessionView(words: scheduler.dueToday).environmentObject(langManager)
        }
    }

    /// Bildirimden gelen yönlendirme: yarım ders ya da tekrar oturumu
    private func openRoute(_ route: AppRouter.Route?) {
        guard let route else { return }
        switch route {
        case .tutor(let c, let g): activeMode = .goal(chapterId: c, goalId: g)
        case .review:              if !scheduler.dueToday.isEmpty { showReview = true }
        case .talk:                break
        }
        AppRouter.shared.route = nil
    }

    // MARK: - Top bar: dil + seviye · seri · sıralama
    private var topBar: some View {
        let s = UserStore.shared.snapshot
        let streak = StudyStreak.current
        let lang = ContentStore.shared.language(code: targetCode)
        return HStack(spacing: 10) {
            // Pingo gibi: dile dokununca öğrenilen diller / yeni dil ekleme
            Button { showLanguages = true } label: {
                HStack(spacing: 8) {
                    Text(lang?.flagEmoji ?? LearningLanguages.flags[targetCode.lowercased()] ?? "🌐").font(.system(size: 22))
                    Text("L\(LearningLanguages.level(targetCode.lowercased()))")
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(DS.Colors.paperSunken, in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onOpenLeaderboard) {
                Image(systemName: "trophy")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.paperSunken, in: Circle())
            }
            .accessibilityLabel(AL.s(.tabRank))

            HStack(spacing: 6) {
                Text("\(streak)")
                    .font(DS.Font.ui(15, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .contentTransition(.numericText(value: Double(streak)))
                LiveFlame(size: 16)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(DS.Colors.paperSunken, in: Capsule())
            .scaleEffect(streakCelebration > 0 ? 1.0 : 1.0)
            .phaseAnimator([1.0, 1.25, 1.0], trigger: streakCelebration) { v, scale in v.scaleEffect(scale) }
            .overlay(ConfettiBurst(origin: .center, count: 40, trigger: streakCelebration)
                        .frame(width: 220, height: 220).allowsHitTesting(false)
                        .opacity(streakCelebration > 0 ? 1 : 0))
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
    }

    // MARK: - Tekrar şeridi (dersler ↔ sohbet köprüsü)
    private var reviewStrip: some View {
        Button { showReview = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Colors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(AL.f(.talkReviewsDue, scheduler.dueToday.count))
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    Text(AL.s(.talkReviewHint))
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                }
                Spacer()
                Text(AL.s(.talkReviewNow))
                    .font(DS.Font.ui(14, weight: .semibold))
                    .foregroundStyle(DS.Colors.accent)
            }
            .padding(16)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.line))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sahneler (kutu yok: logo, başlık ve Başla doğrudan zeminde)
    @ViewBuilder
    private var lessonCard: some View {
        if let next = store.next {
            stage(phase: .connecting, kicker: next.chapter.localizedTitle, title: next.goal.localizedTitle) {
                activeMode = .goal(chapterId: next.chapter.id, goalId: next.goal.id)
            }
        }
    }

    /// Asistanla dolu dolu serbest sohbet
    private var assistantCard: some View {
        stage(phase: .connecting, kicker: AL.s(.talkAssistantKicker), title: AL.s(.talkAssistantTitle)) {
            activeMode = .freeChat
        }
    }

    private func stage(phase: RealtimeVoiceSession.Phase, kicker: String, title: String, start: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                // Yumuşak ışık hâlesi + canlı logo
                Circle()
                    .fill(RadialGradient(colors: [DS.Colors.accent.opacity(0.16), DS.Colors.accent.opacity(0)],
                                         center: .center, startRadius: 10, endRadius: 140))
                    .frame(width: 280, height: 280)
                VoiceLogoView(phase: phase, level: 0.45)
                    .scaleEffect(2.6)
            }
            .frame(height: 200)
            Spacer(minLength: 12)
            Text(kicker.uppercased(with: Locale(identifier: LanguageManager.shared.currentLanguageCode)))
                .font(DS.Font.ui(13, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(DS.Colors.accent)
                .padding(.bottom, 10)
            Text(title)
                .font(DS.Font.display(38, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
            Button(AL.s(.talkStart), action: start)
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                .frame(maxWidth: 260)
                .padding(.top, 28)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    // MARK: - Yana kaydırılan kartlar (Pingo gibi)
    private var pager: some View {
        VStack(spacing: 14) {
            TabView(selection: $page) {
                lessonCard.padding(.horizontal, 2).tag(0)
                assistantCard.padding(.horizontal, 2).tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(minHeight: 420, maxHeight: .infinity)
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { i in
                    Capsule()
                        .fill(page == i ? DS.Colors.accent : DS.Colors.line)
                        .frame(width: page == i ? 18 : 7, height: 7)
                }
            }
            .animation(.spring(response: 0.3), value: page)
        }
    }

    /// İlk ekranın altında: "Planım" ve aşağı ok (dokununca plana kayar)
    private func planHint(_ go: @escaping () -> Void) -> some View {
        Button(action: go) {
            VStack(spacing: 4) {
                Text(AL.s(.talkPlan))
                    .font(DS.Font.ui(15, weight: .semibold))
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 22, weight: .medium))
                    .symbolEffect(.pulse)
            }
            .foregroundStyle(DS.Colors.accent)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plan: bulunduğun bölüm, hedefler dalgalı bir yol üzerinde
    @ViewBuilder
    private var planSection: some View {
        if let next = store.next {
            let chapter = next.chapter
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: chapter.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(DS.Colors.accent)
                        .frame(width: 52, height: 52)
                        .background(DS.Colors.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AL.s(.talkInProgress))
                            .font(DS.Font.ui(13, weight: .medium))
                            .foregroundStyle(DS.Colors.muted)
                        Text(chapter.localizedTitle)
                            .font(DS.Font.display(24, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .lineLimit(2)
                    }
                }
                PlanPathView(goals: chapter.goals, currentId: next.goal.id, isDone: store.isDone) { goal in
                    activeMode = .goal(chapterId: chapter.id, goalId: goal.id)
                }
                Button { showPlan = true } label: {
                    HStack {
                        if let i = store.chapters.firstIndex(where: { $0.id == chapter.id }), i + 1 < store.chapters.count {
                            Text(AL.f(.talkNextChapter, store.chapters[i + 1].localizedTitle))
                        } else {
                            Text(AL.s(.talkSeeFullPlan))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(DS.Font.ui(14, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(DS.Colors.paperSunken.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    .contentShape(Rectangle())   // satırın tamamı dokunulabilir
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 30))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(DS.Colors.line))
        }
    }
}

/// fullScreenCover(item:) için Identifiable sarmalayıcı
private struct ModeBox: Identifiable {
    let mode: TutorMode
    var id: String { String(describing: mode) }
}

// MARK: - Planım: bölüm haritası (bulunduğun bölüm + sonraki ikisi; çok ilerisi gösterilmez)
struct TalkPlanSheet: View {
    var onStart: (VoiceChapter, VoiceGoal) -> Void
    @Environment(\.dismiss) private var dismiss
    private var store: ScenarioStore { ScenarioStore.shared }

    var body: some View {
        let chapters = store.chapters
        let currentChapter = store.next?.chapter.id
        let ci = chapters.firstIndex { $0.id == currentChapter } ?? 0
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    ForEach(Array(chapters.enumerated()).filter { $0.offset <= ci + 2 }, id: \.element.id) { i, chapter in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: i > ci ? "lock.fill" : chapter.icon)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(i > ci ? DS.Colors.muted : DS.Colors.accent)
                                    .frame(width: 44, height: 44)
                                    .background(i > ci ? DS.Colors.paperSunken : DS.Colors.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(chapter.localizedTitle)
                                        .font(DS.Font.display(21, weight: .semibold))
                                        .foregroundStyle(i > ci ? DS.Colors.inkSoft : DS.Colors.ink)
                                    Text(chapter.localizedSubtitle)
                                        .font(DS.Font.ui(13))
                                        .foregroundStyle(DS.Colors.muted)
                                }
                            }
                            PlanPathView(goals: chapter.goals, currentId: i == ci ? store.next?.goal.id ?? "" : "",
                                         isDone: store.isDone, lockedChapter: i > ci) { goal in
                                onStart(chapter, goal)
                            }
                        }
                        .opacity(i > ci ? 0.85 : 1)
                    }
                    // Daha ilerisi: yalnızca adlar, giderek silikleşir; yol noktalı devam edip kaybolur (bitmeyen yolculuk)
                    let later = Array(chapters.dropFirst(ci + 3))
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(later.enumerated()), id: \.element.id) { j, chapter in
                            HStack(spacing: 14) {
                                Circle().stroke(DS.Colors.line, lineWidth: 2.5).frame(width: 18, height: 18)
                                    .frame(width: 60)
                                Text(chapter.localizedTitle)
                                    .font(DS.Font.ui(16, weight: .medium))
                                    .foregroundStyle(DS.Colors.inkSoft)
                                Spacer()
                                Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(DS.Colors.muted)
                            }
                            .frame(height: 52)
                            .opacity(max(0.25, 0.8 - Double(j) * 0.18))
                        }
                        ForEach(0..<5, id: \.self) { k in
                            Circle().fill(DS.Colors.line)
                                .frame(width: 5, height: 5)
                                .frame(width: 60, height: 14)
                                .opacity(0.9 - Double(k) * 0.18)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text(AL.s(.talkMoreComing))
                        }
                        .font(DS.Font.ui(14, weight: .medium))
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.top, 10)
                        .padding(.leading, 18)
                    }
                }
                .padding(24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .paperBackground()
            .navigationTitle(AL.s(.talkPlan))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }
}

// MARK: - Dalgalı plan yolu
/// Solda hafif dalgalanan bir yol: tamamlanan kısım dolu, kalan kısım noktalı; hedef kartları sağda.
struct PlanPathView: View {
    let goals: [VoiceGoal]
    let currentId: String
    let isDone: (VoiceGoal) -> Bool
    /// Henüz açılmamış bölüm: tüm hedefler kilitli
    var lockedChapter = false
    var onTap: (VoiceGoal) -> Void

    private let rowH: CGFloat = 86
    private let lane: CGFloat = 30           // yolun orta çizgisi (x)
    private let sway: CGFloat = 10           // dalga genliği

    private var currentIndex: Int { lockedChapter ? -1 : goals.firstIndex { $0.id == currentId } ?? goals.count }
    private func x(_ i: Int) -> CGFloat { lane + (i % 2 == 0 ? -sway : sway) }
    private func y(_ i: Int) -> CGFloat { rowH * CGFloat(i) + rowH / 2 }

    var body: some View {
        let progress = goals.count > 1 ? CGFloat(max(0, min(currentIndex, goals.count - 1))) / CGFloat(goals.count - 1) : 0
        ZStack(alignment: .topLeading) {
            WavyLane(points: goals.indices.map { CGPoint(x: x($0), y: y($0)) })
                .trim(from: progress, to: 1)
                .stroke(DS.Colors.line, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 8]))
            WavyLane(points: goals.indices.map { CGPoint(x: x($0), y: y($0)) })
                .trim(from: 0, to: progress)
                .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            ForEach(Array(goals.enumerated()), id: \.element.id) { i, goal in
                node(i, goal).position(x: x(i), y: y(i))
                row(i, goal)
                    .padding(.leading, lane + sway + 26)
                    .frame(height: rowH)
                    .offset(y: rowH * CGFloat(i))
            }
        }
        .frame(height: rowH * CGFloat(goals.count))
    }

    @ViewBuilder
    private func node(_ i: Int, _ goal: VoiceGoal) -> some View {
        if isDone(goal) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DS.Colors.paper)
                .frame(width: 26, height: 26)
                .background(DS.Colors.accent, in: Circle())
        } else if i == currentIndex {
            Circle()
                .fill(DS.Colors.accent)
                .frame(width: 14, height: 14)
                .padding(6)
                .background(DS.Colors.accent.opacity(0.18), in: Circle())
                .overlay(Circle().stroke(DS.Colors.accent.opacity(0.35), lineWidth: 1).scaleEffect(1.35))
        } else {
            Circle()
                .stroke(DS.Colors.line, lineWidth: 2.5)
                .background(Circle().fill(DS.Colors.paperRaised))
                .frame(width: 18, height: 18)
        }
    }

    private func row(_ i: Int, _ goal: VoiceGoal) -> some View {
        let current = i == currentIndex
        let done = isDone(goal)
        // Adım adım: yalnızca tamamlanan ve sıradaki hedef açılır
        let locked = !done && !current
        return Button { onTap(goal) } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(AL.s(.talkGoal))
                        .font(DS.Font.ui(11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(current ? DS.Colors.accent : DS.Colors.muted)
                    Text(goal.localizedTitle)
                        .font(DS.Font.ui(16, weight: current ? .semibold : .medium))
                        .foregroundStyle(done || current ? DS.Colors.ink : DS.Colors.inkSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.muted.opacity(0.7))
                } else if current {
                    Text(AL.s(.talkStart))
                        .font(DS.Font.ui(13, weight: .semibold))
                        .foregroundStyle(DS.Colors.paper)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(DS.Colors.accent, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(current ? DS.Colors.accent.opacity(0.07) : DS.Colors.paperSunken.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(current ? DS.Colors.accent.opacity(0.35) : .clear))
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .opacity(locked ? 0.75 : 1)
    }
}

/// Noktaları yumuşak S eğrileriyle bağlayan dikey yol
private struct WavyLane: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        for (a, b) in zip(points, points.dropFirst()) {
            let midY = (a.y + b.y) / 2
            p.addCurve(to: b, control1: CGPoint(x: a.x, y: midY), control2: CGPoint(x: b.x, y: midY))
        }
        return p
    }
}
