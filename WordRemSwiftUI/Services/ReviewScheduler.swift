//
//  ReviewScheduler.swift
//  WordRemSwiftUI
//
//  Aralıklı tekrar (SRS) motoru — SM-2 tabanlı, yerel çalışır (sunucu gerekmez).
//  Kartlar LearnedWordsStore'daki kelimelerdir; her kelimenin tekrar durumu
//  App Group'ta ayrı bir sözlükte tutulur.
//

import Foundation

enum ReviewGrade: Int, CaseIterable {
    case again = 0, hard, good, easy
}

struct ReviewState: Codable, Equatable {
    var interval: Double = 0      // gün
    var ease: Double = 2.5
    var reps: Int = 0             // art arda başarılı tekrar
    var lapses: Int = 0
    var due: Date
    var lastReviewed: Date?

    /// 21 günden uzun aralık = kalıcı öğrenilmiş sayılır
    var isMature: Bool { interval >= 21 }
}

@MainActor
final class ReviewScheduler: ObservableObject {

    static let shared = ReviewScheduler()

    @Published private(set) var states: [String: ReviewState] = [:]
    @Published private(set) var words: [LearnedWord] = []
    /// Tekrar yapılan günler ("yyyy-MM-dd") — seri hesabı için
    @Published private(set) var activeDays: Set<String> = []

    private let statesKey = "reviewStates"
    private let daysKey   = "reviewActiveDays"
    private var defaults: UserDefaults? { UserDefaults(suiteName: LearnedWordsStore.appGroupID) }
    private let calendar = Calendar.current

    private init() { reload() }

    // MARK: - Load / Save
    func reload() {
        words = LearnedWordsStore.load()
        if let data = defaults?.data(forKey: statesKey),
           let decoded = try? JSONDecoder().decode([String: ReviewState].self, from: data) {
            states = decoded
        }
        activeDays = Set(defaults?.stringArray(forKey: daysKey) ?? [])
        // Yeni öğrenilen kelimelere ilk tekrarı yarına planla
        var changed = false
        for word in words where states[word.id] == nil {
            states[word.id] = ReviewState(due: startOfTomorrow(from: word.learnedAt))
            changed = true
        }
        if changed { save() }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(states) { defaults?.set(data, forKey: statesKey) }
        defaults?.set(Array(activeDays), forKey: daysKey)
    }

    func clear() {
        states = [:]; activeDays = []; words = []
        defaults?.removeObject(forKey: statesKey)
        defaults?.removeObject(forKey: daysKey)
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
    var streak: Int {
        var day = calendar.startOfDay(for: Date())
        if !activeDays.contains(key(day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  activeDays.contains(key(yesterday)) else { return 0 }
            day = yesterday
        }
        var count = 0
        while activeDays.contains(key(day)) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    var reviewedToday: Bool { activeDays.contains(key(calendar.startOfDay(for: Date()))) }

    func state(for word: LearnedWord) -> ReviewState? { states[word.id] }

    // MARK: - Grading
    /// Cevabı işler ve yeni durumu döndürür. `again` aynı oturumda tekrar sorulmalıdır.
    @discardableResult
    func grade(_ word: LearnedWord, _ grade: ReviewGrade) -> ReviewState {
        let now = Date()
        var s = states[word.id] ?? ReviewState(due: now)
        let next = Self.schedule(s, grade)
        s = next
        s.lastReviewed = now
        s.due = grade == .again
            ? now.addingTimeInterval(10 * 60)
            : (calendar.date(byAdding: .day, value: max(1, Int(next.interval.rounded())), to: calendar.startOfDay(for: now)) ?? now)
        states[word.id] = s
        activeDays.insert(key(calendar.startOfDay(for: now)))
        save()
        return s
    }

    /// Bir sonraki aralığı hesaplar (UI'da buton altında "3 gün" gibi göstermek için de kullanılır)
    static func schedule(_ current: ReviewState, _ grade: ReviewGrade) -> ReviewState {
        var s = current
        switch grade {
        case .again:
            s.lapses += 1
            s.reps = 0
            s.interval = 0
            s.ease = max(1.3, s.ease - 0.2)
        case .hard:
            s.interval = max(1, s.interval * 1.2)
            s.ease = max(1.3, s.ease - 0.15)
        case .good:
            s.interval = s.reps == 0 ? 1 : (s.reps == 1 ? 3 : s.interval * s.ease)
            s.reps += 1
        case .easy:
            s.interval = (s.reps == 0 ? 3 : max(4, s.interval * s.ease * 1.3))
            s.reps += 1
            s.ease += 0.15
        }
        return s
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
