//
//  PathMapView.swift
//  WordRemSwiftUI
//
//  "Pratik" sekmesi: kurs başlığı, ünitelere bölünmüş seviye zaman çizelgesi,
//  hata tekrarı girişi ve seviye sonrası açılan kartlar.
//  "Kâğıt & mürekkep" tasarım sistemi — serif başlıklar, ince çizgiler, tek imza rengi.
//

import SwiftUI
import StoreKit

struct PathMapView: View {

    @EnvironmentObject var langManager: LanguageManager
    @ObservedObject var vm: PathMapViewModel
    @ObservedObject private var mistakes = MistakesManager.shared
    @State private var selectedLevel: SBLevelWithProgress?
    @State private var appeared = false

    @AppStorage("justCompletedLevel") private var justCompletedLevel = false
    @AppStorage("justSavedMistakes") private var justSavedMistakes = false
    @AppStorage("justClearedMistakes") private var justClearedMistakes = false
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false

    @State private var showCompletionPopup = false
    @State private var showMistakesSavedPopup = false
    @State private var showMistakesClearedPopup = false
    @State private var isRefreshingAfterQuiz = false
    @State private var pendingMistakesPopup = false

    @State private var showMistakesQuiz = false
    @State private var showAIQuiz = false
    @State private var currentUnitIndex = 0

    @Environment(\.requestReview) private var requestReview

    // MARK: - Unit Grouping (her 5 level = 1 ünite)
    private let levelsPerUnit = 5

