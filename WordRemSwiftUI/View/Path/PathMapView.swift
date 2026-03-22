//
//  PathMapView.swift
//  WordRemSwiftUI
//
//  Duolingo-style gamified path map with zigzag layout,
//  animated circular nodes, dashed connector path, and
//  decorative background elements.
//

import SwiftUI
import Lottie
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

    @State private var showMistakesQuiz = false
    @State private var showAIQuiz = false
    @State private var currentUnitIndex = 0

    @Environment(\.requestReview) private var requestReview

    // MARK: - Unit Grouping (her 5 level = 1 ünite)
    private var unitGroups: [[SBLevelWithProgress]] {
        let perUnit = 5
        return stride(from: 0, to: vm.levelsWithProgress.count, by: perUnit).map {
            Array(vm.levelsWithProgress[$0..<min($0 + perUnit, vm.levelsWithProgress.count)])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Gradient Background ────────────────────────────
                pathBackground

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
                            xp: vm.totalXP,
                            streak: vm.streakDays,
                            currentUnit: currentUnitIndex + 1,
                            totalUnits: unitGroups.count
                        )

                        // ── Mistakes Practice Button ───────────────
                        if mistakes.hasMistakes {
                            VStack(spacing: 6) {
                                // 10+ hata uyarısı
                                if mistakes.count > 10 {
                                    MistakesUrgentBanner()
                                }

                                Button {
                                    showMistakesQuiz = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.white)
                                        Text(langManager.f(.pathMistakesFormat, mistakes.count))
                                            .font(.custom("Feather-Bold", size: 14))
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)],
                                            startPoint: .leading, endPoint: .trailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 16)
                                    )
                                    .shadow(color: Color.red.opacity(0.3), radius: 6, y: 3)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.scale.combined(with: .opacity))
                        }

                        // ── AI Quiz Button ─────────────────────────
                        Button {
                            showAIQuiz = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("AI Grammar Quiz")
                                    .font(.custom("Feather-Bold", size: 14))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#8b5cf6"), Color(hex: "#6366f1")],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .shadow(color: Color(hex: "#8b5cf6").opacity(0.35), radius: 6, y: 3)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // ── Ünite Bazlı Level Map ─────────────────
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    ForEach(Array(unitGroups.enumerated()), id: \.offset) { unitIndex, unitLevels in
                                        UnitSectionView(
                                            unitNumber: unitIndex + 1,
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
                                .padding(.bottom, 40)
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
                    ZStack {
                        Color.black.opacity(0.55).ignoresSafeArea()
                        AppLoadingView(message: langManager.s(.pathUpdating))
                    }
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
                            if justSavedMistakes {
                                showMistakesSavedPopup = true
                                justSavedMistakes = false
                            } else {
                                showCompletionPopup = true
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
                GameQuizView(sessionType: .level(level.id), title: level.level.title)
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
            }
        }
    }

    // MARK: - Background
    private var pathBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#e8f4f8"),
                    Color(hex: "#f0f4ff"),
                    Color(hex: "#fef9f0"),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative floating elements
            GeometryReader { geo in
                ForEach(0..<8, id: \.self) { i in
                    DecoElement(index: i, size: geo.size)
                }
            }
            .ignoresSafeArea()
            .opacity(appeared ? 0.6 : 0)
            .animation(.easeIn(duration: 1), value: appeared)
        }
    }

    // MARK: - Error State
    @ViewBuilder
    private func errorState(_ err: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(langManager.s(.pathSomethingWrong))
                .font(.custom("Feather-Bold", size: 17))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(err)
                .font(.custom("Feather-Bold", size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await vm.loadCourses() }
            } label: {
                Text(langManager.s(.pathTryAgain))
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.primaryOrange, in: Capsule())
            }
        }
    }

    // MARK: - No Course For Selected Language State
    private var noCoursesForLanguageState: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.slash")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.Colors.primaryOrange.opacity(0.7))
            Text(langManager.s(.pathNoCourseForLang))
                .font(.custom("Feather-Bold", size: 20))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(langManager.s(.pathNoCourseForLangHint))
                .font(.custom("Feather-Bold", size: 14))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.Colors.primaryOrange.opacity(0.7))
            Text(langManager.s(.pathNoCourses))
                .font(.custom("Feather-Bold", size: 20))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(langManager.s(.pathNoCoursesHint))
                .font(.custom("Feather-Bold", size: 14))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await vm.loadCourses() }
            } label: {
                Label(langManager.s(.pathRefresh), systemImage: "arrow.clockwise")
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.primaryOrange, in: Capsule())
            }
        }
        .padding()
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Unit Section (Ünite grupları)
// MARK: ═══════════════════════════════════════════════════════════

