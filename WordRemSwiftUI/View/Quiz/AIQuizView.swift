//
//  AIQuizView.swift
//  WordRemSwiftUI
//
//  AI-powered quiz launcher: topic grid → question count → loading → quiz.
//

import SwiftUI
import Lottie

struct AIQuizView: View {
    @StateObject private var vm = AIQuizViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showQuiz = false
    @State private var readyQuestions: [GameQuestion] = []
    @State private var readyTitle: String = ""

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
                        readyQuestions = questions
                        readyTitle = title
                        showQuiz = true
                    }
                case .error(let msg):
                    errorView(msg)
                }
            }
        }
        .fullScreenCover(isPresented: $showQuiz, onDismiss: { vm.reset() }) {
            GameQuizView(
                sessionType: .aiGenerated(title: readyTitle),
                title: readyTitle,
                preloadedQuestions: readyQuestions
            )
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
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if case .selectCount(let topic) = vm.state {
                    Text(topic.rawValue)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("Grammar & Vocabulary Practice")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "sparkles").font(.system(size: 11, weight: .semibold))
                Text("GPT-4o").font(.custom("Poppins-SemiBold", size: 11))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#8b5cf6"), Color(hex: "#6366f1")],
                    startPoint: .leading, endPoint: .trailing
                ),
                in: Capsule()
            )
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
            VStack(alignment: .leading, spacing: 24) {
                ForEach(AIQuizTopicCategory.allCases, id: \.self) { cat in
                    let topics = AIQuizTopic.allCases.filter { $0.category == cat }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(cat.rawValue)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, 20)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(topics) { topic in
                                TopicCard(topic: topic) { vm.selectTopic(topic) }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
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
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(topic.rawValue)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    private func countPickerButtons(topic: AIQuizTopic) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(vm.questionCounts.enumerated()), id: \.offset) { idx, count in
                CountButton(
                    count: count,
                    isSelected: vm.selectedCountIndex == idx,
                    gradientColors: topic.gradientColors
                ) {
                    withAnimation(.spring(response: 0.3)) { vm.selectedCountIndex = idx }
                }
            }
        }
    }

    private func generateButton(topic: AIQuizTopic) -> some View {
        Button { vm.startGeneration(topic: topic) } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").font(.system(size: 15, weight: .semibold))
                Text("Generate Quiz").font(.custom("Poppins-SemiBold", size: 16))
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
            LottieView(animation: .named("StartAnimation"))
                .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .frame(width: 120, height: 120)
            VStack(spacing: 8) {
                Text("Preparing your quiz...")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text("\(count) questions about\n\(topic.rawValue)")
                    .font(.custom("Poppins-Regular", size: 14))
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
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(msg)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                vm.reset()
            } label: {
                Text("Try Again")
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.primaryOrange, in: Capsule())
            }
            Spacer()
        }
    }
}

// MARK: - Count Button
private struct CountButton: View {
    let count: Int
    let isSelected: Bool
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)").font(.custom("Poppins-Bold", size: 24))
                Text("soru").font(.custom("Poppins-Regular", size: 11))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
            .frame(width: 72, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected
                        ? AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.white)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.12), lineWidth: 1)
            )
            .shadow(
                color: isSelected ? (gradientColors.first?.opacity(0.35) ?? .clear) : Color.black.opacity(0.06),
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
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: topic.gradientColors.map { $0.opacity(0.15) },
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
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
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

#Preview {
    AIQuizView()
}
