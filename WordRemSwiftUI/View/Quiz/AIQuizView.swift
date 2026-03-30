//
//  AIQuizView.swift
//  WordRemSwiftUI
//
//  AI-powered quiz launcher: topic grid → question count → loading → quiz.
//

import SwiftUI
import Lottie

// Sorular ve başlık birlikte taşınır — timing sorunu yaşanmaz
private struct AIQuizPayload: Identifiable {
    let id = UUID()
    let questions: [GameQuestion]
    let title: String
}

struct AIQuizView: View {
    @StateObject private var vm = AIQuizViewModel()
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var quizPayload: AIQuizPayload? = nil
    @AppStorage("aiQuizOnboardingShown") private var onboardingShown = false
    @State private var showOnboarding = false
    @State private var showPaywall = false

    /// Konu seçildiğinde sesli intro için set edilir — intro bitince quize geçilir.
    @State private var introTopic: AIQuizTopic? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#f0f4ff"), Color(hex: "#fef9f0"), Color.white],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                aiHeader

                switch vm.state {
                case .selectTopic:
                    topicGrid
                case .selectCount(let topic):
                    countPicker(topic: topic)
                case .loading(let topic, let count):
                    loadingView(topic: topic, count: count)
                case .ready(let questions, let title):
                    Color.clear.onAppear {
                        quizPayload = AIQuizPayload(questions: questions, title: title)
                    }
                case .error(let msg):
                    errorView(msg)
                }
            }

            // One-time onboarding overlay
            if showOnboarding {
                AIQuizOnboardingOverlay {
                    withAnimation(.spring(response: 0.4)) {
                        showOnboarding = false
                        onboardingShown = true
                    }
                }
                .zIndex(10)
                .transition(.opacity)
            }
        }
        .onAppear {
            if !onboardingShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4)) {
                        showOnboarding = true
                    }
                }
            }
        }
        // ── Sesli Konu Anlatımı ────────────────────────────────────────
        .fullScreenCover(item: $introTopic) { topic in
            AIGrammarVoiceIntroView(
                topic: topic,
                targetLangCode: UserDefaults.standard.string(
                    forKey: "selectedTargetLanguageCode") ?? "en",
                nativeLangCode: OL.nativeLangCode,
                onProceed: { selectedTopic in
                    introTopic = nil          // intro'yu kapat
                    vm.selectTopic(selectedTopic)   // count picker'a geç
                }
            )
            .environmentObject(langManager)
        }
        // ── Quiz ──────────────────────────────────────────────────────
        .fullScreenCover(item: $quizPayload, onDismiss: { vm.reset() }) { payload in
            GameQuizView(
                sessionType: .aiGenerated(title: payload.title),
                title: payload.title,
                preloadedQuestions: payload.questions
            )
        }
        // ── Paywall ───────────────────────────────────────────────────
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(onContinue: { showPaywall = false })
                .environmentObject(langManager)
        }
    }

    // MARK: - Header
    private var aiHeader: some View {
        HStack(spacing: 12) {
            Button {
                if case .selectCount = vm.state { vm.backToTopics() } else { dismiss() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.7), in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Quiz")
                    .font(.custom("Feather-Bold", size: 22))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if case .selectCount(let topic) = vm.state {
                    Text(topic.rawValue)
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("Grammar & Vocabulary Practice")
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Spacer()

            // Info button to re-show onboarding
            Button {
                withAnimation(.spring(response: 0.4)) { showOnboarding = true }
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.7), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 4)
    }

    // MARK: - Topic Grid
    private var topicGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Featured topic (Simple Present)
                FeaturedTopicCard(topic: .simplePresent) {
                    introTopic = .simplePresent   // önce sesli intro
                }
                .padding(.horizontal, 16)

                // Category sections
                ForEach(AIQuizTopicCategory.allCases, id: \.self) { cat in
                    let topics = AIQuizTopic.allCases.filter { $0.category == cat && $0 != .simplePresent }
                    CategorySection(category: cat, topics: topics) { topic in
                        introTopic = topic        // önce sesli intro
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        // Ensure scroll works over all subviews
        .scrollContentBackground(.hidden)
    }

    // MARK: - Count Picker
    private func countPicker(topic: AIQuizTopic) -> some View {
        VStack(spacing: 32) {
            Spacer()
            MascotAnimationView(width: 120, height: 120)
            countPickerTitle(topic: topic)
            countPickerButtons(topic: topic)
            generateButton(topic: topic)
            Spacer()
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func countPickerTitle(topic: AIQuizTopic) -> some View {
        VStack(spacing: 6) {
            Text("How many questions?")
                .font(.custom("Feather-Bold", size: 22))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(topic.rawValue)
                .font(.custom("Feather-Bold", size: 14))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    private func countPickerButtons(topic: AIQuizTopic) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(vm.questionCounts.enumerated()), id: \.offset) { idx, count in
                let isLocked = !vm.isPremium && count >= 15
                CountButton(
                    count: count,
                    isSelected: vm.selectedCountIndex == idx,
                    isLocked: isLocked,
                    gradientColors: topic.gradientColors
                ) {
                    if isLocked {
                        showPaywall = true
                    } else {
                        withAnimation(.spring(response: 0.3)) { vm.selectedCountIndex = idx }
                    }
                }
            }
        }
    }

    private func generateButton(topic: AIQuizTopic) -> some View {
        Button {
            if vm.hasReachedFreeLimit { showPaywall = true } else { vm.startGeneration(topic: topic) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").font(.system(size: 15, weight: .semibold))
                Text("Generate Quiz").font(.custom("Feather-Bold", size: 16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: topic.gradientColors, startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .shadow(color: topic.gradientColors.first?.opacity(0.4) ?? .clear, radius: 10, y: 5)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Loading View
    private func loadingView(topic: AIQuizTopic, count: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()
            LottieView(animation: .named("reeny_waving"))
                .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .frame(width: 140, height: 140)
            VStack(spacing: 8) {
                Text("Preparing your quiz...")
                    .font(.custom("Feather-Bold", size: 20))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text("\(count) questions about\n\(topic.rawValue)")
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    LoadingDot(delay: Double(i) * 0.2)
                }
            }
            Spacer()
        }
    }

    // MARK: - Error View
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.orange)
            Text("Something went wrong")
                .font(.custom("Feather-Bold", size: 20))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(msg)
                .font(.custom("Feather-Bold", size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                vm.reset()
            } label: {
                Text("Try Again")
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.primaryOrange, in: Capsule())
            }
            Spacer()
        }
    }
}

// MARK: - Featured Topic Card
private struct FeaturedTopicCard: View {
    let topic: AIQuizTopic
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon area
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: topic.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("⭐ TAVSİYE EDİLEN")
                            .font(.custom("Feather-Bold", size: 10))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2), in: Capsule())
                    }
                    Text(topic.rawValue)
                        .font(.custom("Feather-Bold", size: 18))
                        .foregroundStyle(.white)
                    Text("Başlangıç için mükemmel")
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: topic.gradientColors,
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .shadow(color: topic.gradientColors.first?.opacity(0.4) ?? .clear, radius: 14, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Section
private struct CategorySection: View {
    let category: AIQuizTopicCategory
    let topics: [AIQuizTopic]
    let onSelect: (AIQuizTopic) -> Void

    var categoryIcon: String {
        switch category {
        case .tenses:    return "clock.arrow.2.circlepath"
        case .structure: return "text.alignleft"
        case .vocabulary: return "book.pages"
        }
    }

    var categoryColor: Color {
        switch category {
        case .tenses:    return Color(hex: "#f97316")
        case .structure: return Color(hex: "#6366f1")
        case .vocabulary: return Color(hex: "#10b981")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(categoryColor)
                }
                Text(category.rawValue)
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text("\(topics.count) konu")
                    .font(.custom("Feather-Bold", size: 12))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 20)

            // Topic cards
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(topics) { topic in
                    TopicCard(topic: topic) { onSelect(topic) }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Count Button
private struct CountButton: View {
    let count: Int
    let isSelected: Bool
    let isLocked: Bool
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                VStack(spacing: 4) {
                    Text("\(count)").font(.custom("Feather-Bold", size: 24))
                    Text("soru").font(.custom("Feather-Bold", size: 11))
                }
                .foregroundStyle(isLocked ? Color.gray.opacity(0.4) : (isSelected ? .white : AppTheme.Colors.textPrimary))

                if isLocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "#8b5cf6"))
                                .padding(4)
                                .background(Color(hex: "#8b5cf6").opacity(0.12), in: Circle())
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            .frame(width: 72, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isLocked
                        ? AnyShapeStyle(Color.gray.opacity(0.06))
                        : (isSelected
                            ? AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.white)
                          )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isLocked ? Color(hex: "#8b5cf6").opacity(0.3) : (isSelected ? Color.clear : Color.gray.opacity(0.12)), lineWidth: 1)
            )
            .shadow(
                color: isLocked ? .clear : (isSelected ? (gradientColors.first?.opacity(0.35) ?? .clear) : Color.black.opacity(0.06)),
                radius: 8, y: 4
            )
            .scaleEffect(isSelected ? 1.08 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Topic Card
private struct TopicCard: View {
    let topic: AIQuizTopic
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: topic.gradientColors.map { $0.opacity(0.12) },
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 38, height: 38)
                    Image(systemName: topic.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            colors: topic.gradientColors,
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                }
                Text(topic.rawValue)
                    .font(.custom("Feather-Bold", size: 13))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading Dot
private struct LoadingDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(AppTheme.Colors.primaryOrange)
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Onboarding Overlay
private struct AIQuizOnboardingOverlay: View {
    let onDismiss: () -> Void
    @State private var page = 0

    private let pages: [(icon: String, colors: [Color], title: String, desc: String)] = [
        (
            icon: "sparkles",
            colors: [Color(hex: "#8b5cf6"), Color(hex: "#6366f1")],
            title: "AI ile Kişiselleştirilmiş Quiz",
            desc: "Yapay zeka, seçtiğin konuya özel sorular hazırlar. Her seferinde farklı, her seferinde senin seviyene uygun!"
        ),
        (
            icon: "clock.arrow.2.circlepath",
            colors: [Color(hex: "#f97316"), Color(hex: "#ec4899")],
            title: "Gramer Zamanları",
            desc: "Simple Present'tan Past Perfect'e kadar tüm zaman kiplerini interaktif sorularla öğren. Özellikle Simple Present ile başlamanı öneririz! 🌟"
        ),
        (
            icon: "text.alignleft",
            colors: [Color(hex: "#6366f1"), Color(hex: "#8b5cf6")],
            title: "Cümle Yapısı",
            desc: "Koşul cümleleri, edilgen yapı, modal fiiller... Gerçek cümleler üzerinden pratik yaparak dili içselleştir."
        ),
        (
            icon: "book.pages",
            colors: [Color(hex: "#10b981"), Color(hex: "#3b82f6")],
            title: "Kelime Kategorileri",
            desc: "Günlük hayat, yiyecekler, seyahat ve daha fazlası. Bağlam içinde kelime öğrenmek kalıcılığı 3 kat artırır!"
        )
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { /* block passthrough */ }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // Page indicator
                    HStack(spacing: 6) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == page
                                    ? Color(hex: pages[page].colors.first?.description ?? "#8b5cf6")
                                    : Color.gray.opacity(0.3)
                                )
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: page)
                        }
                    }

                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: pages[page].colors,
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                        Image(systemName: pages[page].icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: pages[page].colors.first?.opacity(0.4) ?? .clear, radius: 16, y: 6)

                    // Text
                    VStack(spacing: 10) {
                        Text(pages[page].title)
                            .font(.custom("Feather-Bold", size: 20))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(pages[page].desc)
                            .font(.custom("Feather-Bold", size: 14))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                    }

                    // Buttons
                    if page < pages.count - 1 {
                        HStack(spacing: 16) {
                            Button("Atla") { onDismiss() }
                                .font(.custom("Feather-Bold", size: 15))
                                .foregroundStyle(AppTheme.Colors.textSecondary)

                            Button {
                                withAnimation(.spring(response: 0.35)) { page += 1 }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("İleri")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.custom("Feather-Bold", size: 15))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 13)
                                .background(
                                    LinearGradient(colors: pages[page].colors, startPoint: .leading, endPoint: .trailing),
                                    in: Capsule()
                                )
                            }
                        }
                    } else {
                        Button {
                            onDismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Hadi Başlayalım!")
                            }
                            .font(.custom("Feather-Bold", size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: pages[page].colors, startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                            .shadow(color: pages[page].colors.first?.opacity(0.4) ?? .clear, radius: 10, y: 5)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(28)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.15), radius: 30, y: 10)

                Spacer()
            }
        }
        .animation(.spring(response: 0.35), value: page)
    }
}

#Preview {
    AIQuizView()
}
