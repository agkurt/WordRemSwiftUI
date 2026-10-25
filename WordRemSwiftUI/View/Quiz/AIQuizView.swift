//
//  AIQuizView.swift
//  WordRemSwiftUI
//
//  AI-powered quiz launcher: topic list → question count → loading → quiz.
//  "Kâğıt & mürekkep" tasarım sistemi.
//

import SwiftUI

// Sorular ve başlık birlikte taşınır — timing sorunu yaşanmaz
private struct AIQuizPayload: Identifiable {
    let id = UUID()
    let questions: [GameQuestion]
    let title: String
}

/// Konunun tek satırlık açıklaması (prompt metninin "—" sonrası kısmı)
private func aiTopicBlurb(_ topic: AIQuizTopic) -> String {
    let text = topic.promptDescription
    if let range = text.range(of: " — ") {
        return String(text[range.upperBound...])
    }
    return text
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
            DS.Colors.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                aiHeader

                switch vm.state {
                case .selectTopic:
                    topicList
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
                    withAnimation(.easeOut(duration: 0.25)) {
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
                    withAnimation(.easeOut(duration: 0.25)) {
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
                    .foregroundStyle(DS.Colors.ink)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(AL.s(.aiQuizTitle))
                    .font(DS.Font.display(22))
                    .foregroundStyle(DS.Colors.ink)
                if case .selectCount(let topic) = vm.state {
                    Text(topic.rawValue)
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                        .lineLimit(1)
                } else {
                    Text(AL.s(.aiQuizSubtitle))
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                }
            }

            Spacer()

            // Info button to re-show onboarding
            Button {
                withAnimation(.easeOut(duration: 0.25)) { showOnboarding = true }
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .background(DS.Colors.paper)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.Colors.line).frame(height: 1)
        }
    }

    // MARK: - Topic List
    private var topicList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // Önerilen konu (Simple Present)
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: AL.s(.hcRecommended))
                    PaperCard(padding: 0) {
                        AITopicRow(
                            topic: .simplePresent,
                            subtitle: AL.s(.hcPerfectForBeginners)
                        ) {
                            introTopic = .simplePresent   // önce sesli intro
                        }
                    }
                }

                // Kategoriler
                ForEach(AIQuizTopicCategory.allCases, id: \.self) { cat in
                    let topics = AIQuizTopic.allCases.filter { $0.category == cat && $0 != .simplePresent }
                    AICategorySection(category: cat, topics: topics) { topic in
                        introTopic = topic        // önce sesli intro
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Count Picker
    private func countPicker(topic: AIQuizTopic) -> some View {
        VStack(spacing: 32) {
            Spacer()
            countPickerTitle(topic: topic)
            countPickerButtons(topic: topic)
            generateButton(topic: topic)
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func countPickerTitle(topic: AIQuizTopic) -> some View {
        VStack(spacing: 8) {
            Eyebrow(text: topic.category.rawValue, color: DS.Colors.muted)
            Text(AL.s(.aiQuizHowMany))
                .font(DS.Font.display(28))
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
            Text(topic.rawValue)
                .font(DS.Font.ui(15))
                .foregroundStyle(DS.Colors.muted)
        }
    }

    private func countPickerButtons(topic: AIQuizTopic) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(vm.questionCounts.enumerated()), id: \.offset) { idx, count in
                let isLocked = !vm.isPremium && count >= 15
                AICountButton(
                    count: count,
                    isSelected: vm.selectedCountIndex == idx,
                    isLocked: isLocked
                ) {
                    if isLocked {
                        showPaywall = true
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) { vm.selectedCountIndex = idx }
                    }
                }
            }
        }
    }

    private func generateButton(topic: AIQuizTopic) -> some View {
        Button {
            if vm.hasReachedFreeLimit { showPaywall = true } else { vm.startGeneration(topic: topic) }
        } label: {
            Text(AL.s(.aiQuizGenerate))
        }
        .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
    }

    // MARK: - Loading View
    private func loadingView(topic: AIQuizTopic, count: Int) -> some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView()
                .tint(DS.Colors.muted)
                .controlSize(.large)
            VStack(spacing: 6) {
                Text(AL.s(.aiQuizPreparing))
                    .font(DS.Font.ui(16, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                Text(AL.f(.aiQuizAbout, count) + "\n" + topic.rawValue)
                    .font(DS.Font.ui(14))
                    .foregroundStyle(DS.Colors.muted)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error View
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Text(AL.s(.aiQuizError))
                .font(DS.Font.display(24))
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
            Text(msg)
                .font(DS.Font.ui(15))
                .foregroundStyle(DS.Colors.muted)
                .multilineTextAlignment(.center)
            Button {
                vm.reset()
            } label: {
                Text(AL.s(.aiQuizTryAgain))
            }
            .buttonStyle(OutlineButtonStyle())
            .padding(.top, 12)
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Topic Row
private struct AITopicRow: View {
    let topic: AIQuizTopic
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.rawValue)
                        .font(DS.Font.display(19))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.leading)
                    Text(subtitle ?? aiTopicBlurb(topic))
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.muted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Section
private struct AICategorySection: View {
    let category: AIQuizTopicCategory
    let topics: [AIQuizTopic]
    let onSelect: (AIQuizTopic) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(text: category.rawValue, color: DS.Colors.muted)
                Spacer()
                Text(AL.f(.aiQuizTopicsCount, topics.count))
                    .font(DS.Font.ui(12))
                    .foregroundStyle(DS.Colors.muted)
            }

            PaperCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(topics.enumerated()), id: \.element.id) { idx, topic in
                        AITopicRow(topic: topic) { onSelect(topic) }
                        if idx < topics.count - 1 {
                            Rectangle()
                                .fill(DS.Colors.line)
                                .frame(height: 1)
                                .padding(.leading, 18)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Count Button
private struct AICountButton: View {
    let count: Int
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    private var foreground: Color {
        if isLocked { return DS.Colors.muted }
        return isSelected ? DS.Colors.paperRaised : DS.Colors.ink
    }

    private var fill: Color {
        if isLocked { return DS.Colors.paperSunken }
        return isSelected ? DS.Colors.ink : DS.Colors.paperRaised
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(count)").font(DS.Font.display(26))
                if isLocked {
                    Image(systemName: "lock")
                        .font(.system(size: 11, weight: .semibold))
                } else {
                    Text(AL.s(.aiQuizQuestionsUnit)).font(DS.Font.ui(11, weight: .medium))
                }
            }
            .foregroundStyle(foreground)
            .frame(width: 72, height: 72)
            .background(fill, in: RoundedRectangle(cornerRadius: DS.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .stroke(isSelected && !isLocked ? Color.clear : DS.Colors.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Onboarding Overlay
private struct AIQuizOnboardingOverlay: View {
    let onDismiss: () -> Void
    @State private var page = 0

    private var pages: [(icon: String, title: String, desc: String)] {[
        (icon: "book",           title: AL.s(.hcAIPage1Title), desc: AL.s(.hcAIPage1Desc)),
        (icon: "clock",          title: AL.s(.hcAIPage2Title), desc: AL.s(.hcAIPage2Desc)),
        (icon: "text.alignleft", title: AL.s(.hcAIPage3Title), desc: AL.s(.hcAIPage3Desc)),
        (icon: "character.book.closed", title: AL.s(.hcAIPage4Title), desc: AL.s(.hcAIPage4Desc))
    ]}

    var body: some View {
        ZStack {
            DS.Colors.paper
                .ignoresSafeArea()
                .onTapGesture { /* block passthrough */ }

            VStack(alignment: .leading, spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    if page < pages.count - 1 {
                        Button(AL.s(.commonSkip)) { onDismiss() }
                            .font(DS.Font.ui(15, weight: .medium))
                            .foregroundStyle(DS.Colors.muted)
                    }
                }
                .frame(height: 44)

                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(DS.Colors.accent)
                        .padding(.bottom, 8)
                    Text(pages[page].title)
                        .font(DS.Font.display(32, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(pages[page].desc)
                        .font(DS.Font.ui(17))
                        .foregroundStyle(DS.Colors.muted)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .id(page)
                .transition(.opacity)

                Spacer()

                // Page dots
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? DS.Colors.ink : DS.Colors.line)
                            .frame(width: i == page ? 20 : 6, height: 6)
                    }
                }
                .padding(.bottom, 24)

                if page < pages.count - 1 {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { page += 1 }
                    } label: {
                        Text(AL.s(.hcNext))
                    }
                    .buttonStyle(InkButtonStyle())
                } else {
                    Button {
                        onDismiss()
                    } label: {
                        Text(AL.s(.hcLetsStart))
                    }
                    .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .animation(.easeOut(duration: 0.25), value: page)
    }
}

#Preview {
    AIQuizView()
}
