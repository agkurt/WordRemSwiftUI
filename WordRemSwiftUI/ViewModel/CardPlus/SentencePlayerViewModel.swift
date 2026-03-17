//
//  SentencePlayerViewModel.swift
//  WordRemSwiftUI
//
//  Created by AI Assistant on 14.03.2026.
//

import SwiftUI
import AVFoundation

@MainActor
final class SentencePlayerViewModel: NSObject, ObservableObject {
    
    @Published var isPlaying = false
    @Published var translatedSentence: String?
    @Published var wordAlignments: [String: (translation: String, colorIndex: Int)] = [:]
    @Published var isLoadingTranslation = false
    @Published var showTranslation = false
    
    private var synthesizer = AVSpeechSynthesizer()
    private var languageCode: String = "en-US"
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Text-to-Speech
    func speak(text: String, languageCode: String) {
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isPlaying = false
            return
        }
        
        self.languageCode = languageCode
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: getVoiceLanguageCode(code: languageCode))
        utterance.rate = 0.45 // Slightly slower for learning
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isPlaying = true
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isPlaying = false
        }
    }
    
    // MARK: - Sentence Translation with Word Alignment
    func translateSentence(_ sentence: String, fromLang: String, toLang: String) async {
        isLoadingTranslation = true
        showTranslation = true
        
        do {
            let result = try await translateSentenceWithAlignment(
                sentence: sentence,
                sourceLang: fromLang,
                targetLang: toLang
            )
            
            self.translatedSentence = result.translation
            self.wordAlignments = result.alignments
            self.isLoadingTranslation = false
        } catch {
            print("❌ Sentence translation error: \(error)")
            self.translatedSentence = "Translation unavailable"
            self.isLoadingTranslation = false
        }
    }
    
    func hideTranslation() {
        showTranslation = false
    }
    
    private func translateSentenceWithAlignment(sentence: String, sourceLang: String, targetLang: String) async throws -> (translation: String, alignments: [String: (translation: String, colorIndex: Int)]) {
        let apiKey = APIKey.geminiApi
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let sourceLangName = getLanguageName(code: sourceLang)
        let targetLangName = getLanguageName(code: targetLang)
        
        let prompt = """
        Translate this sentence from \(sourceLangName) to \(targetLangName) and provide word alignments.
        
        Sentence: "\(sentence)"
        
        IMPORTANT: Respond with EXACTLY 2 lines, no prefixes, no extra text:
        Line 1: Complete natural translation
        Line 2: word1:translation1, word2:translation2 (content words only)
        
        Example:
        Mon frère est plus grand que moi.
        Benim kardeşim benden daha büyüktür.
        frère:kardeşim, plus:daha, grand:büyük
        
        Now translate (2 lines only):
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 150  // Increased for complete sentences
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "API Error", code: -1)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: "Failed to parse response", code: -1)
        }
        
        // Parse response
        let rawText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("📝 Raw OpenAI Response:")
        print(rawText)
        
        // Remove any "Output line X:" prefixes that GPT might add
        let cleanedText = rawText
            .replacingOccurrences(of: "Output line 1:", with: "")
            .replacingOccurrences(of: "Output line 2:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let lines = cleanedText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        print("📝 Cleaned lines:")
        for (i, line) in lines.enumerated() {
            print("Line \(i): \(line)")
        }
        
        guard lines.count >= 1 else {
            throw NSError(domain: "Invalid response format", code: -1)
        }
        
        let translation = lines[0]
        var alignments: [String: (translation: String, colorIndex: Int)] = [:]
        
        // Parse alignments if available
        if lines.count >= 2 {
            let alignmentPairs = lines[1].components(separatedBy: ",")
            for (index, pair) in alignmentPairs.enumerated() {
                let parts = pair.components(separatedBy: ":")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                
                if parts.count == 2 {
                    let sourceWord = parts[0].lowercased()
                    let targetWord = parts[1].lowercased()
                    alignments[sourceWord] = (translation: targetWord, colorIndex: index)
                    alignments[targetWord] = (translation: sourceWord, colorIndex: index)
                    print("✅ Alignment: \(sourceWord) ↔ \(targetWord) [Color \(index)]")
                }
            }
        }
        
        print("📊 Total alignments: \(alignments.count / 2)")
        
        return (translation: translation, alignments: alignments)
    }
    
    // MARK: - Helper Functions
    private func getVoiceLanguageCode(code: String) -> String {
        switch code.uppercased() {
        case "EN": return "en-US"
        case "TR": return "tr-TR"
        case "ES": return "es-ES"
        case "FR": return "fr-FR"
        case "DE": return "de-DE"
        case "IT": return "it-IT"
        case "PT": return "pt-PT"
        case "RU": return "ru-RU"
        case "JA": return "ja-JP"
        case "KO": return "ko-KR"
        case "ZH": return "zh-CN"
        case "AR": return "ar-SA"
        default: return "en-US"
        }
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

// MARK: - AVSpeechSynthesizerDelegate
extension SentencePlayerViewModel: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
