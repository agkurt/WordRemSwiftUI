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
    @State private var coverIndex = 0
    @State private var bump = 0
    @FocusState private var nameFocused: Bool

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    private var trimmedName: String { viewModel.cardName.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: NoteText.newEyebrow, color: DS.Colors.accentText)
                        Text(NoteText.createTitle)
                            .font(DS.Font.display(30, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(NoteText.createSub)
                            .font(.system(size: 16, design: .serif).italic())
                            .foregroundStyle(DS.Colors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)

                    // Canlı önizleme: yazdıkça etiket dolar, renk seçtikçe kapak değişir
                    notebookPreview
                        .padding(.horizontal, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: NoteText.cover, color: DS.Colors.accentText)
                        coverSwatches
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: NoteText.sticker, color: DS.Colors.accentText)
                        FlagSelectionView(selectedFlag: $viewModel.selectedFlag)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: NoteText.languages, color: DS.Colors.accentText)
                        HStack(alignment: .bottom, spacing: 14) {
                            LanguagePickerCard(title: AL.s(.deckSource), selection: $viewModel.sourceLanguage)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(DS.Colors.muted)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.bottom, 14)
                            LanguagePickerCard(title: AL.s(.deckTarget), selection: $viewModel.targetLanguage)
                        }
                    }

                    Button {
                        CardView.saveCover(coverIndex, for: trimmedName)
                        viewModel.cardName = trimmedName
                        Haptics.success()
                        Task { await viewModel.addCardNameInfo() }
                        dismiss()
                    } label: {
                        Label(NoteText.create, systemImage: "book.closed")
                    }
                    .buttonStyle(InkButtonStyle(fill: trimmedName.isEmpty ? DS.Colors.line : DS.Colors.ink,
                                                foreground: trimmedName.isEmpty ? DS.Colors.muted : DS.Colors.paperRaised))
                    .disabled(trimmedName.isEmpty)
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
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) { animateIn = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nameFocused = true }
            }
            .onDisappear {
                completion()
                animateIn = false
            }
        }
    }

    /// Gerçek bir defter: bez kapak, solda sırt, sağda lastik bant, ortada etiket, köşede çıkartma, alttan sarkan ayraç
    private var notebookPreview: some View {
        let color = CardView.covers[coverIndex]
        let shape = UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6, bottomTrailingRadius: 16, topTrailingRadius: 16)
        return ZStack(alignment: .topLeading) {
            NotebookCover(color: color)
                .clipShape(shape)
            // Lastik bant
            Rectangle()
                .fill(Color.black.opacity(0.28))
                .frame(width: 9)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 26)
                .clipShape(shape)
            // Etiket: ad çizgiye yazılır, altında diller
            VStack(alignment: .leading, spacing: 10) {
                Text(NoteText.nameField)
                    .font(DS.Font.ui(11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(DS.Colors.muted)
                TextField("", text: $viewModel.cardName,
                          prompt: Text(NoteText.namePlaceholder).foregroundStyle(DS.Colors.muted.opacity(0.7)))
                    .font(DS.Font.display(24, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .tint(DS.Colors.accent)
                    .autocorrectionDisabled()
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .padding(.bottom, 4)
                    .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.inkSoft.opacity(0.5)).frame(height: 1) }
                Text("\(viewModel.sourceLanguage.rawValue)  →  \(viewModel.targetLanguage.rawValue)")
                    .font(.system(size: 14, design: .serif).italic())
                    .foregroundStyle(DS.Colors.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).inset(by: 4).stroke(DS.Colors.line, lineWidth: 1))
            .rotationEffect(.degrees(-1.2))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 5)
            .padding(.leading, 44)
            .padding(.trailing, 50)
            .frame(maxHeight: .infinity)
            // Çıkartma: kapağın sol üstüne yapıştırılmış bayrak
            Image(viewModel.selectedFlag.rawValue)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .overlay(Circle().stroke(DS.Colors.paperRaised, lineWidth: 3.5))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                .rotationEffect(.degrees(-10))
                .padding(.leading, 40)
                .padding(.top, 16)
                .id(viewModel.selectedFlag)
                .transition(.scale(scale: 1.5).combined(with: .opacity))
                .accessibilityHidden(true)
        }
        .frame(height: 250)
        // Alttan sarkan tek ayraç
        .overlay(alignment: .bottomTrailing) {
            RibbonShape().fill(DS.Colors.accent)
                .frame(width: 13, height: 46)
                .offset(y: 38)
                .padding(.trailing, 64)
        }
        .padding(.bottom, 38)
        .rotationEffect(.degrees(-1))
        .shadow(color: Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.18), radius: 14, y: 10)
        .phaseAnimator([1.0, 1.035, 1.0], trigger: bump) { v, scale in v.scaleEffect(scale) }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.selectedFlag)
        .animation(.easeOut(duration: 0.25), value: coverIndex)
    }

    /// Kapak bezleri: seçilen halkalı ve hafif eğik
    private var coverSwatches: some View {
        HStack(spacing: 14) {
            ForEach(CardView.covers.indices, id: \.self) { i in
                let on = i == coverIndex
                Button {
                    coverIndex = i
                    bump += 1
                    Haptics.tap()
                } label: {
                    UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 3, bottomTrailingRadius: 7, topTrailingRadius: 7)
                        .fill(CardView.covers[i])
                        .frame(width: 34, height: 44)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.18)).frame(width: 3).padding(.leading, 5)
                        }
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(on ? DS.Colors.accent : .clear, lineWidth: 2))
                        .rotationEffect(.degrees(on ? -6 : 0))
                        .scaleEffect(on ? 1.08 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: on)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
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
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Altı çizili alan (dolu kutu yerine)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.Colors.line).frame(height: 1)
        }
    }
}