    private var unitGroups: [[SBLevelWithProgress]] {
        let perUnit = levelsPerUnit
        return stride(from: 0, to: vm.levelsWithProgress.count, by: perUnit).map {
            Array(vm.levelsWithProgress[$0..<min($0 + perUnit, vm.levelsWithProgress.count)])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.paper.ignoresSafeArea()

                if vm.isLoading && vm.levelsWithProgress.isEmpty {
                    AppLoadingView(message: langManager.s(.gameLoading))

                } else if let err = vm.errorMessage {
                    errorState(err)

                } else if vm.noCoursesForLanguage {
                    noCoursesForLanguageState

                } else if vm.levelsWithProgress.isEmpty && !vm.isLoading {
                    emptyState

                } else {
                    VStack(spacing: 0) {
                        // ── Course Header ──────────────────────────
                        PathHeaderView(
                            course: vm.selectedCourse,
                            progress: vm.courseProgress,
                            completed: vm.completedCount,
                            total: vm.levelsWithProgress.count,
                            xp: vm.totalXP,
                            streak: vm.streakDays,
                            currentUnit: currentUnitIndex + 1,
                            totalUnits: unitGroups.count
                        )

                        // ── Level Timeline ─────────────────────────
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 0) {
                                    if mistakes.hasMistakes || AIEngine.isAvailable {
                                        practiceRows
                                            .padding(.top, 20)
                                    }

                                    ForEach(Array(unitGroups.enumerated()), id: \.offset) { unitIndex, unitLevels in
                                        PathUnitSection(
                                            unitNumber: unitIndex + 1,
                                            firstLevelNumber: unitIndex * levelsPerUnit + 1,
                                            levels: unitLevels
                                        ) { level in
                                            if level.status != .locked {
                                                selectedLevel = level
                                            }
                                        }
                                        // Ünite başlığı scroll pozisyonunu raporla
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear.preference(
                                                    key: UnitScrollKey.self,
                                                    value: [unitIndex: geo.frame(in: .named("pathScroll")).minY]
                                                )
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 40)
                                .frame(maxWidth: 620)
                                .frame(maxWidth: .infinity)
                            }
                            .coordinateSpace(name: "pathScroll")
                            .onPreferenceChange(UnitScrollKey.self) { positions in
                                // Ekranın üstüne en yakın (ama geçmiş) üniteyi bul
                                let threshold: CGFloat = 220
                                let passed = positions.filter { $0.value <= threshold }
                                if let top = passed.max(by: { $0.value < $1.value }) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentUnitIndex = top.key
                                    }
                                }
                            }
                            .onAppear {
                                if let active = vm.levelsWithProgress
                                    .first(where: { $0.status == .unlocked || $0.status == .inProgress }) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            proxy.scrollTo(active.id, anchor: .center)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Overlays: Loading & Completion Popup ─────────────────
                if isRefreshingAfterQuiz {
                    PathRefreshOverlay()
                        .zIndex(10)
                }

                if showCompletionPopup {
                    LevelCompletePopupView(isPresented: $showCompletionPopup)
                        .zIndex(20)
                }

                if showMistakesSavedPopup {
                    MistakesSavedPopupView(isPresented: $showMistakesSavedPopup)
                        .zIndex(21)
                }

                if showMistakesClearedPopup {
                    MistakesClearedPopupView(isPresented: $showMistakesClearedPopup)
                        .zIndex(22)
                }
            }
            .navigationBarHidden(true)
            .task {
                guard !vm.hasInitiallyLoaded else { return }
                await vm.loadCourses()
                await vm.loadUserProfile()
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    appeared = true
                }
                if DemoData.autoOpenQuiz {
                    for _ in 0..<20 where vm.levelsWithProgress.isEmpty {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                    }
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    selectedLevel = vm.levelsWithProgress.first { $0.status == .unlocked }
                }
            }
            .fullScreenCover(item: $selectedLevel, onDismiss: {
                if justCompletedLevel {
                    isRefreshingAfterQuiz = true
                    Task {
                        await vm.loadCourses()
                        await vm.loadUserProfile()

                        try? await Task.sleep(nanoseconds: 700_000_000)

                        withAnimation {
                            isRefreshingAfterQuiz = false
                            // Always show level-complete popup; mistakes popup follows after
                            showCompletionPopup = true
                            if justSavedMistakes {
                                pendingMistakesPopup = true
                                justSavedMistakes = false
                            }
                            justCompletedLevel = false
                        }

                        // İlk seviye tamamlandığında App Store rating iste
                        if !hasRequestedReview && vm.completedCount == 1 {
                            hasRequestedReview = true
                            // Completion popup gösterildikten sonra iste
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            await MainActor.run { requestReview() }
                        }
                    }
                } else {
                    Task {
                        await vm.loadCourses()
                        await vm.loadUserProfile()
                    }
                }
            }) { level in
                GameQuizView(sessionType: .level(level.id), title: level.level.localizedTitle(langCode: langManager.currentLanguageCode))
            }
            // ── Mistakes Quiz Navigation ─────────────────────────
            .fullScreenCover(isPresented: $showMistakesQuiz, onDismiss: {
                if justClearedMistakes {
                    showMistakesClearedPopup = true
                    justClearedMistakes = false
                }
            }) {
                GameQuizView(sessionType: .mistakes, title: langManager.s(.pathMistakesReview))
            }
            // ── AI Quiz Navigation ────────────────────────────────
            .fullScreenCover(isPresented: $showAIQuiz) {
                AIQuizView()
                    .environmentObject(langManager)
            }
            // Show mistakes-saved popup after level-complete popup is dismissed
            .onChange(of: showCompletionPopup) { _, isShowing in
                if !isShowing && pendingMistakesPopup {
                    pendingMistakesPopup = false
                    withAnimation { showMistakesSavedPopup = true }
                }
            }
        }
    }

    // MARK: - Practice Rows (Mistakes + AI Quiz)
    private var practiceRows: some View {
        VStack(spacing: 0) {
            if mistakes.hasMistakes {
                Button {
                    showMistakesQuiz = true
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DS.Colors.inkSoft)
                                .frame(width: 24)
                            Text(langManager.s(.todayMistakes))
                                .font(DS.Font.ui(16, weight: .medium))
                                .foregroundStyle(DS.Colors.ink)
                            Spacer()
                            Text("\(mistakes.count)")
                                .font(DS.Font.display(18, weight: .bold))
                                .foregroundStyle(DS.Colors.danger)
                                .contentTransition(.numericText())
                            PathChevron()
                        }
                        // 10+ hata uyarısı
                        if mistakes.count > 10 {
                            Text(langManager.s(.pathMistakesUrgent))
                                .font(DS.Font.ui(13))
                                .foregroundStyle(DS.Colors.inkSoft)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 36)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(langManager.f(.pathMistakesFormat, mistakes.count))
                .transition(.opacity)

                if AIEngine.isAvailable {
                    Rectangle()
                        .fill(DS.Colors.line)
                        .frame(height: 1)
                        .padding(.leading, 52)
                }
            }

            // Cihaz üstü AI (Apple Intelligence) yoksa gizlenir
            if AIEngine.isAvailable {
                Button {
                    showAIQuiz = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "text.book.closed")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.slate)
                            .frame(width: 24)
                        Text(AL.s(.pathAIGrammarQuiz))
                            .font(DS.Font.ui(16, weight: .medium))
                            .foregroundStyle(DS.Colors.ink)
                        Spacer()
                        PathChevron()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.line, lineWidth: 1))
        .animation(.easeOut(duration: 0.2), value: mistakes.hasMistakes)
    }

    // MARK: - Error State
    @ViewBuilder
    private func errorState(_ err: String) -> some View {
        PathMessageState(
            title: langManager.s(.pathSomethingWrong),
            // Ham sistem hatası yerine kullanıcı dostu, çevrilmiş mesaj
            message: AL.s(.loadFailedMessage)
        ) {
            Button(langManager.s(.pathTryAgain)) {
                Task { await vm.loadCourses() }
            }
            .buttonStyle(InkButtonStyle())
        }
    }

    // MARK: - No Course For Selected Language State
    private var noCoursesForLanguageState: some View {
        PathMessageState(
            title: langManager.s(.pathNoCourseForLang),
            message: langManager.s(.pathNoCourseForLangHint)
        ) {
            EmptyView()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        PathMessageState(
            title: langManager.s(.pathNoCourses),
            message: langManager.s(.pathNoCoursesHint)
        ) {
            Button {
                Task { await vm.loadCourses() }
            } label: {
                Label(langManager.s(.pathRefresh), systemImage: "arrow.clockwise")
            }
            .buttonStyle(OutlineButtonStyle())
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Shared small pieces
// MARK: ═══════════════════════════════════════════════════════════

private struct PathChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(DS.Colors.muted)
    }
}

/// Serif tek satır + soluk açıklama + isteğe bağlı buton
private struct PathMessageState<Action: View>: View {
    let title: String
    let message: String
    @ViewBuilder var action: Action

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(DS.Font.display(26))
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(DS.Font.ui(15))
                .foregroundStyle(DS.Colors.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            action
                .padding(.top, 12)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 440)
    }
}