private struct UnitSectionView: View {
    let unitNumber: Int
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
        VStack(spacing: 0) {
            // ── Ünite ayraç bandı ──────────────────────────────────
            UnitDividerView(
                unitNumber: unitNumber,
                status: unitStatus,
                completed: completedCount,
                total: levels.count
            )

            // ── Level node'ları ────────────────────────────────────
            ZStack {
                PathConnectorView(items: levels)

                VStack(spacing: 56) {
                    ForEach(Array(levels.enumerated()), id: \.element.id) { index, item in
                        PathNodeView(
                            item: item,
                            index: index,
                            totalCount: levels.count
                        ) {
                            onTap(item)
                        }
                        .id(item.id)
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Unit Divider (sade ayraç)
// MARK: ═══════════════════════════════════════════════════════════

private struct UnitDividerView: View {
    let unitNumber: Int
    let status: SBLevelStatus
    let completed: Int
    let total: Int

    private var accentColor: Color {
        switch status {
        case .completed:              return Color(hex: "#22c55e")
        case .inProgress, .unlocked:  return AppTheme.Colors.primaryOrange
        case .locked:                 return Color(hex: "#cbd5e1")
        }
    }

    private var progress: CGFloat {
        total > 0 ? CGFloat(completed) / CGFloat(total) : 0
    }

    var body: some View {
        VStack(spacing: 10) {
            // Çizgi + pill
            HStack(spacing: 12) {
                // Sol çizgi
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, accentColor.opacity(0.35)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)

                // Ünite pill
                HStack(spacing: 5) {
                    if status == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentColor)
                    } else if status == .locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accentColor)
                    }
                    Text(langManager.f(.pathUnitFormat, unitNumber))
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(status == .locked ? Color(hex: "#94a3b8") : Color(hex: "#1a1a2e"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(status == .locked ? 0.07 : 0.12))
                        .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
                )

                // Sağ çizgi
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.35), Color.clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)
            }
            .padding(.horizontal, 24)

            // Mini progress bar (sadece aktif/tamamlanmış ünitelerde)
            if status != .locked {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "#e2e8f0"))
                            .frame(height: 3)
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 48)

                Text(langManager.f(.pathLevelProgressFormat, completed, total))
                    .font(.custom("Feather-Bold", size: 10))
                    .foregroundStyle(Color(hex: "#94a3b8"))
            }
        }
        .padding(.top, unitNumber == 1 ? 16 : 8)
        .padding(.bottom, 4)
        .opacity(status == .locked ? 0.7 : 1)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Unit Header
// MARK: ═══════════════════════════════════════════════════════════

private struct UnitHeaderView: View {
    let unitNumber: Int
    let status: SBLevelStatus
    let totalLevels: Int
    let completedLevels: Int

