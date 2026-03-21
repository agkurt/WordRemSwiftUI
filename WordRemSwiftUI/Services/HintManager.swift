//
//  HintManager.swift
//  WordRemSwiftUI
//
//  Günlük 5 ipucu hakkı (24 saat sıfırlanır).
//  Her kelime için OpenAI üzerinden anlamı doğrudan söylemeden
//  kullanıcının dilinde bir ipucu cümlesi üretir.
//

import Foundation

final class HintManager {

    static let shared = HintManager()
    private init() {}

    static let dailyHintLimit = 5

    // MARK: - UserDefaults keys
    private let usedKey   = "hint_used"
    private let resetKey  = "hint_resetDate"

    // MARK: - Remaining hints
    var hintsUsedToday: Int {
        refreshIfNeeded()
        return UserDefaults.standard.integer(forKey: usedKey)
    }

    var hintsRemaining: Int {
        if DailyLimitManager.shared.isPremium { return Int.max }
        return max(0, HintManager.dailyHintLimit - hintsUsedToday)
    }

    var canUseHint: Bool {
        DailyLimitManager.shared.isPremium || hintsRemaining > 0
    }

    // MARK: - Record hint usage
    func useHint() {
        guard !DailyLimitManager.shared.isPremium else { return }
        refreshIfNeeded()
        let used = UserDefaults.standard.integer(forKey: usedKey)
        if used == 0 {
            // First hint today → set reset time 24h from now
            UserDefaults.standard.set(Date().addingTimeInterval(86_400), forKey: resetKey)
        }
        UserDefaults.standard.set(used + 1, forKey: usedKey)
    }

    // MARK: - Countdown string
    var countdownString: String {
        guard let resetDate = UserDefaults.standard.object(forKey: resetKey) as? Date else {
            return "00:00:00"
        }
        let seconds = max(0, Int(resetDate.timeIntervalSinceNow))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Generate hint via OpenAI
    /// Returns an AI hint in the user's native language that hints at the word
    /// without directly translating it.
    func fetchHint(term: String, targetLangCode: String, options: [String] = [], correctAnswer: String = "") async -> String {
        let phoneCode   = OL.nativeLangCode.uppercased()
        let langName    = languageName(for: phoneCode)
        let targetName  = languageName(for: targetLangCode)

        let optionsText = options.isEmpty ? "" : "\nThe answer options are: \(options.joined(separator: ", "))"
        let correctContext = correctAnswer.isEmpty ? "" : "\nThe correct answer is one of those options (do NOT reveal which one)."

        let prompt = """
        The user is learning \(targetName). The word is "\(term)" in \(targetName).\(optionsText)\(correctContext)
        Write a helpful hint in \(langName) (2-3 sentences) that:
        - Describes the context, theme, or category of this word
        - Does NOT directly translate it or give away the correct answer option
        - Provides an example sentence using "\(term)" in \(targetName)
        Return ONLY the hint text.
        """

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(APIKey.geminiApi)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 120
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return "💡 \(term)"
        }
        req.httpBody = httpBody

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let msg = choices.first?["message"] as? [String: Any],
              let content = msg["content"] as? String else {
            return "💡 Try to think of a context where you'd use '\(term)' in \(targetName)."
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines).joined(separator: " ")
    }

    // MARK: - Helpers
    private func refreshIfNeeded() {
        guard let resetDate = UserDefaults.standard.object(forKey: resetKey) as? Date else { return }
        if Date() >= resetDate {
            UserDefaults.standard.set(0, forKey: usedKey)
            UserDefaults.standard.removeObject(forKey: resetKey)
        }
    }

    private func languageName(for code: String) -> String {
        switch code.uppercased() {
        case "TR": return "Turkish"
        case "EN": return "English"
        case "DE": return "German"
        case "FR": return "French"
        case "ES": return "Spanish"
        case "IT": return "Italian"
        case "RU": return "Russian"
        case "ZH": return "Chinese"
        case "JA": return "Japanese"
        case "KO": return "Korean"
        case "PT": return "Portuguese"
        default:   return code
        }
    }
}
