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

struct PathMapView: View {

    @ObservedObject var vm: PathMapViewModel
    @State private var selectedLevel: SBLevelWithProgress?
    @State private var appeared = false
    
    @AppStorage("justCompletedLevel") private var justCompletedLevel = false
    @AppStorage("justSavedMistakes") private var justSavedMistakes = false
    @AppStorage("justClearedMistakes") private var justClearedMistakes = false
    
    @State private var showCompletionPopup = false
    @State private var showMistakesSavedPopup = false
    @State private var showMistakesClearedPopup = false
    @State private var isRefreshingAfterQuiz = false
    
    @State private var showMistakesQuiz = false

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Gradient Background ────────────────────────────
                pathBackground

                if vm.isLoading && vm.levelsWithProgress.isEmpty {
                    VStack(spacing: 8) {
                        LottieView(animation: .named("reeny_waving"))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .frame(width: 120, height: 120)
                        Text("Yükleniyor...")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }

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
                            streak: vm.streakDays
                        )

                        // ── Mistakes Practice Button ───────────────
                        if MistakesManager.shared.hasMistakes {
                            Button {
                                showMistakesQuiz = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.white)
                                    Text(AL.f(.pathMistakesFormat, MistakesManager.shared.count))
                                        .font(.custom("Poppins-SemiBold", size: 14))
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
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.scale.combined(with: .opacity))
                        }

                        // ── Zigzag Level Map ──────────────────────
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                ZStack {
                                    // Dashed connector path
                                    PathConnectorView(
                                        items: vm.levelsWithProgress.reversed()
                                    )

                                    // Level nodes
                                    VStack(spacing: 56) {
                                        ForEach(Array(vm.levelsWithProgress.reversed().enumerated()),
                                                id: \.element.id) { index, item in
                                            PathNodeView(
                                                item: item,
                                                index: index,
                                                totalCount: vm.levelsWithProgress.count
                                            ) {
                                                if item.status != .locked {
                                                    selectedLevel = item
                                                }
                                            }
                                            .id(item.id)
                                        }
                                    }
                                    .padding(.vertical, 40)
                                    .padding(.horizontal, 20)
                                }
                            }
                            .onAppear {
                                // Scroll to current/unlocked level
                                if let active = vm.levelsWithProgress.reversed()
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
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.6)
                                .tint(.white)
                            Text(AL.s(.pathUpdating))
                                .font(.custom("Poppins-SemiBold", size: 15))
                                .foregroundStyle(.white)
                        }
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
                GameQuizView(sessionType: .mistakes, title: AL.s(.pathMistakesReview))
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
            Text(AL.s(.pathSomethingWrong))
                .font(.custom("Poppins-SemiBold", size: 17))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(err)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await vm.loadCourses() }
            } label: {
                Text(AL.s(.pathTryAgain))
                    .font(.custom("Poppins-SemiBold", size: 15))
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
            Text(AL.s(.pathNoCourseForLang))
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(AL.s(.pathNoCourseForLangHint))
                .font(.custom("Poppins-Regular", size: 14))
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
            Text(AL.s(.pathNoCourses))
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(AL.s(.pathNoCoursesHint))
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await vm.loadCourses() }
            } label: {
                Label(AL.s(.pathRefresh), systemImage: "arrow.clockwise")
                    .font(.custom("Poppins-SemiBold", size: 15))
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
// MARK: - Path Header
// MARK: ═══════════════════════════════════════════════════════════

private struct PathHeaderView: View {
    let course: SBCourse?
    let progress: Double
    let xp: Int
    let streak: Int

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(course?.title ?? AL.s(.pathSelectCourse))
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text(motivationText)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // Streak pill
                StatPill(icon: "flame.fill", value: "\(streak)", color: .orange)

                // XP pill
                StatPill(icon: "bolt.fill", value: "\(xp) XP", color: Color(hex: "#FFD700"))
            }

            // Progress bar
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

                    // Percentage text
                    if progress > 0.08 {
                        Text("\(Int(progress * 100))%")
                            .font(.custom("Poppins-Bold", size: 8))
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

    private var motivationText: String {
        if progress >= 1.0 { return AL.s(.pathMotivation3) }
        if progress >= 0.7 { return AL.s(.pathMotivation2) }
        if progress >= 0.3 { return AL.s(.pathMotivation1) }
        return AL.s(.pathMotivation0)
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
                .font(.custom("Poppins-SemiBold", size: 13))
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
                Text(AL.s(.pathStart))
                    .font(.custom("Poppins-Bold", size: 11))
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
                    // Outer glow ring for active node
                    if item.status == .unlocked || item.status == .inProgress {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppTheme.Colors.primaryOrange.opacity(0.6),
                                        AppTheme.Colors.darkOrange.opacity(0.3),
                                        AppTheme.Colors.primaryOrange.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 84, height: 84)
                            .scaleEffect(pulse ? 1.15 : 1.0)
                            .opacity(pulse ? 0.5 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: pulse
                            )
                    }

                    // Main circle
                    Circle()
                        .fill(nodeFill)
                        .frame(width: 72, height: 72)
                        .shadow(color: nodeShadow, radius: pulse ? 16 : 8, y: 4)

                    // Inner circle border
                    Circle()
                        .strokeBorder(nodeBorder, lineWidth: 3)
                        .frame(width: 72, height: 72)

                    // Icon
                    Image(systemName: nodeIcon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(nodeIconColor)
                }
            }
            .buttonStyle(BounceButtonStyle())
            .disabled(item.status == .locked)
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0)

            // Level title
            Text(item.level.title)
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundStyle(item.status == .locked
                    ? AppTheme.Colors.textSecondary.opacity(0.5)
                    : Color(hex: "#1a1a2e"))
                .multilineTextAlignment(.center)

            // XP badge
            Text("\(item.level.xpReward) XP")
                .font(.custom("Poppins-Regular", size: 11))
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
        case .completed:   return Color(hex: "#22c55e").opacity(0.35)
        case .unlocked, .inProgress: return AppTheme.Colors.primaryOrange.opacity(0.3)
        case .locked:      return Color.clear
        }
    }

    private var nodeIcon: String {
        switch item.status {
        case .completed:   return "checkmark"
        case .unlocked, .inProgress: return item.level.iconName ?? "star.fill"
        case .locked:      return "lock.fill"
        }
    }

    private var nodeIconColor: Color {
        switch item.status {
        case .completed:   return .white
        case .unlocked, .inProgress: return AppTheme.Colors.primaryOrange
        case .locked:      return Color.white.opacity(0.7)
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
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: i <= stars ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(i <= stars
                        ? Color(hex: "#f59e0b")
                        : Color(hex: "#d1d5db"))
                    .shadow(color: i <= stars ? Color(hex: "#f59e0b").opacity(0.4) : .clear,
                            radius: 4, y: 2)
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
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 120, height: 120)
                    .padding(.top, 10)

                // Text Content
                VStack(spacing: 8) {
                    Text(AL.s(.pathWellDone))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text(AL.s(.pathWellDoneDesc))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                // Action Button
                Button(action: dismiss) {
                    Text(AL.s(.pathContinue))
                        .font(.custom("Poppins-Bold", size: 16))
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
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 110, height: 110)
                    .padding(.top, 10)

                VStack(spacing: 8) {
                    Text(AL.s(.pathDontBeSad))
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text(AL.s(.pathDontBeSadDesc))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                Button(action: dismiss) {
                    Text(AL.s(.pathGotIt))
                        .font(.custom("Poppins-Bold", size: 16))
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
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 110, height: 110)
                    .padding(.top, 10)

                VStack(spacing: 8) {
                    Text(AL.s(.pathGreatWork))
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text(AL.s(.pathGreatWorkDesc))
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                Button(action: dismiss) {
                    Text(AL.s(.pathHooray))
                        .font(.custom("Poppins-Bold", size: 16))
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

// MARK: - Preview
#Preview {
    PathMapView(vm: PathMapViewModel())
}
