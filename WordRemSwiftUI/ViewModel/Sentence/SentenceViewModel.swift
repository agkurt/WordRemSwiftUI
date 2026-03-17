//
//  SentenceViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import Foundation
import SwiftUI

@MainActor
final class SentenceViewModel: ObservableObject {
    
    @Published var exampleWords: ExampleWord?
    @Published var word: String = ""
    @Published var errorMessage: String?
    @Published var colorScheme: ColorScheme?
    @Published var isLoading = false
    
    func fetchAllWords() {
        guard !word.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a word"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let examples = try await generateExamplesWithGemini(word: word)
                self.exampleWords = ExampleWord(word: word, examples: examples)
                self.isLoading = false
            } catch {
                print("❌ Gemini API Error: \(error)")
                print("❌ Error description: \(error.localizedDescription)")
                
                // More detailed error message
                if let nsError = error as NSError? {
                    print("❌ Error domain: \(nsError.domain)")
                    print("❌ Error code: \(nsError.code)")
                    print("❌ Error userInfo: \(nsError.userInfo)")
                    
                    if nsError.code == -1 {
                        self.errorMessage = "Failed to connect to Gemini API. Please check your API key."
                    } else if nsError.code == 403 {
                        self.errorMessage = "Invalid API key. Please check your Gemini API key in ApiKey-Info.plist"
                    } else if nsError.code == 400 {
                        self.errorMessage = "Bad request. Please try a different word."
                    } else {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                    }
                } else {
                    self.errorMessage = error.localizedDescription
                }
                
                self.exampleWords = nil
                self.isLoading = false
            }
        }
    }
    
    private func generateExamplesWithGemini(word: String) async throws -> [String] {
        let apiKey = APIKey.geminiApi // We'll rename this to openAIKey later
        
        print("🔑 Using OpenAI API key: \(apiKey.prefix(10))...")
        
        // OpenAI GPT-4o-mini endpoint (cheapest and fast)
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        Generate 5 example sentences using the word "\(word)".
        
        Requirements:
        - Each sentence should demonstrate a different usage context of the word
        - Sentences should be clear, natural, and educational
        - Vary the sentence structure and context (formal, casual, technical, everyday)
        - Make sure the word "\(word)" appears in each sentence
        - Return ONLY the sentences, one per line, without numbering or bullets
        
        Format your response as exactly 5 sentences, each on a new line.
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful English teacher that generates example sentences for vocabulary learning."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 300
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 Sending request to OpenAI API for word: \(word)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NSError(domain: "Invalid response", code: -1)
        }
        
        print("📥 Received response with status code: \(httpResponse.statusCode)")
        
        // Print response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response body: \(responseString.prefix(500))...") // First 500 chars only
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ API Error message: \(message)")
                throw NSError(domain: "API Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            
            throw NSError(domain: "API Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            print("❌ Failed to parse JSON response")
            throw NSError(domain: "Failed to parse response", code: -1)
        }
        
        print("✅ Successfully received text from OpenAI")
        print("📝 Generated text: \(text)")
        
        // Parse sentences from response
        let sentences = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !$0.starts(with: "sentence") } // Remove any "sentence 1:" type prefixes
            .map { sentence in
                // Clean up common prefixes like "1.", "•", "-", etc.
                var clean = sentence
                if let firstChar = clean.first, firstChar.isNumber || firstChar == "•" || firstChar == "-" {
                    clean = String(clean.drop(while: { $0.isNumber || $0.isPunctuation || $0.isWhitespace }))
                }
                return clean.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
        
        print("✅ Parsed \(sentences.count) sentences")
        
        // Return up to 5 sentences
        return Array(sentences.prefix(5))
    }
    
    func getColorBasedOnScheme() -> Color  {
        switch colorScheme {
        case .light:
            return Color.init(hex: "#a2a7ac")
            
        case .dark:
            return Color.init(hex: "#1c2127")
            
        default:
            return Color.init(hex:"#313a45")
        }
    }
}
