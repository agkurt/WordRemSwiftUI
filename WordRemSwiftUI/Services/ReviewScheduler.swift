//
//  ReviewScheduler.swift
//  WordRemSwiftUI
//
//  Aralıklı tekrar (SRS) motoru — SM-2 tabanlı, yerel çalışır (sunucu gerekmez).
//  Kartlar LearnedWordsStore'daki kelimelerdir; her kelimenin tekrar durumu
//  App Group'ta ayrı bir sözlükte tutulur.
//

import Foundation

@MainActor
final class ReviewScheduler: ObservableObject {

    static let shared = ReviewScheduler()

    @Published private(set) var states: [String: ReviewState] = [:]
    @Published private(set) var words: [LearnedWord] = []
    /// Tekrar yapılan günler ("yyyy-MM-dd") — seri hesabı için
    @Published private(set) var activeDays: Set<String> = []

    private var defaults: UserDefaults? { UserDefaults(suiteName: LearnedWordsStore.appGroupID) }
    private let calendar = Calendar.current

    private init() { reload() }

    // MARK: - Load / Save
    func reload() {
        words = LearnedWordsStore.load()
        // Widget/bildirimden verilen cevaplar da burada okunur
        states = ReviewCore.loadStates()
        activeDays = ReviewCore.loadActiveDays()
        // Yeni öğrenilen kelimelere ilk tekrarı yarına planla
        var changed = false
        for word in words where states[word.id] == nil {
            states[word.id] = ReviewState(due: startOfTomorrow(from: word.learnedAt))
            changed = true
        }
        if changed { save() }
    }

    private func save() {
        ReviewCore.save(states: states, activeDays: activeDays)
    }

    func clear() {
        states = [:]; activeDays = []; words = []
        defaults?.removeObject(forKey: ReviewCore.statesKey)
        defaults?.removeObject(forKey: ReviewCore.daysKey)
    }

    // MARK: - Queries
    /// Bugün sonuna kadar vadesi gelen kelimeler, en gecikmiş önce
    var dueToday: [LearnedWord] {
        let end = endOfToday()
        return words
            .filter { (states[$0.id]?.due ?? .distantPast) <= end }
            .sorted { (states[$0.id]?.due ?? .distantPast) < (states[$1.id]?.due ?? .distantPast) }
    }

    var nextDueDate: Date? {
        states.values.map(\.due).filter { $0 > endOfToday() }.min()
    }

    var knownCount: Int { words.count }
    var matureCount: Int { states.values.filter(\.isMature).count }

    var learnedThisWeek: Int {
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return words.filter { $0.learnedAt >= weekAgo }.count
    }

    /// Bugün ya da dün tekrar yapıldıysa devam eden gün serisi
    var streak: Int { ReviewCore.streak(activeDays: activeDays) }

    var reviewedToday: Bool { activeDays.contains(key(calendar.startOfDay(for: Date()))) }

    func state(for word: LearnedWord) -> ReviewState? { states[word.id] }

    // MARK: - Grading
    /// Cevabı işler ve yeni durumu döndürür. `again` aynı oturumda tekrar sorulmalıdır.
    @discardableResult
    func grade(_ word: LearnedWord, _ grade: ReviewGrade) -> ReviewState {
        let now = Date()
        let s = ReviewCore.applying(grade, to: states[word.id] ?? ReviewState(due: now), now: now)
        states[word.id] = s
        activeDays.insert(key(calendar.startOfDay(for: now)))
        save()
        return s
    }

    /// Bir sonraki aralığı hesaplar (UI'da buton altında "3 gün" gibi göstermek için de kullanılır)
    static func schedule(_ current: ReviewState, _ grade: ReviewGrade) -> ReviewState {
        ReviewCore.schedule(current, grade)
    }

    // MARK: - Helpers
    private func key(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func endOfToday() -> Date {
        calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: Date())) ?? Date()
    }

    private func startOfTomorrow(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    }
}