    var body: some View {
        HStack(spacing: 14) {
            // Sol: ikon dairesi
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: statusIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(statusColor)
            }

            // Orta: başlık + progress
            VStack(alignment: .leading, spacing: 4) {
                Text(langManager.f(.pathUnitFormat, unitNumber))
                    .font(.custom("Feather-Bold", size: 17))
                    .foregroundStyle(status == .locked ? Color(hex: "#9ca3af") : Color(hex: "#1a1a2e"))

                // İlerleme çubuğu
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "#e2e8f0"))
                            .frame(height: 6)
                        Capsule()
                            .fill(statusColor)
                            .frame(width: geo.size.width * CGFloat(completedLevels) / CGFloat(max(totalLevels, 1)), height: 6)
                            .animation(.spring(response: 0.6), value: completedLevels)
                    }
                }
                .frame(height: 6)

                Text(langManager.f(.pathLevelProgressFormat, completedLevels, totalLevels))
                    .font(.custom("Feather-Bold", size: 11))
                    .foregroundStyle(Color(hex: "#9ca3af"))
            }

            Spacer()

            // Sağ: durum badge
            Text(statusText)
                .font(.custom("Feather-Bold", size: 11))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(status == .locked ? Color(hex: "#f1f5f9") : Color.white)
                .shadow(color: statusColor.opacity(status == .locked ? 0 : 0.15), radius: 10, y: 3)
        )
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 4)
        .opacity(status == .locked ? 0.65 : 1.0)
    }

    private var statusColor: Color {
        switch status {
        case .completed:            return Color(hex: "#22c55e")
        case .inProgress, .unlocked: return AppTheme.Colors.primaryOrange
        case .locked:               return Color(hex: "#9ca3af")
        }
    }

    private var statusIcon: String {
        switch status {
        case .completed:            return "checkmark.seal.fill"
        case .inProgress, .unlocked: return "flame.fill"
        case .locked:               return "lock.fill"
        }
    }

    private var statusText: String {
        switch status {
        case .completed:            return langManager.s(.pathStatusCompleted)
        case .inProgress, .unlocked: return langManager.s(.pathStatusInProgress)
        case .locked:               return langManager.s(.pathStatusLocked)
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Path Header
// MARK: ═══════════════════════════════════════════════════════════

private struct PathHeaderView: View {
    let course: SBCourse?
    let progress: Double
    let xp: Int
    let streak: Int
    let currentUnit: Int
    let totalUnits: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                // Sol: Ünite bilgisi (scroll ile güncellenir)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(langManager.f(.pathUnitFormat, currentUnit))
                            .font(.custom("Feather-Bold", size: 20))
                            .foregroundStyle(Color(hex: "#1a1a2e"))
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: currentUnit)

                        if totalUnits > 1 {
                            Text("/ \(totalUnits)")
                                .font(.custom("Feather-Bold", size: 14))
                                .foregroundStyle(Color(hex: "#94a3b8"))
                        }
                    }

                    Text(course?.title ?? langManager.s(.pathSelectCourse))
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Sağ: Streak + XP
                HStack(spacing: 8) {
                    StatPill(icon: "flame.fill", value: "\(streak)", color: .orange)
                    StatPill(icon: "bolt.fill", value: "\(xp) XP", color: Color(hex: "#FFD700"))
                }
            }

            // İlerleme çubuğu (tüm kurs)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#e2e8f0"))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#f97316"), Color(hex: "#f59e0b")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * CGFloat(progress), 10), height: 10)
                        .animation(.spring(response: 0.6), value: progress)

                    if progress > 0.08 {
                        Text("\(Int(progress * 100))%")
                            .font(.custom("Feather-Bold", size: 8))
                            .foregroundStyle(.white)
                            .offset(x: max(geo.size.width * CGFloat(progress) - 24, 4))
                    }
                }
            }
            .frame(height: 10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

// MARK: - Unit Scroll Preference Key
private struct UnitScrollKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Stat Pill
private struct StatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.custom("Feather-Bold", size: 13))
                .foregroundStyle(Color(hex: "#1a1a2e"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Path Node (Duolingo-style circular button)
// MARK: ═══════════════════════════════════════════════════════════

struct PathNodeView: View {
    let item: SBLevelWithProgress
    let index: Int
    let totalCount: Int
    let onTap: () -> Void

    @State private var pulse = false
    @State private var appeared = false

    // Zigzag X offset: even indices left, odd indices right
    private var xOffset: CGFloat {
        let amplitude: CGFloat = 70
        return (index % 2 == 0) ? -amplitude : amplitude
    }

    var body: some View {
        VStack(spacing: 8) {
            // Level label above node
            if item.status == .unlocked || item.status == .inProgress {
                Text(langManager.s(.pathStart))
                    .font(.custom("Feather-Bold", size: 11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.primaryOrange)
                            .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.4), radius: 6, y: 3)
                    )
                    .transition(.scale.combined(with: .opacity))
            }

            // Main circular node
            Button(action: onTap) {
                ZStack {
                    // Outer pulse ring — gradient for active, plain for others
                    if item.status == .unlocked || item.status == .inProgress {
                        // Second outer ring (softer, larger)
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FFAA44").opacity(0.25),
                                        Color(hex: "#E8409C").opacity(0.15),
                                        Color(hex: "#6B22E0").opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 6
                            )
                            .frame(width: 96, height: 96)
                            .scaleEffect(pulse ? 1.12 : 1.0)
                            .opacity(pulse ? 0.4 : 0.9)
                            .animation(
                                .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                                value: pulse
                            )

                        // Inner ring (sharper gradient border)
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FFAA44"),
                                        Color(hex: "#E8409C"),
                                        Color(hex: "#6B22E0")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(pulse ? 1.08 : 1.0)
                            .opacity(pulse ? 0.6 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: pulse
                            )
                    }

                    // Main circle (shadow only, image covers it)
                    Circle()
                        .fill(nodeFill)
                        .frame(width: 72, height: 72)
                        .shadow(color: nodeShadow, radius: pulse ? 18 : 8, y: 4)

                    // Icon — starss fills the entire circle for active nodes
                    Group {
                        if item.status == .locked {
                            Circle()
                                .strokeBorder(nodeBorder, lineWidth: 3)
                                .frame(width: 72, height: 72)
                                .overlay {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(Color.white.opacity(0.8))
                                }
                        } else if item.status == .completed {
                            Circle()
                                .strokeBorder(nodeBorder, lineWidth: 3)
                                .frame(width: 72, height: 72)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                        } else {
                            // starss covers the full circle — clip to circle shape
                            Image("starss")
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .buttonStyle(BounceButtonStyle())
            .disabled(item.status == .locked)
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0)

            // Level title
            Text(item.level.title)
                .font(.custom("Feather-Bold", size: 13))
                .foregroundStyle(item.status == .locked
                    ? AppTheme.Colors.textSecondary.opacity(0.5)
                    : Color(hex: "#1a1a2e"))
                .multilineTextAlignment(.center)

            // XP badge
            Text("\(item.level.xpReward) XP")
                .font(.custom("Feather-Bold", size: 11))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            // Stars (completed)
            if item.status == .completed {
                PathStarView(stars: item.stars)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .offset(x: xOffset)
        .opacity(item.status == .locked ? 0.5 : 1.0)
        .onAppear {
            if item.status == .unlocked || item.status == .inProgress {
                pulse = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08)) {
                appeared = true
            }
        }
    }

    // MARK: - Styling

    private var nodeFill: some ShapeStyle {
        switch item.status {
        case .completed:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: "#22c55e"), Color(hex: "#16a34a")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .unlocked, .inProgress:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white, Color(hex: "#fff7ed")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .locked:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: "#d1d5db"), Color(hex: "#9ca3af")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var nodeBorder: Color {
        switch item.status {
        case .completed:   return Color(hex: "#15803d")
        case .unlocked, .inProgress: return AppTheme.Colors.primaryOrange
        case .locked:      return Color(hex: "#9ca3af")
        }
    }

    private var nodeShadow: Color {
        switch item.status {
        case .completed:              return Color(hex: "#22c55e").opacity(0.35)
        case .unlocked, .inProgress:  return Color(hex: "#E8409C").opacity(0.4)
        case .locked:                 return Color.clear
        }
    }

}

// MARK: - Bounce Button Style
private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Path Connector (Dashed line between nodes)
// MARK: ═══════════════════════════════════════════════════════════

private struct PathConnectorView: View {
    let items: [SBLevelWithProgress]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let nodeSpacing: CGFloat = 56 + 140 // VStack spacing + approx node height
            let amplitude: CGFloat = 70

            Path { path in
                for i in 0..<items.count {
                    let y = 40 + CGFloat(i) * nodeSpacing + 36 // centered on node
                    let x = width / 2 + ((i % 2 == 0) ? -amplitude : amplitude)

                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        let prevX = width / 2 + (((i - 1) % 2 == 0) ? -amplitude : amplitude)
                        let prevY = 40 + CGFloat(i - 1) * nodeSpacing + 36
                        let midY = (prevY + y) / 2

                        path.addCurve(
                            to: CGPoint(x: x, y: y),
                            control1: CGPoint(x: prevX, y: midY),
                            control2: CGPoint(x: x, y: midY)
                        )
                    }
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 8]))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.primaryOrange.opacity(0.25),
                        Color(hex: "#e2e8f0").opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Star Rating
// MARK: ═══════════════════════════════════════════════════════════

private struct PathStarView: View {
    let stars: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { i in
                Image("starss")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .opacity(i <= stars ? 1.0 : 0.25)
                    .scaleEffect(i <= stars ? 1.0 : 0.85)
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Decorative Background Elements
// MARK: ═══════════════════════════════════════════════════════════

private struct DecoElement: View {
    let index: Int
    let size: CGSize

    @State private var floating = false

    // Pseudo-random positions based on index
    private var xPos: CGFloat {
        let positions: [CGFloat] = [0.1, 0.85, 0.15, 0.9, 0.05, 0.92, 0.2, 0.8]
        return size.width * positions[index % positions.count]
    }

    private var yPos: CGFloat {
        let positions: [CGFloat] = [0.08, 0.18, 0.32, 0.45, 0.55, 0.68, 0.78, 0.9]
        return size.height * positions[index % positions.count]
    }

    private var decoIcon: String {
        let icons = ["cloud.fill", "sparkle", "star.fill", "cloud.fill",
                      "sparkle", "leaf.fill", "star.fill", "cloud.fill"]
        return icons[index % icons.count]
    }

    private var decoColor: Color {
        let colors: [Color] = [
            .blue.opacity(0.15), .orange.opacity(0.2), .yellow.opacity(0.25),
            .blue.opacity(0.1), .purple.opacity(0.15), .green.opacity(0.15),
            .orange.opacity(0.15), .blue.opacity(0.12)
        ]
        return colors[index % colors.count]
    }

    private var decoSize: CGFloat {
        let sizes: [CGFloat] = [20, 14, 12, 24, 10, 16, 11, 22]
        return sizes[index % sizes.count]
    }

    var body: some View {
        Image(systemName: decoIcon)
            .font(.system(size: decoSize))
            .foregroundStyle(decoColor)
            .position(x: xPos, y: yPos)
            .offset(y: floating ? -6 : 6)
            .animation(
                .easeInOut(duration: Double.random(in: 2.5...4.0))
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.3),
                value: floating
            )
            .onAppear { floating = true }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Level Complete Popup Component
// MARK: ═══════════════════════════════════════════════════════════

struct LevelCompletePopupView: View {
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                // Mascot celebrating
                LottieView(animation: .named("reeny_waving"))
                    .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 120, height: 120)
                    .padding(.top, 10)

                // Text Content
                VStack(spacing: 8) {
                    Text(langManager.s(.pathWellDone))
                        .font(.custom("Feather-Bold", size: 28))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text(langManager.s(.pathWellDoneDesc))
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                // Action Button
                Button(action: dismiss) {
                    Text(langManager.s(.pathContinue))
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.primaryOrange)
                                .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.3), radius: 8, y: 4)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            )
            .padding(.horizontal, 40)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            scale = 0.8
            opacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Mistakes Popups

struct MistakesSavedPopupView: View {
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { dismiss() }

            VStack(spacing: 24) {
                LottieView(animation: .named("reeny_waving"))
                    .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 110, height: 110)
                    .padding(.top, 10)

                VStack(spacing: 8) {
                    Text(langManager.s(.pathDontBeSad))
                        .font(.custom("Feather-Bold", size: 24))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text(langManager.s(.pathDontBeSadDesc))
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                Button(action: dismiss) {
                    Text(langManager.s(.pathGotIt))
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.orange).shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4))
                }
                .padding(.horizontal, 20).padding(.bottom, 10)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white).shadow(color: .black.opacity(0.1), radius: 20, y: 10))
            .padding(.horizontal, 40)
            .scaleEffect(scale).opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { scale = 1.0; opacity = 1.0 }
            }
        }
    }
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) { scale = 0.8; opacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isPresented = false }
    }
}

