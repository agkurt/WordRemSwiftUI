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
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - Title
                        Text(editMode ? "Edit Your Word" : "Create Your Word")
                            .font(.custom("Feather-Bold", size: 28))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        
                        // MARK: - Word Input Section
                        VStack(alignment: .leading, spacing: 16) {
                            ModernTextField(text: $viewModel.wordName, placeholder: "Word (in your native language)", icon: "textformat.abc")
                            
                            // Translate Button
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(AppTheme.Colors.primaryOrange)
                                    Text("Translating...")
                                        .font(.custom("Feather-Bold", size: 14))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                                .padding(.vertical, 8)
                            } else {
                                Button {
                                    guard !viewModel.wordName.isEmpty else { return }
                                    Task {
                                        await viewModel.translateForWordName(
                                            targetLang: viewModel.targetLang.first ?? "",
                                            sourceLang: viewModel.sourceLang.first ?? "",
                                            text: viewModel.wordName
                                        )
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Translate")
                                            .font(.custom("Feather-Bold", size: 15))
                                    }
                                    .foregroundStyle(viewModel.wordName.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.primaryOrange)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppTheme.Colors.cardBackground)
                                            .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                                    )
                                }
                                .disabled(viewModel.wordName.isEmpty)
                            }
                            
                            ModernTextField(text: $viewModel.wordMean, placeholder: "Translation (in learning language)", icon: "book.fill")
                        }
                        
                        // MARK: - Example Sentence Section
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.isLoadingSentence {
                                HStack {
                                    ProgressView()
                                        .tint(AppTheme.Colors.primaryOrange)
                                    Text("Generating sentence...")
                                        .font(.custom("Feather-Bold", size: 14))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                                .padding(.vertical, 8)
                            } else {
                                Button {
                                    guard !viewModel.wordMean.isEmpty else { return }
                                    Task {
                                        await viewModel.createSentenceUseToWord(name: viewModel.wordMean)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "text.quote")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Generate Example Sentence")
                                            .font(.custom("Feather-Bold", size: 15))
                                    }
                                    .foregroundStyle(
                                        !viewModel.wordMean.isEmpty
                                        ? AppTheme.Colors.primaryOrange
                                        : AppTheme.Colors.textSecondary
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppTheme.Colors.cardBackground)
                                            .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                                    )
                                }
                                .disabled(viewModel.wordName.isEmpty)
                            }
                            
                            ModernTextField(text: $viewModel.wordDescription, placeholder: "Example Sentence", icon: "text.alignleft")
                        }
                        
                        // MARK: - Reminder Section
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $isOnToggle) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                                    Text("Reminder")
                                        .font(.custom("Feather-Bold", size: 16))
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                }
                            }
                            .tint(AppTheme.Colors.primaryOrange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                            )
                            
                            if isOnToggle {
                                VStack(spacing: 16) {
                                    // Date Picker
                                    DatePicker(
                                        "Reminder Date & Time",
                                        selection: $reminderViewModel.date,
                                        in: Date()...,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .datePickerStyle(.compact)
                                    .tint(AppTheme.Colors.primaryOrange)
                                    .font(.custom("Feather-Bold", size: 15))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(AppTheme.Colors.cardBackground)
                                            .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                                    )
                                    
                                    // Repeat Options
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Repeat")
                                            .font(.custom("Feather-Bold", size: 14))
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                        
                                        Picker("Repeat", selection: $reminderViewModel.repeatOption) {
                                            ForEach(reminderViewModel.repeatOptions, id: \.self) { option in
                                                Text(option).tag(option)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .tint(AppTheme.Colors.primaryOrange)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(AppTheme.Colors.cardBackground)
                                            .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                                    )
                                    
                                    // Repeat Value Stepper
                                    if reminderViewModel.repeatOption != "None" {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Frequency")
                                                .font(.custom("Feather-Bold", size: 14))
                                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                            
                                            Stepper(
                                                value: $reminderViewModel.repeatValue,
                                                in: 1...5
                                            ) {
                                                Text("Repeat every \(reminderViewModel.repeatValue) \(reminderViewModel.repeatOption.lowercased())")
                                                    .font(.custom("Feather-Bold", size: 15))
                                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                            }
                                            .tint(AppTheme.Colors.primaryOrange)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(AppTheme.Colors.cardBackground)
                                                .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                                        )
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
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
                    } label: {
                        Text("Done")
                            .foregroundStyle(
                                viewModel.wordName.isEmpty || viewModel.wordMean.isEmpty
                                ? AppTheme.Colors.textSecondary
                                : AppTheme.Colors.primaryOrange
                            )
                            .font(.custom("Feather-Bold", size: 16))
                    }
                    .disabled(viewModel.wordName.isEmpty || viewModel.wordMean.isEmpty)
                }
            }
        }
    }
}


// MARK: - Modern TextField Component
private struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isFocused ? AppTheme.Colors.primaryOrange : AppTheme.Colors.textSecondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                if isFocused || !text.isEmpty {
                    Text(placeholder)
                        .font(.custom("Feather-Bold", size: 11))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                TextField(isFocused || !text.isEmpty ? "" : placeholder, text: $text)
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .tint(AppTheme.Colors.primaryOrange)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: AppTheme.Shadows.softY)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isFocused ? AppTheme.Colors.primaryOrange.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct CardPlusView_Previews: PreviewProvider {
    static var previews: some View {
        CardPlusView(cardId: "your_card_id_here", completion: {})
    }
}


