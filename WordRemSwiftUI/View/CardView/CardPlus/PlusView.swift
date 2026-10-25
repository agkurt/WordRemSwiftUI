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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: Title & Subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AL.s(.deckCreateTitle))
                            .font(DS.Font.display(32, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                        Text(AL.s(.deckCreateSubtitle))
                            .font(DS.Font.ui(16))
                            .foregroundStyle(DS.Colors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    // MARK: Flag Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: AL.s(.deckChooseFlag), color: DS.Colors.muted)
                        FlagSelectionView(selectedFlag: $viewModel.selectedFlag)
                    }

                    // MARK: Language Cards
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: AL.s(.deckLanguages), color: DS.Colors.muted)

                        HStack(spacing: 12) {
                            LanguagePickerCard(title: AL.s(.deckSource), selection: $viewModel.sourceLanguage)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(DS.Colors.muted)
                                .font(.system(size: 14, weight: .semibold))
                            LanguagePickerCard(title: AL.s(.deckTarget), selection: $viewModel.targetLanguage)
                        }
                    }

                    // MARK: Deck Name
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: AL.s(.deckName), color: DS.Colors.muted)

                        TextField("", text: $viewModel.cardName,
                                  prompt: Text(AL.s(.deckNamePlaceholder)).foregroundStyle(DS.Colors.muted))
                            .font(DS.Font.ui(17))
                            .foregroundStyle(DS.Colors.ink)
                            .tint(DS.Colors.accent)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Colors.line, lineWidth: 1))
                    }

                    // MARK: Create Button
                    Button {
                        Task {
                            await viewModel.addCardNameInfo()
                        }
                        dismiss()
                    } label: {
                        Text(AL.s(.deckCreate))
                    }
                    .buttonStyle(InkButtonStyle(fill: viewModel.cardName.isEmpty ? DS.Colors.line : DS.Colors.ink,
                                                foreground: viewModel.cardName.isEmpty ? DS.Colors.muted : DS.Colors.paperRaised))
                    .disabled(viewModel.cardName.isEmpty)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 8)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) {
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

private struct LanguagePickerCard: View {
    let title: String
    @Binding var selection: Language

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(DS.Font.ui(12, weight: .medium))
                .foregroundStyle(DS.Colors.muted)
            Picker("", selection: $selection) {
                ForEach(Language.allCases, id: \.self) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            }
            .pickerStyle(.menu)
            .tint(DS.Colors.ink)
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Colors.line, lineWidth: 1))
    }
}