struct MistakesClearedPopupView: View {
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { dismiss() }

            VStack(spacing: 24) {
                LottieView(animation: .named("reeny_waving"))
                    .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 110, height: 110)
                    .padding(.top, 10)

                VStack(spacing: 8) {
                    Text(langManager.s(.pathGreatWork))
                        .font(.custom("Feather-Bold", size: 24))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text(langManager.s(.pathGreatWorkDesc))
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                Button(action: dismiss) {
                    Text(langManager.s(.pathHooray))
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.green).shadow(color: Color.green.opacity(0.3), radius: 8, y: 4))
                }
                .padding(.horizontal, 20).padding(.bottom, 10)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white).shadow(color: .black.opacity(0.1), radius: 20, y: 10))
            .padding(.horizontal, 40)
            .scaleEffect(scale).opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { scale = 1.0; opacity = 1.0 }
            }
        }
    }
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) { scale = 0.8; opacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isPresented = false }
    }
}

// MARK: - Mistakes Urgent Banner
private struct MistakesUrgentBanner: View {
    @State private var bouncing = false

    var body: some View {
        HStack(spacing: 8) {
            // Yukarı ok — mistakes butonuna işaret eder
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "#ff3b30"))
                .offset(y: bouncing ? -4 : 0)
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: bouncing
                )

            Text(langManager.s(.pathMistakesUrgent))
                .font(.custom("Feather-Bold", size: 13))
                .foregroundStyle(Color(hex: "#ff3b30"))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#ff3b30").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: "#ff3b30").opacity(0.35), lineWidth: 1)
                )
        )
        .onAppear { bouncing = true }
    }
}

// MARK: - Preview
#Preview {
    PathMapView(vm: PathMapViewModel())
}
