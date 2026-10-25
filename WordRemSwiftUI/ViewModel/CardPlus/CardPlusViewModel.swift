//
//  CardTextFieldViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

@MainActor
final class CardPlusViewModel: ObservableObject {
    
    @Published var wordName: String = ""
    @Published var wordMean: String = ""
    @Published var wordDescription: String = ""
    @Published var examplesWord:ExampleWord?
    @Published var isDelete = false
    @Published var sourceLang:[String] = []
    @Published var targetLang:[String] = []
    @Published var translatedText = ""
    @Published var isLoading = false
    @Published var isLoadingSentence = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    func addWordToCard(cardId:String) async {
        // SWAP: wordName ve wordMean yerlerini değiştir
        // ÖN YÜZ (cümlenin olduğu) = wordMean (Fransızca - "cousin")
        // ARKA YÜZ = wordName (Türkçe - "kuzen")
        await DeckService.shared.addWordToCard(
            cardId: cardId, 
            wordName: wordMean,        // ÖN YÜZ: Fransızca kelime
            wordMean: wordName,        // ARKA YÜZ: Türkçe anlam
            wordDescription: wordDescription  // Fransızca örnek cümle
        )
    }
    
    func updateWord(cardId: String, wordId: String) async {
        // Update existing word
        await DeckService.shared.updateWordInCard(
            cardId: cardId,
            wordId: wordId,
            wordName: wordMean,        // ÖN YÜZ: Fransızca kelime
            wordMean: wordName,        // ARKA YÜZ: Türkçe anlam
            wordDescription: wordDescription
        )
    }
    
    func createSentenceUseToWord(name:String) async {
        isLoadingSentence = true
        errorMessage = nil
        showError = false
        
        do {
            // targetLang kullan çünkü cümle öğrenilen dilde (Fransızca) olmalı
            // ve wordMean (çevrilmiş kelime - "cousin") cümlede kullanılmalı
            let languageCode = targetLang.first ?? "EN"
            let wordToUse = wordMean.isEmpty ? name : wordMean // Çevrilmiş kelimeyi kullan (Fransızca)
            let sentence = try await generateExampleSentenceWithGemini(word: wordToUse, languageCode: languageCode)
            self.wordDescription = sentence
            self.isLoadingSentence = false
        } catch {
            print("❌ Example sentence error: \(error)")
            self.errorMessage = "Could not generate example sentence. Please try again."
            self.showError = true
            self.isLoadingSentence = false
        }
    }
    
    private func generateExampleSentenceWithGemini(word: String, languageCode: String) async throws -> String {
        
        let languageName = getLanguageName(code: languageCode)
        
        let prompt = """
        Generate ONE short example sentence using the word "\(word)" in \(languageName).
        
        Requirements:
        - The sentence MUST be in \(languageName) language
        - The sentence must be SHORT (10-15 words maximum)
        - The sentence should be clear, natural, and educational
        - Make sure the word "\(word)" appears in the sentence
        - Return ONLY the sentence in \(languageName), without any numbering, bullets, or extra text
        - Do not include quotation marks
        - Do not translate the sentence to any other language
        
        Example format (in \(languageName)):
        [A short sentence using the word in \(languageName)]
        """
        
        let text = try await AIEngine.complete(instructions: "You are a helpful language tutor.", prompt: prompt)
        
        // Clean up the sentence
        let cleanedSentence = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .components(separatedBy: .newlines)
            .first ?? text
        
        return cleanedSentence.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func fetchLanguageInfo(cardId:String) async {
        do {
            let fetch = try await DeckService.shared.fetchSourceAndTargetLang(cardId: cardId)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.sourceLang = fetch.map { $0.sourceLang ?? ""}
                self.targetLang = fetch.map { $0.targetLang ?? ""}
            }
        }catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    func translateForWordName(targetLang:String, sourceLang:String,text:String) async {
        self.isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // text (wordName) native dilde (sourceLang) yazılmış
            // Onu öğrenilen dile (targetLang) çeviriyoruz
            // Örnek: "kuzen" (TR) → "cousin" (FR)
            let translation = try await translateWithGemini(word: text, sourceLang: sourceLang, targetLang: targetLang)
            self.translatedText = translation
            self.wordMean = translation
            self.isLoading = false
        } catch {
            print("❌ Translation error: \(error)")
            self.errorMessage = "Could not translate. Please try again."
            self.showError = true
            self.isLoading = false
        }
    }
    
    private func translateWithGemini(word: String, sourceLang: String, targetLang: String) async throws -> String {
        
        // Map language codes to full names
        let sourceLangName = getLanguageName(code: sourceLang)
        let targetLangName = getLanguageName(code: targetLang)
        
        let prompt = """
        Translate the following word from \(sourceLangName) to \(targetLangName):
        
        Word: "\(word)"
        
        Requirements:
        - Return ONLY the translated word
        - If it's a single word, return a single word translation (the most common meaning)
        - Do not include the original word
        - Do not include any explanation or extra text
        - Do not include quotation marks
        - Just return the translation
        
        Translation:
        """
        
        let text = try await AIEngine.complete(instructions: "You are a helpful language tutor.", prompt: prompt)
        
        // Clean up the translation - get first word/line only
        let cleanedTranslation = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .components(separatedBy: .newlines)
            .first?
            .components(separatedBy: " ")
            .prefix(3) // Max 3 words
            .joined(separator: " ") ?? text
        
        return cleanedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func getLanguageName(code: String) -> String {
        switch code.uppercased() {
        case "EN": return "English"
        case "TR": return "Turkish"
        case "ES": return "Spanish"
        case "FR": return "French"
        case "DE": return "German"
        case "IT": return "Italian"
        case "PT": return "Portuguese"
        case "RU": return "Russian"
        case "JA": return "Japanese"
        case "KO": return "Korean"
        case "ZH": return "Chinese"
        case "AR": return "Arabic"
        default: return code
        }
    }
}

