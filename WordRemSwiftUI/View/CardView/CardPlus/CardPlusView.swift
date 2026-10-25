//
//  CardPlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardPlusView: View {
    
    @StateObject private var viewModel = CardPlusViewModel()
    @StateObject private var reminderViewModel = ReminderViewModel()
    @Environment(\.dismiss) private var dismiss
    @State var isLoading = false
    @State var cardId: String
    @State private var isOnToggle = false
    
    // Edit mode properties
    var editMode: Bool = false
    var editWordId: String = ""
    var editWordName: String = ""
    var editWordMean: String = ""
    var editWordDescription: String = ""
    var completion: (() -> Void)?

    init(cardId: String, editMode: Bool = false, editWordId: String = "", editWordName: String = "", editWordMean: String = "", editWordDescription: String = "", completion: (() -> Void)? = nil) {
        self.cardId = cardId
        self.editMode = editMode
        self.editWordId = editWordId
        self.editWordName = editWordName
        self.editWordMean = editWordMean
        self.editWordDescription = editWordDescription
        self.completion = completion
    }
    
    private var canSave: Bool { !(viewModel.wordName.isEmpty || viewModel.wordMean.isEmpty) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // MARK: - Title
                    Text(editMode ? "Edit Your Word" : "Create Your Word")
                        .font(DS.Font.display(32, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    // MARK: - Word Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        PaperTextField(text: $viewModel.wordName, label: "Word (in your native language)", serif: true)

                        if viewModel.isLoading {
                            LoadingRow(text: "Translating...")
                        } else {
                            SmallOutlineButton(title: "Translate", icon: "arrow.left.arrow.right",
                                               enabled: !viewModel.wordName.isEmpty) {
                                guard !viewModel.wordName.isEmpty else { return }
                                Task {
                                    await viewModel.translateForWordName(
                                        targetLang: viewModel.targetLang.first ?? "",
                                        sourceLang: viewModel.sourceLang.first ?? "",
                                        text: viewModel.wordName
                                    )
                                }
                            }
                            .disabled(viewModel.wordName.isEmpty)
                        }

                        PaperTextField(text: $viewModel.wordMean, label: "Translation (in learning language)")
                    }

                    // MARK: - Example Sentence Section
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.isLoadingSentence {
                            LoadingRow(text: "Generating sentence...")
                        } else {
                            SmallOutlineButton(title: "Generate Example Sentence", icon: "text.quote",
                                               enabled: !viewModel.wordMean.isEmpty) {
                                guard !viewModel.wordMean.isEmpty else { return }
                                Task {
                                    await viewModel.createSentenceUseToWord(name: viewModel.wordMean)
                                }
                            }
                            .disabled(viewModel.wordName.isEmpty)
                        }

                        PaperTextField(text: $viewModel.wordDescription, label: "Example Sentence")
                    }

                    // MARK: - Reminder Section
                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(isOn: $isOnToggle) {
                            Text("Reminder")
                                .font(DS.Font.ui(16, weight: .semibold))
                                .foregroundStyle(DS.Colors.ink)
                        }
                        .tint(DS.Colors.accent)
                        .padding(.vertical, 14)

                        if isOnToggle {
                            Hairline()
                            DatePicker(
                                "Reminder Date & Time",
                                selection: $reminderViewModel.date,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .tint(DS.Colors.accent)
                            .font(DS.Font.ui(15))
                            .foregroundStyle(DS.Colors.ink)
                            .padding(.vertical, 12)

                            Hairline()
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Repeat")
                                    .font(DS.Font.ui(13, weight: .medium))
                                    .foregroundStyle(DS.Colors.muted)
                                Picker("Repeat", selection: $reminderViewModel.repeatOption) {
                                    ForEach(reminderViewModel.repeatOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 14)

                            if reminderViewModel.repeatOption != "None" {
                                Hairline()
                                Stepper(
                                    value: $reminderViewModel.repeatValue,
                                    in: 1...5
                                ) {
                                    Text("Repeat every \(reminderViewModel.repeatValue) \(reminderViewModel.repeatOption.lowercased())")
                                        .font(DS.Font.ui(15))
                                        .foregroundStyle(DS.Colors.ink)
                                }
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Colors.line, lineWidth: 1))

                    // MARK: - Save
                    VStack(spacing: 10) {
                        Button(editMode ? "Save" : "Add Word") { save() }
                            .buttonStyle(InkButtonStyle(fill: canSave ? DS.Colors.ink : DS.Colors.line,
                                                        foreground: canSave ? DS.Colors.paperRaised : DS.Colors.muted))
                            .disabled(!canSave)
                        Button("Cancel") { dismiss() }
                            .buttonStyle(OutlineButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .paperBackground()
            .onAppear {
                Task {
                    await viewModel.fetchLanguageInfo(cardId: cardId)
                    await reminderViewModel.notificationManager.request()

                    // If edit mode, populate fields
                    if editMode {
                        viewModel.wordName = editWordName
                        viewModel.wordMean = editWordMean
                        viewModel.wordDescription = editWordDescription
                    }
                }
            }
            .onDisappear {
                self.completion?()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
                    viewModel.showError = false
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { save() } label: {
                        Text("Done")
                            .foregroundStyle(canSave ? DS.Colors.accent : DS.Colors.muted)
                            .font(DS.Font.ui(16, weight: .semibold))
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        Task {
            if editMode {
                // Update existing word
                await viewModel.updateWord(cardId: cardId, wordId: editWordId)
            } else {
                // Add new word
                await viewModel.addWordToCard(cardId: cardId)
            }

            if isOnToggle {
                await reminderViewModel.sendNotifications(
                    title: viewModel.wordName,
                    body: viewModel.wordDescription
                )
            }

            completion?()
        }
        dismiss()
    }
}


// MARK: - Components

private struct Hairline: View {
    var body: some View { Rectangle().fill(DS.Colors.line).frame(height: 1) }
}

private struct LoadingRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            ProgressView().tint(DS.Colors.muted)
            Text(text)
                .font(DS.Font.ui(14))
                .foregroundStyle(DS.Colors.muted)
        }
        .frame(height: 40)
    }
}

private struct SmallOutlineButton: View {
    let title: String
    let icon: String
    let enabled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(DS.Font.ui(15, weight: .semibold))
            }
            .foregroundStyle(enabled ? DS.Colors.ink : DS.Colors.muted)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Colors.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

private struct PaperTextField: View {
    @Binding var text: String
    let label: String
    var serif: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(DS.Font.ui(13, weight: .medium))
                .foregroundStyle(DS.Colors.muted)
            TextField("", text: $text)
                .font(serif ? DS.Font.display(20, weight: .regular) : DS.Font.ui(17))
                .foregroundStyle(DS.Colors.ink)
                .tint(DS.Colors.accent)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? DS.Colors.inkSoft : DS.Colors.line, lineWidth: 1)
                )
        }
    }
}

struct CardPlusView_Previews: PreviewProvider {
    static var previews: some View {
        CardPlusView(cardId: "your_card_id_here", completion: {})
    }
}
