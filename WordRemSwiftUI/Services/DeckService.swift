//
//  DeckService.swift
//  WordRemSwiftUI
//
//  Kullanıcı desteleri (kendi kelime kartları). Firestore yerine cihazda JSON olarak
//  tutulur ve iCloud anahtar-değer deposu ile cihazlar arasında senkronlanır.
//  Arayüz eski FirebaseService ile aynıdır.
//

import Foundation

final class DeckService {

    static let shared = DeckService()

    private struct StoredWord: Codable {
        var id: String
        var name: String
        var mean: String
        var description: String
        var createdAt: Date
    }

    private struct StoredDeck: Codable {
        var id: String
        var name: String
        var flag: String
        var sourceLang: String
        var targetLang: String
        var createdAt: Date
        var words: [StoredWord] = []
    }

    private struct Library: Codable {
        var decks: [StoredDeck] = []
        var updatedAt = Date()
    }

    private let queue = DispatchQueue(label: "wordrem.decks")
    private var library: Library
    private let fileURL: URL
    private let cloud = NSUbiquitousKeyValueStore.default
    private let cloudKey = "decks.v1"

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("decks.json")
        let local = (try? Data(contentsOf: fileURL)).flatMap { try? JSONDecoder.iso.decode(Library.self, from: $0) }
        let remote = FreshUser.isOn ? nil : cloud.data(forKey: cloudKey).flatMap { try? JSONDecoder.iso.decode(Library.self, from: $0) }
        // Daha yeni olan kazanır (desteler tek kullanıcının elinde, çakışma nadir)
        library = [local, remote].compactMap { $0 }.max { $0.updatedAt < $1.updatedAt } ?? Library()

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: nil
        ) { [weak self] _ in self?.pullFromCloud() }
    }

    // MARK: - Decks
    @discardableResult
    func addCardNameInfo(name: String, selectedFlag: FlagModel, sourceLang: String, targetLang: String) async -> String? {
        let id = UUID().uuidString
        mutate { $0.decks.insert(StoredDeck(id: id, name: name, flag: selectedFlag.rawValue,
                                            sourceLang: sourceLang, targetLang: targetLang, createdAt: Date()), at: 0) }
        return id
    }

    func findDeckId(named name: String) async -> String? {
        read { $0.decks.first { $0.name == name }?.id }
    }

    func fetchCardName() async throws -> [Card] {
        read { lib in
            lib.decks.sorted { a, b in
                // Sesli dersten gelen desteler hep en üstte
                let pa = a.id.hasPrefix("voice."), pb = b.id.hasPrefix("voice.")
                return pa != pb ? pa : a.createdAt > b.createdAt
            }.map {
                Card(id: $0.id, name: $0.name, selectedFlag: FlagModel(rawValue: $0.flag), wordCount: $0.words.count)
            }
        }
    }

    func fetchSourceAndTargetLang(cardId: String) async throws -> [Card] {
        read { lib in
            lib.decks.filter { $0.id == cardId }.map { Card(id: $0.id, targetLang: $0.targetLang, sourceLang: $0.sourceLang) }
        }
    }

    func deleteCardAndTransactions(withId cardId: String) async throws {
        mutate { $0.decks.removeAll { $0.id == cardId } }
    }

    // MARK: - Words
    func fetchTheCardNameInfo(cardId: String) async throws -> [WordInfo] {
        read { lib in
            (lib.decks.first { $0.id == cardId }?.words ?? [])
                .sorted { $0.createdAt > $1.createdAt }
                .map { WordInfo(id: $0.id, names: $0.name, means: $0.mean, descriptions: $0.description) }
        }
    }

    func addWordToCard(cardId: String, wordName: String, wordMean: String, wordDescription: String) async {
        mutate { lib in
            guard let i = lib.decks.firstIndex(where: { $0.id == cardId }) else { return }
            lib.decks[i].words.append(StoredWord(id: UUID().uuidString, name: wordName, mean: wordMean,
                                                 description: wordDescription, createdAt: Date()))
        }
    }

    func updateWordInCard(cardId: String, wordId: String, wordName: String, wordMean: String, wordDescription: String) async {
        mutate { lib in
            guard let d = lib.decks.firstIndex(where: { $0.id == cardId }),
                  let w = lib.decks[d].words.firstIndex(where: { $0.id == wordId }) else { return }
            lib.decks[d].words[w].name = wordName
            lib.decks[d].words[w].mean = wordMean
            lib.decks[d].words[w].description = wordDescription
        }
    }

    func deleteCardInfoAndTransactions(deckId: String, cardId: String) async throws {
        mutate { lib in
            guard let d = lib.decks.firstIndex(where: { $0.id == deckId }) else { return }
            lib.decks[d].words.removeAll { $0.id == cardId }
        }
    }

    /// Deste quiz sonuçları artık saklanmıyor (yalnızca istatistik amaçlıydı)
    func saveQuizResult(cardId: String, mode: String, score: Int, total: Int) async throws {}

    /// Ana dil UserDefaults/LanguageManager'da tutuluyor; burada yapılacak bir şey yok
    func addMotherTongueLanguage(motherTongue: String) async throws {}

    func deleteAll() { mutate { $0.decks = [] } }

    // MARK: - Sesli dersten desteye (kaydedilenler / telaffuz)
    enum VoiceDeck: String {
        case saved = "voice.saved"                 // kartta yer imine dokunulan ifadeler
        case pronunciation = "voice.pronunciation" // yanlış söylenen cümleler (otomatik)
    }

    /// Sesli derste kartı desteye ekler (deste yoksa sabit kimlikle oluşturur, aynı ifade iki kez eklenmez).
    /// Kelime kartı düzeni: ön yüz ana dil (çeviri), arka yüz öğrenilen dil — diğer destelerle aynı.
    @discardableResult
    func save(phrase: String, translation: String, to deck: VoiceDeck, name: String,
              flag: FlagModel, nativeCode: String, targetCode: String) -> Bool {
        var added = false
        mutate { lib in
            if !lib.decks.contains(where: { $0.id == deck.rawValue }) {
                lib.decks.insert(StoredDeck(id: deck.rawValue, name: name, flag: flag.rawValue, sourceLang: nativeCode,
                                            targetLang: targetCode, createdAt: Date()), at: 0)
            }
            guard let i = lib.decks.firstIndex(where: { $0.id == deck.rawValue }),
                  !lib.decks[i].words.contains(where: { Self.matches($0, phrase) }) else { return }
            // Kartın ön yüzü (name) öğrenilen dildeki cümle, arka yüzü (mean) çevirisi
            lib.decks[i].words.append(StoredWord(id: UUID().uuidString, name: phrase,
                                                 mean: translation, description: "", createdAt: Date()))
            added = true
        }
        return added
    }

    func contains(phrase: String, in deck: VoiceDeck) -> Bool {
        read { $0.decks.first { $0.id == deck.rawValue }?.words.contains { Self.matches($0, phrase) } ?? false }
    }

    func remove(phrase: String, from deck: VoiceDeck) {
        mutate { lib in
            guard let i = lib.decks.firstIndex(where: { $0.id == deck.rawValue }) else { return }
            lib.decks[i].words.removeAll { Self.matches($0, phrase) }
        }
    }

    /// Eski kayıtlarda cümle "mean" alanındaydı: iki alana da bakılır
    private static func matches(_ w: StoredWord, _ phrase: String) -> Bool {
        w.name.caseInsensitiveCompare(phrase) == .orderedSame || w.mean.caseInsensitiveCompare(phrase) == .orderedSame
    }

    // MARK: - Storage
    private func read<T>(_ body: (Library) -> T) -> T { queue.sync { body(library) } }

    private func mutate(_ change: (inout Library) -> Void) {
        let data: Data? = queue.sync {
            change(&library)
            library.updatedAt = Date()
            return try? JSONEncoder.iso.encode(library)
        }
        guard let data else { return }
        try? data.write(to: fileURL, options: .atomic)
        if !FreshUser.isOn { cloud.set(data, forKey: cloudKey) }
    }

    private func pullFromCloud() {
        guard !FreshUser.isOn, let data = cloud.data(forKey: cloudKey),
              let remote = try? JSONDecoder.iso.decode(Library.self, from: data) else { return }
        queue.sync { if remote.updatedAt > library.updatedAt { library = remote } }
        try? data.write(to: fileURL, options: .atomic)
    }
}