/// İnce 4pt ilerleme çizgisi (çizgi zemin / mürekkep dolgu)
private struct PathProgressLine: View {
    let progress: Double
    var fill: Color = DS.Colors.ink

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.Colors.line)
                Capsule()
                    .fill(fill)
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
            }
        }
        .frame(height: 4)
        .animation(.easeOut(duration: 0.4), value: progress)
    }
}

/// Üç küçük yıldız (ödül → altın)
private struct PathStars: View {
    let stars: Int
    var size: CGFloat = 10

    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(i <= stars ? DS.Colors.gold : DS.Colors.line)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars)/3")
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Path Header
// MARK: ═══════════════════════════════════════════════════════════

private struct PathHeaderView: View {
    @EnvironmentObject var langManager: LanguageManager
    let course: SBCourse?
    let progress: Double
    let completed: Int
    let total: Int
    let xp: Int
    let streak: Int
    let currentUnit: Int
    let totalUnits: Int

    private var unitLabel: String {
        let unit = langManager.f(.pathUnitFormat, currentUnit)
        return totalUnits > 1 ? "\(unit) / \(totalUnits)" : unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(text: unitLabel)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: currentUnit)

                Spacer()

                HStack(spacing: 14) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(streak > 0 ? DS.Colors.gold : DS.Colors.muted)
                        Text("\(streak)")
                            .font(DS.Font.ui(13, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                    }
                    Text("\(xp) XP")
                        .font(DS.Font.ui(13, weight: .medium))
                        .foregroundStyle(DS.Colors.muted)
                }
            }

            Text(course?.localizedTitle ?? langManager.s(.pathSelectCourse))
                .font(DS.Font.display(30, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            VStack(alignment: .leading, spacing: 8) {
                PathProgressLine(progress: progress)
                HStack {
                    Text(langManager.f(.pathLevelProgressFormat, completed, total))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                }
                .font(DS.Font.ui(12, weight: .medium))
                .foregroundStyle(DS.Colors.muted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .background(DS.Colors.paper)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.Colors.line).frame(height: 1)
        }
    }
}

// MARK: - Unit Scroll Preference Key
private struct UnitScrollKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Unit Section (Ünite grupları)
// MARK: ═══════════════════════════════════════════════════════════

private struct PathUnitSection: View {
    @EnvironmentObject var langManager: LanguageManager
    let unitNumber: Int
    let firstLevelNumber: Int
    let levels: [SBLevelWithProgress]
    let onTap: (SBLevelWithProgress) -> Void

    private var unitStatus: SBLevelStatus {
        if levels.allSatisfy({ $0.status == .completed }) { return .completed }
        if levels.contains(where: { $0.status == .unlocked || $0.status == .inProgress }) { return .inProgress }
        return .locked
    }

