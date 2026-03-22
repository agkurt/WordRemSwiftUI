//
//  TranslateViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import Foundation

@MainActor
final class TranslateViewModel: ObservableObject {
    @Published var translatedText: String = ""
    @Published var showAlert = false
    @Published var isTranslating = false
    @Published var showCopiedConfirmation = false
    @Published var errorMessage = "There was a problem translating the text. Please try again later."
    @Published var detectedSourceLang: String? = nil // Detected language
    
    private var translationTask: Task<Void, Never>?
    
    func triggerTranslation(text: String, sourceLang: String, targetLang: String, autoDetect: Bool = true) {
        // Cancel any existing translation
        translationTask?.cancel()
        
        // Clear if text is empty
        guard !text.isEmpty else {
            clearTranslatedText()
            return
        }
        
        // Debounce: wait 1.5 seconds before translating (increased from 0.5)
        translationTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            guard !Task.isCancelled else { return }
            
            // Use auto-detect if enabled, otherwise use sourceLang
            let sourceToUse = autoDetect ? "" : sourceLang
            await translate(text: text, sourceLang: sourceToUse, targetLang: targetLang)
        }
    }
    
    func translate(text: String, sourceLang: String, targetLang: String) async {
        isTranslating = true
        
        URLSessionApiService.shared.getTranslate(text: text, targetLang: targetLang, sourceLang: sourceLang) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isTranslating = false
                
                switch result {
                case .success(let translationResponse):
                    if let translation = translationResponse.translations.first {
                        self.translatedText = translation.text
                        // Store detected language
                        self.detectedSourceLang = translation.detected_source_language
                        print("✅ Detected language: \(translation.detected_source_language ?? "unknown")")
                    } else {
                        self.errorMessage = "No translation found."
                        self.showAlert = true
                    }
                case .failure(let error):
                    // Don't show alert for cancelled errors
                    let errorString = error.localizedDescription.lowercased()
                    if errorString.contains("cancelled") || errorString.contains("cancel") {
                        // Silently ignore cancelled errors
                        print("Translation cancelled (user still typing)")
                        return
                    }
                    
//                    if let apiError = error as? APIError {
//                        self.errorMessage = apiError.localizedDescription ?? "Unknown error occurred."
//                    } else {
//                        self.errorMessage = error.localizedDescription
//                    }
//                    self.showAlert = true
                }
            }
        }
    }
    
    func clearTranslatedText() {
        translatedText = ""
        isTranslating = false
        detectedSourceLang = nil
        translationTask?.cancel()
    }
    
    func showCopyConfirmation() {
        showCopiedConfirmation = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                showCopiedConfirmation = false
            }
        }
    }
}

