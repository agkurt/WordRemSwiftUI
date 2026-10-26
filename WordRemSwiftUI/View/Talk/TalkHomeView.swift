//
//  TalkHomeView.swift
//  WordRemSwiftUI
//
//  "Konuş" ana ekranı: üstte dil/seviye ve seri, bugünün tekrar şeridi, ortada tek ders kartı
//  ("Başla"), altında serbest sohbet modları ve "Planım" yol haritası.
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

    private var store: ScenarioStore { ScenarioStore.shared }
    private var targetCode: String { UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN" }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                topBar
                if !scheduler.dueToday.isEmpty { reviewStrip }
                lessonCard
                modes
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .id(refresh)
        }
        .paperBackground()
        .onAppear { scheduler.reload(); openRoute(AppRouter.shared.route) }
        .onReceive(AppRouter.shared.$route) { openRoute($0) }
        .fullScreenCover(item: Binding(get: { activeMode.map(ModeBox.init) }, set: { activeMode = $0?.mode })) { box in
            VoiceTutorView(mode: box.mode) { _ in refresh += 1 }
        }
        .sheet(isPresented: $showPlan) { TalkPlanSheet() }
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
        let lang = ContentStore.shared.language(code: targetCode)
        let goalsDone = s.voiceGoalsDone?.count ?? 0
        return HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(lang?.flagEmoji ?? "🌐").font(.system(size: 22))
                Text("L\(1 + goalsDone / 5)")
                    .font(DS.Font.ui(15, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(DS.Colors.paperSunken, in: Capsule())

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
                Text("\(s.streakDays)")
                    .font(DS.Font.ui(15, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                Image(systemName: "flame.fill").foregroundStyle(DS.Colors.accent)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(DS.Colors.paperSunken, in: Capsule())
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

    // MARK: - Ders kartı
    @ViewBuilder
    private var lessonCard: some View {
        if let next = store.next {
            VStack(spacing: 18) {
                VoiceLogoView(phase: .aiSpeaking, level: 0.4)
                    .scaleEffect(1.8)
                    .frame(height: 90)
                Text(next.chapter.localizedTitle)
                    .font(DS.Font.ui(15, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
                Text(next.goal.localizedTitle)
                    .font(DS.Font.display(34, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(AL.s(.talkStart)) {
                    activeMode = .goal(chapterId: next.chapter.id, goalId: next.goal.id)
                }
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                .frame(maxWidth: 240)
                Button { showPlan = true } label: {
                    Label(AL.s(.talkPlan), systemImage: "map")
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(DS.Colors.line))
        }
    }

    // MARK: - Serbest modlar
    private var modes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AL.s(.talkWhatToPractice))
                .font(DS.Font.display(22, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                modeTile(AL.s(.talkModeRoleplay), "theatermasks", .roleplay)
                modeTile(AL.s(.talkModeNewPhrases), "text.quote", .newPhrases)
                modeTile(AL.s(.talkModeQuestion), "questionmark.bubble", .quickQuestion)
                modeTile(AL.s(.talkModeMyDay), "sun.max", .myDay)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func modeTile(_ title: String, _ icon: String, _ mode: TutorMode) -> some View {
        Button { activeMode = mode } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DS.Colors.accent)
                Text(title)
                    .font(DS.Font.ui(15, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
            .padding(16)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.line))
        }
        .buttonStyle(.plain)
    }
}

/// fullScreenCover(item:) için Identifiable sarmalayıcı
private struct ModeBox: Identifiable {
    let mode: TutorMode
    var id: String { String(describing: mode) }
}

// MARK: - Planım: bölüm yol haritası
struct TalkPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    private var store: ScenarioStore { ScenarioStore.shared }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(store.chapters) { chapter in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: chapter.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(DS.Colors.accent)
                                    .frame(width: 40, height: 40)
                                    .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(chapter.localizedTitle)
                                        .font(DS.Font.display(20, weight: .semibold))
                                        .foregroundStyle(DS.Colors.ink)
                                    Text(chapter.localizedSubtitle)
                                        .font(DS.Font.ui(13))
                                        .foregroundStyle(DS.Colors.muted)
                                }
                            }
                            ForEach(Array(chapter.goals.enumerated()), id: \.element.id) { i, goal in
                                let done = store.isDone(goal)
                                HStack(spacing: 12) {
                                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(done ? DS.Colors.accent : DS.Colors.line)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(AL.s(.talkGoal))
                                            .font(DS.Font.ui(11, weight: .semibold))
                                            .foregroundStyle(DS.Colors.muted)
                                        Text(goal.localizedTitle)
                                            .font(DS.Font.ui(16, weight: .medium))
                                            .foregroundStyle(DS.Colors.ink)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 16))
                                .padding(.leading, i % 2 == 0 ? 0 : 24)
                            }
                        }
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