    private var completedCount: Int {
        levels.filter { $0.status == .completed }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Ünite başlığı ──────────────────────────────────────
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(langManager.f(.pathUnitFormat, unitNumber))
                    .font(DS.Font.display(22))
                    .foregroundStyle(unitStatus == .locked ? DS.Colors.muted : DS.Colors.ink)
                Spacer()
                if unitStatus == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Colors.success)
                }
                Text(langManager.f(.pathLevelProgressFormat, completedCount, levels.count))
                    .font(DS.Font.ui(12, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
            }
            .padding(.bottom, 10)

            Rectangle()
                .fill(DS.Colors.line)
                .frame(height: 1)
                .padding(.bottom, 12)

            // ── Seviye satırları ───────────────────────────────────
            ForEach(Array(levels.enumerated()), id: \.element.id) { index, item in
                PathLevelRow(
                    item: item,
                    number: firstLevelNumber + index,
                    isFirst: index == 0,
                    isLast: index == levels.count - 1
                ) {
                    onTap(item)
                }
                .id(item.id)
            }
        }
        .padding(.top, 36)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Level Row (zaman çizelgesi satırı)
// MARK: ═══════════════════════════════════════════════════════════

private struct PathLevelRow: View {
    @EnvironmentObject var langManager: LanguageManager
    let item: SBLevelWithProgress
    let number: Int
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void

    private let markerSize: CGFloat = 32

    private var isCurrent: Bool {
        item.status == .unlocked || item.status == .inProgress
    }

    private var title: String {
        item.level.localizedTitle(langCode: langManager.currentLanguageCode)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // ── Sol: işaret + bağlantı çizgisi ────────────────────
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : DS.Colors.line)
                    .frame(width: 1, height: isCurrent ? 22 : 8)
                marker
                Rectangle()
                    .fill(isLast ? Color.clear : DS.Colors.line)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: markerSize)

            // ── Sağ: içerik ───────────────────────────────────────
            Group {
                if isCurrent {
                    currentCard
                } else {
                    plainRow
                }
            }
            .padding(.bottom, isLast ? 0 : 8)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Marker
    @ViewBuilder
    private var marker: some View {
        switch item.status {
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.Colors.success)
                .frame(width: markerSize, height: markerSize)
                .background(DS.Colors.successSoft, in: Circle())
        case .unlocked, .inProgress:
            Text("\(number)")
                .font(DS.Font.display(15, weight: .bold))
                .foregroundStyle(DS.Colors.paperRaised)
                .frame(width: markerSize, height: markerSize)
                .background(DS.Colors.accent, in: Circle())
        case .locked:
            Text("\(number)")
                .font(DS.Font.display(15, weight: .semibold))
                .foregroundStyle(DS.Colors.muted)
                .frame(width: markerSize, height: markerSize)
                .background(DS.Colors.paper, in: Circle())
                .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
        }
    }

    // MARK: Current level — vurgulu kart
    private var currentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: item.status == .inProgress
                        ? langManager.s(.pathStatusInProgress)
                        : "\(item.level.xpReward) XP")
                Text(title)
                    .font(DS.Font.display(22))
                    .foregroundStyle(DS.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let desc = item.level.localizedDescription(langCode: langManager.currentLanguageCode), !desc.isEmpty {
                    Text(desc)
                        .font(DS.Font.ui(14))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button(langManager.s(.pathStart), action: onTap)
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.accent, lineWidth: 1))
        .padding(.bottom, 12)
    }

    // MARK: Completed / locked row
    private var plainRow: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DS.Font.display(18, weight: .medium))
                        .foregroundStyle(item.status == .locked ? DS.Colors.muted : DS.Colors.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    statusLine
                }
                Spacer(minLength: 8)
                if item.status == .completed {
                    PathChevron()
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(item.status == .locked)
    }

    @ViewBuilder
    private var statusLine: some View {
        if item.status == .completed {
            HStack(spacing: 8) {
                PathStars(stars: item.stars)
                Text("\(item.bestScore)%")
                    .font(DS.Font.ui(13, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
            }
        } else {
            HStack(spacing: 5) {
                Image(systemName: "lock")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(langManager.s(.pathStatusLocked)) · \(item.level.xpReward) XP")
                    .font(DS.Font.ui(13))
            }
            .foregroundStyle(DS.Colors.muted)
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Overlay card shell
// MARK: ═══════════════════════════════════════════════════════════

/// Karartılmış zemin üstünde kâğıt kart
private struct PathOverlayCard<Content: View>: View {
    var onBackdropTap: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            DS.Colors.ink.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onBackdropTap?() }

            content
                .padding(28)
                .frame(maxWidth: 420)
                .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.line, lineWidth: 1))
                .padding(.horizontal, 32)
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Path Refresh Overlay (after quiz completion)
// MARK: ═══════════════════════════════════════════════════════════

private struct PathRefreshOverlay: View {

    @AppStorage("lastCompletedStars") private var stars: Int  = 0
    @AppStorage("lastCompletedScore") private var score: Int  = 0
    @EnvironmentObject var langManager: LanguageManager

    @State private var barProgress: Double     = 0
    @State private var cardOpacity: Double     = 0
    @State private var dotOpacities: [Double]  = [1.0, 0.3, 0.3]

    var body: some View {
        PathOverlayCard {
            VStack(spacing: 18) {
                PathStars(stars: stars, size: 20)

                Text("\(score)%")
                    .font(DS.Font.display(44, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)

                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Text(langManager.s(.pathUpdating)
                            .replacingOccurrences(of: "...", with: ""))
                            .font(DS.Font.ui(13, weight: .medium))
                            .foregroundStyle(DS.Colors.muted)
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(DS.Colors.muted.opacity(dotOpacities[i]))
                                .frame(width: 4, height: 4)
                        }
                    }

                    PathProgressLine(progress: barProgress)
                        .frame(width: 200)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(cardOpacity)
        .onAppear { animateEntrance() }
        .task { await animateDots() }
    }

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.25)) {
            cardOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.9).delay(0.2)) {
            barProgress = 1.0
        }
    }

    // Nokta animasyonu — overlay ömrü boyunca .task ile döner
    private func animateDots() async {
        var phase = 0
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: 0.25)) {
                dotOpacities = [0.3, 0.3, 0.3]
                dotOpacities[phase] = 1.0
            }
            phase = (phase + 1) % 3
            try? await Task.sleep(nanoseconds: 380_000_000)
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Level Complete Popup Component
// MARK: ═══════════════════════════════════════════════════════════

