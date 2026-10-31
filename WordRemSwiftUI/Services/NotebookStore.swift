//
//  NotebookStore.swift
//  WordRemSwiftUI
//
//  Defter: her sesli sohbet bir sayfa. Sayfalar cihazda saklanır (Documents/notebook.json),
//  Defterlerim'de sayfa sayfa çevrilir; öğrenci sayfadaki kelimeleri işaretler, işaretlenen kelime
//  anlamıyla birlikte tekrar listesine (LearnedWordsStore) düşer.
//

import Foundation

struct NotebookPage: Codable, Identifiable, Equatable {
    struct Line: Codable, Equatable {
        enum Role: String, Codable { case ai, user, card }
        var role: Role
        var text: String
        /// Kartın çevirisi
        var detail: String?
    }

    let id: UUID
    var date: Date
    /// Öğrenilen dil (küçük harf, "es")
    var language: String
    /// "Yeni insanlarla tanışma · s. 3"
    var kicker: String
    var title: String
    var lines: [Line]
    /// İşaretlenen kelimeler (küçük harf)
    var marks: [String] = []
    /// Ders hedefi tamamlandı (sayfaya mühür)
    var done = false

    /// Onboarding tanışma sohbeti her dilde tek sayfa: tekrar yapılırsa üstüne yazılır
    static func demoId(for language: String) -> UUID {
        var bytes = [UInt8](repeating: 0xD0, count: 16)
        for (i, b) in language.lowercased().utf8.prefix(8).enumerated() { bytes[8 + i] = b }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

/// Kelime dizininin bir maddesi: işaretlenen kelime ve karşılığı
struct NotebookGloss: Codable, Equatable {
    /// Dizindeki başlık: her zaman öğrenilen dilde ("book")
    var headword: String
    /// Ana dildeki karşılığı ("kitap")
    var meaning: String
    /// Öğrenci kelimeyi ana dilinde işaretlemişti (Lupa'nın Türkçe cümlesinden)
    var fromNative: Bool
}

@MainActor
final class NotebookStore: ObservableObject {
    static let shared = NotebookStore()

    @Published private(set) var pages: [NotebookPage] = []
    /// "dil|anahtar" → karşılık (işaretli kelimelerin anlamları)
    @Published private(set) var glossary: [String: NotebookGloss] = [:]

    private let maxPages = 400
    private var url: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("notebook.json")
    }
    private var glossaryURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("notebook_glossary.json")
    }

    private init() {
        if let glossaryURL, let data = try? Data(contentsOf: glossaryURL),
           let saved = try? JSONDecoder().decode([String: NotebookGloss].self, from: data) {
            glossary = saved
        }
        guard let url, let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([NotebookPage].self, from: data) else { return }
        // Eski sürümde "İngilizce" → "i̇ngilizce" (noktalı i) diye saklanan işaretler düzelir
        pages = saved.map { p in
            var p = p
            var seen = Set<String>()
            p.marks = p.marks.map { Self.key($0) }.filter { !$0.isEmpty && seen.insert($0).inserted }
            return p
        }
    }

    func gloss(_ word: String, language: String) -> NotebookGloss? {
        glossary[language.lowercased() + "|" + Self.key(word)]
    }

    func setGloss(_ gloss: NotebookGloss, for word: String, language: String) {
        glossary[language.lowercased() + "|" + Self.key(word)] = gloss
        guard let glossaryURL else { return }
        let snapshot = glossary
        Task.detached(priority: .utility) {
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: glossaryURL, options: .atomic) }
        }
    }

    /// Bir dilin sayfaları, eskiden yeniye
    func pages(for language: String) -> [NotebookPage] {
        pages.filter { $0.language == language.lowercased() }.sorted { $0.date < $1.date }
    }

    func page(_ id: UUID) -> NotebookPage? { pages.first { $0.id == id } }

    /// Sohbet sayfasını yazar (aynı kimlikle yeniden yazılırsa günceller)
    func save(_ page: NotebookPage) {
        var page = page
        page.lines = page.lines.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard page.lines.contains(where: { $0.role == .user }) else { return }
        if let i = pages.firstIndex(where: { $0.id == page.id }) {
            page.marks = pages[i].marks
            pages[i] = page
        } else {
            pages.append(page)
        }
        if pages.count > maxPages { pages.removeFirst(pages.count - maxPages) }
        persist()
    }

    func isMarked(_ word: String, in pageId: UUID) -> Bool {
        page(pageId)?.marks.contains(Self.key(word)) ?? false
    }

    /// Kelimeyi işaretler / işareti kaldırır; yeni durumu döner
    @discardableResult
    func toggleMark(_ word: String, in pageId: UUID) -> Bool {
        guard let i = pages.firstIndex(where: { $0.id == pageId }) else { return false }
        let k = Self.key(word)
        if let j = pages[i].marks.firstIndex(of: k) {
            pages[i].marks.remove(at: j)
            persist()
            return false
        }
        pages[i].marks.append(k)
        persist()
        return true
    }

    /// Bir dildeki tüm işaretli kelimeler (kelime dizini)
    func marks(for language: String) -> [String] {
        var seen = Set<String>()
        return pages(for: language).flatMap(\.marks).filter { seen.insert($0).inserted }
    }

    /// Defteri ve kelime dizinini tamamen siler (Profil → İlerlemeyi sıfırla)
    func deleteAll() {
        pages = []
        glossary = [:]
        persist()
        if let glossaryURL { try? FileManager.default.removeItem(at: glossaryURL) }
    }

    /// Debug "yeni kullanıcı" modu: gerçek defter kenara alınır, test bitince geri konur
    nonisolated static func stash(_ hide: Bool) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        for name in ["notebook", "notebook_glossary"] {
            let live = dir.appendingPathComponent(name + ".json")
            let kept = dir.appendingPathComponent(name + ".real.json")
            if hide {
                if !FileManager.default.fileExists(atPath: kept.path) {
                    try? FileManager.default.moveItem(at: live, to: kept)
                } else {
                    try? FileManager.default.removeItem(at: live)
                }
            } else {
                try? FileManager.default.removeItem(at: live)
                try? FileManager.default.moveItem(at: kept, to: live)
            }
        }
    }

    /// Noktalama ve büyük harf temizlenmiş anahtar ("¡Hola," → "hola", "İngilizce" → "ingilizce")
    nonisolated static func key(_ word: String) -> String {
        word.trimmingCharacters(in: .punctuationCharacters.union(.symbols).union(.whitespaces))
            .lowercased()
            .replacingOccurrences(of: "\u{0307}", with: "")
    }

    private func persist() {
        guard let url else { return }
        let snapshot = pages
        Task.detached(priority: .utility) {
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: url, options: .atomic) }
        }
    }
}
