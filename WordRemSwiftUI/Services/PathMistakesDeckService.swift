//
//  PathMistakesDeckService.swift
//  WordRemSwiftUI
//
//  Path quizinde yanlış yapılan kelimeleri otomatik olarak
//  Decks (Firebase) bölümüne yeni bir deck olarak ekler.
//  Her kelime için telefon diline çeviri + hedef dilde örnek cümle üretilir.
//

import Foundation

final class PathMistakesDeckService {

    static let shared = PathMistakesDeckService()
    private init() {}

    // MARK: - Ana giriş noktası

    /// Path quiz bitince yanlış yapılan kelimeler için otomatik deck oluşturur.
    /// - Parameters:
    ///   - mistakeWordIds: Yanlış cevaplanan SBWord UUID string'leri
    ///   - levelTitle:     Level adı (örn. "Selamlaşma")
    ///   - targetLangCode: Öğrenilen dil kodu (örn. "FR")
    func createDeckFromMistakes(
        mistakeWordIds: Set<String>,
        levelTitle: String,
        targetLangCode: String
    ) async {
        guard !mistakeWordIds.isEmpty else { return }

        let wordIds = mistakeWordIds.compactMap { UUID(uuidString: $0) }
        guard !wordIds.isEmpty else { return }

        do {
            // 1. Supabase'den kelimeleri getir
            let words = try await SupabaseDataService.shared.fetchWords(byIds: wordIds)
            guard !words.isEmpty else { return }

            // 2. Firestore'da yeni deck oluştur
            let flag      = flagModel(for: targetLangCode)
            let phoneCode = OL.phoneCode.uppercased()
            let name      = deckTitle(levelTitle: levelTitle, targetLangCode: targetLangCode)

            guard let deckId = await FirebaseService.shared.addCardNameInfo(
                name: name, selectedFlag: flag, sourceLang: phoneCode, targetLang: targetLangCode.uppercased()
            ) else { return }

            // 3. Her kelimeyi ekle (convention: wordName = native, wordMean = target language word)
            for word in words {
                let nativeTranslation = word.displayTranslation(phoneCode: OL.phoneCode)
                let sentence = (try? await generateSentence(term: word.term, langCode: targetLangCode)) ?? ""
                await FirebaseService.shared.addWordToCard(
                    cardId: deckId,
                    wordName: nativeTranslation,   // ön yüz: kullanıcının dilindeki çeviri (native)
                    wordMean: word.term,            // arka yüz: öğrenilen dildeki kelime (target)
                    wordDescription: sentence
                )
            }

            // 4. HomeScreen'i yenile
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .pathMistakesDeckCreated,
                    object: nil,
                    userInfo: ["deckName": name]
                )
            }

            print("✅ PathMistakesDeck created: \(name) (\(words.count) words)")

        } catch {
            print("⚠️ PathMistakesDeckService error: \(error)")
        }
    }

    // MARK: - Deck adı

    private func deckTitle(levelTitle: String, targetLangCode: String) -> String {
        let emoji = langEmoji(for: targetLangCode)
        return "\(emoji) Path — \(levelTitle)"
    }

    // MARK: - Örnek cümle üretimi (OpenAI)

    private func generateSentence(term: String, langCode: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",          forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(APIKey.geminiApi)", forHTTPHeaderField: "Authorization")

        let langName = languageName(for: langCode)
        let prompt = """
        Generate ONE short example sentence (10-15 words max) using "\(term)" in \(langName).
        - Must be in \(langName) only
        - No quotes, no numbering, no translation
        - Return ONLY the sentence
        """
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 50
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content   = (json?["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any]
        return (content?["content"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines).first ?? ""
    }

    // MARK: - Yardımcılar

    private func flagModel(for code: String) -> FlagModel {
        switch code.uppercased() {
        case "FR": return .french
        case "DE": return .german
        case "IT": return .italian
        case "RU": return .russian
        case "ZH": return .chinese
        case "TR": return .turkey
        default:   return .english
        }
    }

    private func langEmoji(for code: String) -> String {
        switch code.uppercased() {
        case "FR": return "🇫🇷"
        case "DE": return "🇩🇪"
        case "ES": return "🇪🇸"
        case "IT": return "🇮🇹"
        case "RU": return "🇷🇺"
        case "ZH": return "🇨🇳"
        case "EN": return "🇬🇧"
        case "TR": return "🇹🇷"
        default:   return "📚"
        }
    }

    private func languageName(for code: String) -> String {
        switch code.uppercased() {
        case "FR": return "French"
        case "DE": return "German"
        case "ES": return "Spanish"
        case "IT": return "Italian"
        case "RU": return "Russian"
        case "ZH": return "Chinese"
        case "EN": return "English"
        case "TR": return "Turkish"
        default:   return code
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let pathMistakesDeckCreated = Notification.Name("pathMistakesDeckCreated")
}
