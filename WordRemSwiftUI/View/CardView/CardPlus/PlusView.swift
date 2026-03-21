//
//  PlusView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct PlusView: View {

    @StateObject var viewModel = PlusViewModel()
    @Environment(\.dismiss) private var dismiss
    var completion: () -> Void

    @State private var animateIn = false

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearBackgroundView()

                // Decorative blobs
                Circle()
                    .fill(AppTheme.Colors.primaryOrange.opacity(0.08))
                    .frame(width: 260, height: 260)
                    .blur(radius: 60)
                    .offset(x: 120, y: -180)
                    .allowsHitTesting(false)

                Circle()
                    .fill(AppTheme.Colors.primaryOrange.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: -130, y: 200)
                    .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // MARK: Title & Subtitle
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Create a New Deck")
                                .font(.custom("Feather-Bold", size: 30))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Choose a flag and give your deck a memorable name.")
                                .font(.custom("Feather-Bold", size: 15))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .padding(.trailing, 20)
                        }
                        .padding(.top, 8)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)

                        // MARK: Flag Selection
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(icon: "flag.fill", title: "Choose Flag")
                            FlagSelectionView(selectedFlag: $viewModel.selectedFlag)
                                .padding(.horizontal, -4)
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)

                        // MARK: Language Cards
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(icon: "globe", title: "Translation Languages")

                            HStack(spacing: 12) {
                                // Source
                                LanguagePickerCard(
                                    title: "Source",
                                    selection: $viewModel.sourceLanguage,
                                    icon: "arrow.up.right"
                                )
                                // Arrow
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                                    .font(.system(size: 16, weight: .semibold))

                                // Target
                                LanguagePickerCard(
                                    title: "Target",
                                    selection: $viewModel.targetLanguage,
                                    icon: "arrow.down.left"
                                )
                            }
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)

                        // MARK: Deck Name
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Deck Name")
                                .font(.custom("Feather-Bold", size: 16))
                                .foregroundStyle(AppTheme.Colors.textPrimary)

                            ZStack(alignment: .leading) {
                                if viewModel.cardName.isEmpty {
                                    Text("E.g. Spanish Basics, Useful Verbs")
                                        .font(.custom("Feather-Bold", size: 16))
                                        .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))
                                }
                                TextField("", text: $viewModel.cardName)
                                    .font(.custom("Feather-Bold", size: 16))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                    .tint(AppTheme.Colors.primaryOrange)
                                    .autocorrectionDisabled()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                            )
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)

                        // MARK: Create Button
                        Button {
                            Task {
                                await viewModel.addCardNameInfo()
                            }
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Create Deck")
                                    .font(.custom("Feather-Bold", size: 16))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                viewModel.cardName.isEmpty
                                ? AnyShapeStyle(AppTheme.Colors.textSecondary.opacity(0.3)) // Disabled look
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(
                                color: viewModel.cardName.isEmpty ? .clear : AppTheme.Shadows.vibrantColor,
                                radius: AppTheme.Shadows.vibrantRadius, y: AppTheme.Shadows.vibrantY
                            )
                        }
                        .disabled(viewModel.cardName.isEmpty)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)
                        .animation(.spring(response: 0.35), value: viewModel.cardName.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(8)
                            .background(Circle().fill(AppTheme.Colors.cardBackground.opacity(0.8)))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateIn = true
                }
            }
            .onDisappear {
                completion()
                animateIn = false
            }
        }
    }
}

// MARK: - Helper Views

private struct SectionLabel: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryOrange)
            Text(title)
                .font(.custom("Feather-Bold", size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

private struct LanguagePickerCard: View {
    let title: String
    @Binding var selection: Language
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                Text(title)
                    .font(.custom("Feather-Bold", size: 10))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Picker("", selection: $selection) {
                ForEach(Language.allCases, id: \.self) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.Colors.primaryOrange)
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.Colors.cardBackground.opacity(0.5))
        )
    }
}
