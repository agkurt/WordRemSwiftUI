//
//  ContentStore.swift
//  WordRemSwiftUI
//
//  Kurs içeriği (diller, kurslar, seviyeler, kelimeler, cümleler) uygulamaya gömülü
//  `content.json` dosyasından okunur — internet ya da sunucu gerekmez.
//  Dosya `tools/build_content.py` ile `tools/content/*.json` kaynaklarından üretilir.
//

import Foundation

final class ContentStore {

    static let shared = ContentStore()

    private struct Bundle: Decodable {
        let languages: [SBLanguage]
        let courses: [SBCourse]
        let levels: [SBLevel]
        let words: [SBWord]
        let wordLevelAssignments: [Assignment]
        let sentences: [SBSentence]

        enum CodingKeys: String, CodingKey {
            case languages, courses, levels, words, sentences
            case wordLevelAssignments = "word_level_assignments"
        }
    }

    struct Assignment: Decodable {
        let levelId: UUID
        let wordId: UUID
        let displayOrder: Int
        enum CodingKeys: String, CodingKey {
            case levelId = "level_id", wordId = "word_id", displayOrder = "display_order"
        }
    }

    let languages: [SBLanguage]
    let courses: [SBCourse]
    private let levelsByCourse: [UUID: [SBLevel]]
    private let levelsById: [UUID: SBLevel]
    private let wordsById: [UUID: SBWord]
    private let wordIdsByLevel: [UUID: [UUID]]
    private let sentencesByCourse: [UUID: [SBSentence]]

    private init() {
        let decoded: Bundle
        do {
            guard let url = Foundation.Bundle.main.url(forResource: "content", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            decoded = try JSONDecoder().decode(Bundle.self, from: Data(contentsOf: url))
        } catch {
            // Gömülü içerik okunamazsa uygulama boş içerikle açılır (asla çökmez)
            assertionFailure("content.json okunamadı: \(error)")
            decoded = Bundle(languages: [], courses: [], levels: [], words: [], wordLevelAssignments: [], sentences: [])
        }

        languages = decoded.languages
        courses = decoded.courses
        levelsByCourse = Dictionary(grouping: decoded.levels, by: \.courseId)
            .mapValues { $0.sorted { $0.orderIndex < $1.orderIndex } }
        levelsById = Dictionary(uniqueKeysWithValues: decoded.levels.map { ($0.id, $0) })
        wordsById = Dictionary(uniqueKeysWithValues: decoded.words.map { ($0.id, $0) })
        wordIdsByLevel = Dictionary(grouping: decoded.wordLevelAssignments, by: \.levelId)
            .mapValues { $0.sorted { $0.displayOrder < $1.displayOrder }.map(\.wordId) }
        sentencesByCourse = Dictionary(grouping: decoded.sentences, by: \.courseId)
    }

    // MARK: - Queries
    func language(code: String) -> SBLanguage? {
        languages.first { $0.code.caseInsensitiveCompare(code) == .orderedSame }
    }

    func levels(courseId: UUID) -> [SBLevel] { levelsByCourse[courseId] ?? [] }

    func level(id: UUID) -> SBLevel? { levelsById[id] }

    func words(levelId: UUID) -> [SBWord] {
        (wordIdsByLevel[levelId] ?? []).compactMap { wordsById[$0] }
    }

    func words(ids: [UUID]) -> [SBWord] { ids.compactMap { wordsById[$0] } }

    func sentences(courseId: UUID) -> [SBSentence] { sentencesByCourse[courseId] ?? [] }
}
