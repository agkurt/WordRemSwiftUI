//
//  TranslateView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import SwiftUI

struct TranslationView: View {
    @StateObject var viewModel = TranslateViewModel()
    @State private var inputText: String = ""
    @State private var sourceLang: Language = .english
    @State private var targetLang: Language = .turkish
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    @FocusState private var isInputFocused: Bool
    @AppStorage("userTargetLanguage") private var userTargetLanguageCode: String = "TR"
    @AppStorage("userNativeLanguage") private var userNativeLanguageCode: String = "EN"
    
    private let maxCharacters = 5000
    
    var body: some View {
        ZStack {
            LinearBackgroundView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Language Selector Bar
                    HStack(spacing: 12) {
                        // Source Language Button
                        Button(action: { showSourcePicker = true }) {
                            HStack(spacing: 8) {
                                // Use plain Text for emoji flag to fix rendering
                                Text(sourceLang.flag)
                                    .font(.system(size: 22))
                                Text(sourceLang.shortName)
                                    .font(.custom("Feather-Bold", size: 15))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
                            )
                        }
                        
                        // Swap Button
                        Button(action: swapLanguages) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.primaryOrange)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.cardBackground)
                                        .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
                                )
                        }
                        
                        // Target Language Button
                        Button(action: { showTargetPicker = true }) {
                            HStack(spacing: 8) {
                                // Use plain Text for emoji flag to fix rendering
                                Text(targetLang.flag)
                                    .font(.system(size: 22))
                                Text(targetLang.shortName)
                                    .font(.custom("Feather-Bold", size: 15))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // MARK: - Input Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("From: \(sourceLang.rawValue)")
                                .font(.custom("Feather-Bold", size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Spacer()
                            
                            if !inputText.isEmpty {
                                Button(action: clearInput) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .font(.system(size: 18))
                                }
                            }
                        }
                        
                        ZStack(alignment: .topLeading) {
                            if inputText.isEmpty {
                                Text("Enter text to translate...")
                                    .font(.custom("Feather-Bold", size: 16))
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: $inputText)
                                .font(.custom("Feather-Bold", size: 16))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 120, maxHeight: 200)
                                .focused($isInputFocused)
                                .onChange(of: inputText) { newValue in
                                    if newValue.count > maxCharacters {
                                        inputText = String(newValue.prefix(maxCharacters))
                                    }
                                    viewModel.triggerTranslation(
                                        text: inputText,
                                        sourceLang: sourceLang.code,
                                        targetLang: targetLang.code
                                    )
                                }
                        }
                        
                        HStack {
                            Text("\(inputText.count) / \(maxCharacters)")
                                .font(.custom("Feather-Bold", size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Spacer()
                            
                            if !inputText.isEmpty {
                                Button(action: pasteFromClipboard) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Paste")
                                    }
                                    .font(.custom("Feather-Bold", size: 12))
                                    .foregroundColor(AppTheme.Colors.primaryOrange)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.Colors.inputBorder, lineWidth: 1)
                            )
                            .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Translation Indicator
                    if viewModel.isTranslating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(AppTheme.Colors.primaryOrange)
                            Text("Translating...")
                                .font(.custom("Feather-Bold", size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // MARK: - Output Card
                    if !viewModel.translatedText.isEmpty || viewModel.isTranslating {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("To: \(targetLang.rawValue)")
                                    .font(.custom("Feather-Bold", size: 14))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Spacer()
                                
                                if !viewModel.translatedText.isEmpty {
                                    Button(action: copyToClipboard) {
                                        HStack(spacing: 6) {
                                            Image(systemName: viewModel.showCopiedConfirmation ? "checkmark" : "doc.on.doc")
                                            Text(viewModel.showCopiedConfirmation ? "Copied" : "Copy")
                                        }
                                        .font(.custom("Feather-Bold", size: 12))
                                        .foregroundColor(viewModel.showCopiedConfirmation ? .green : AppTheme.Colors.primaryOrange)
                                    }
                                }
                            }
                            
                            if viewModel.isTranslating {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(AppTheme.Colors.primaryOrange)
                                    Spacer()
                                }
                                .frame(height: 100)
                            } else {
                                Text(viewModel.translatedText)
                                    .font(.custom("Feather-Bold", size: 16))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.Colors.primaryOrange.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Translator")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load saved target language
            if let targetLang = Language.allCases.first(where: { $0.code == userTargetLanguageCode }) {
                self.targetLang = targetLang
            }
        }
        .sheet(isPresented: $showSourcePicker) {
            LanguagePickerSheet(
                selectedLanguage: $sourceLang,
                title: "Source Language"
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTargetPicker) {
            LanguagePickerSheet(
                selectedLanguage: $targetLang,
                title: "Target Language"
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Translation Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Helper Functions
    
    private func swapLanguages() {
        withAnimation(.spring(response: 0.3)) {
            let temp = sourceLang
            sourceLang = targetLang
            targetLang = temp
            
            // Swap texts too
            if !viewModel.translatedText.isEmpty {
                let tempText = inputText
                inputText = viewModel.translatedText
                viewModel.translatedText = tempText
            }
        }
    }
    
    private func clearInput() {
        withAnimation {
            inputText = ""
            viewModel.clearTranslatedText()
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            inputText = clipboardText
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = viewModel.translatedText
        viewModel.showCopyConfirmation()
    }
}

// MARK: - Language Picker Sheet

struct LanguagePickerSheet: View {
    @Binding var selectedLanguage: Language
    @Environment(\.dismiss) private var dismiss
    let title: String
    @State private var searchText = ""
    
    private var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return Language.allCases
        }
        return Language.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        TextField("Search languages...", text: $searchText)
                            .font(.custom("Feather-Bold", size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .autocapitalization(.none)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                            .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
                    )
                    .padding()
                    
                    // Language List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredLanguages, id: \.self) { language in
                                Button(action: {
                                    selectedLanguage = language
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        Text(language.flag)
                                            .font(.system(size: 28))
                                        
                                        Text(language.rawValue)
                                            .font(.custom("Feather-Bold", size: 16))
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        if language == selectedLanguage {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.Colors.primaryOrange)
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(
                                        language == selectedLanguage
                                            ? AppTheme.Colors.primaryOrange.opacity(0.1)
                                            : Color.clear
                                    )
                                }
                                
                                Divider()
                                    .background(AppTheme.Colors.inputBorder)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundColor(AppTheme.Colors.primaryOrange)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TranslationView()
    }
}