struct LevelCompletePopupView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var opacity: Double = 0.0

    @AppStorage("lastCompletedScore") private var lastScore: Int = 0
    @AppStorage("lastCompletedStars") private var lastStars: Int = 0

    var body: some View {
        PathOverlayCard(onBackdropTap: dismiss) {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    PathStars(stars: lastStars, size: 22)
                    Text("\(lastScore)%")
                        .font(DS.Font.display(48, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                }

                Rectangle().fill(DS.Colors.accent).frame(width: 24, height: 2)

                VStack(spacing: 8) {
                    Text(langManager.s(.pathWellDone))
                        .font(DS.Font.display(26))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)

                    Text(langManager.s(.pathWellDoneDesc))
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(langManager.s(.pathContinue), action: dismiss)
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                    .padding(.top, 4)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { opacity = 1.0 }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Mistakes Popups

struct MistakesSavedPopupView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var opacity: Double = 0.0

    var body: some View {
        PathOverlayCard(onBackdropTap: dismiss) {
            VStack(spacing: 20) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Colors.danger)
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.dangerSoft, in: Circle())

                VStack(spacing: 8) {
                    Text(langManager.s(.pathDontBeSad))
                        .font(DS.Font.display(26))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)

                    Text(langManager.s(.pathDontBeSadDesc))
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(langManager.s(.pathGotIt), action: dismiss)
                    .buttonStyle(InkButtonStyle())
                    .padding(.top, 4)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { opacity = 1.0 }
        }
    }
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) { opacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isPresented = false }
    }
}

struct MistakesClearedPopupView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var opacity: Double = 0.0

    var body: some View {
        PathOverlayCard(onBackdropTap: dismiss) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DS.Colors.success)
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.successSoft, in: Circle())

                VStack(spacing: 8) {
                    Text(langManager.s(.pathGreatWork))
                        .font(DS.Font.display(26))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)

                    Text(langManager.s(.pathGreatWorkDesc))
                        .font(DS.Font.ui(15))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(langManager.s(.pathHooray), action: dismiss)
                    .buttonStyle(InkButtonStyle())
                    .padding(.top, 4)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { opacity = 1.0 }
        }
    }
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) { opacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isPresented = false }
    }
}

// MARK: - Preview
#Preview {
    PathMapView(vm: PathMapViewModel())
}
