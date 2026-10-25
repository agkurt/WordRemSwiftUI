//
//  LearnedWordsStore.swift
//  WordRemSwiftUI
//
//  Quiz'de doğru bilinen kelimeleri App Group'ta saklar.
//  Hem uygulama hem de "Günün Kelimesi" widget'ı bu dosyayı derler.
//

import Foundation
import WidgetKit

struct LearnedWord: Codable, Hashable, Identifiable {
    let id: String
    let term: String
    let meaning: String
    let phonetic: String?
    /// Öğrenilen dilin ISO kodu, örn. "ES"
    let languageCode: String
    let learnedAt: Date
}

enum LearnedWordsStore {

    static let appGroupID = "group.com.twinflare.WordRemSwiftUI"
    static let widgetKind = "WordOfTheDayWidget"

    private static let wordsKey      = "learnedWords"
    private static let nativeLangKey = "nativeLangCode"
    private static let maxCount      = 300

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    // MARK: - Read
    static func load() -> [LearnedWord] {
        guard let data = defaults?.data(forKey: wordsKey),
              let words = try? JSONDecoder().decode([LearnedWord].self, from: data)
        else { return [] }
        return words
    }

    /// Widget'taki boş durum metni için kullanıcının ana dili
    static var nativeLangCode: String {
        defaults?.string(forKey: nativeLangKey) ?? "en"
    }

    // MARK: - Write
    /// Yeni kelimeleri en başa ekler; aynı kelime tekrar gelirse öne taşınır.
    static func add(_ newWords: [LearnedWord], nativeLangCode: String) {
        guard !newWords.isEmpty, let defaults else { return }
        let newIds = Set(newWords.map(\.id))
        var words = newWords + load().filter { !newIds.contains($0.id) }
        if words.count > maxCount { words = Array(words.prefix(maxCount)) }
        guard let data = try? JSONEncoder().encode(words) else { return }
        defaults.set(data, forKey: wordsKey)
        defaults.set(nativeLangCode, forKey: nativeLangKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    /// Çıkış / hesap silme sonrası widget'ta eski kullanıcının kelimeleri kalmasın
    static func clear() {
        defaults?.removeObject(forKey: wordsKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
