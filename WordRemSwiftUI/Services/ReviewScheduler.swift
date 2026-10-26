//
//  ReviewScheduler.swift
//  WordRemSwiftUI
//
//  Aralıklı tekrar (SRS) motoru — SM-2 tabanlı, yerel çalışır (sunucu gerekmez).
//  Kartlar LearnedWordsStore'daki kelimelerdir; her kelimenin tekrar durumu
//  App Group'ta ayrı bir sözlükte tutulur.
//

import Foundation
import WidgetKit

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
    /// Şu an öğrenilen dilin kelimeleri (Kelimeler listesi dilleri karıştırmasın)
    var currentWords: [LearnedWord] {
        let lang = (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased()
        return words.filter { $0.languageCode.lowercased() == lang }
    }

    var dueToday: [LearnedWord] {
        let end = endOfToday()
        // Yalnızca şu an öğrenilen dilin kelimeleri (dil değiştirince eski dilin tekrarları karışmasın)
        let lang = (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased()
        return words
            .filter { $0.languageCode.lowercased() == lang && (states[$0.id]?.due ?? .distantPast) <= end }
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
        StudyStreak.record()
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

/// Tek seri kaynağı: o gün yapılan herhangi bir çalışma (quiz, ders, sesli sohbet, kelime tekrarı) seriyi sürdürür.
/// Günler App Group'ta (widget ve bildirimler görsün) ve kullanıcı kaydında (bulut, cihazlar arası) birlikte tutulur.
enum StudyStreak {
    static var days: Set<String> {
        ReviewCore.loadActiveDays().union(UserStore.shared.snapshot.studyDays ?? [])
    }
    static var current: Int { ReviewCore.streak(activeDays: days) }

    /// Bugün çalışıldı
    static func record() { sync(addingToday: true) }

    /// Widget/bildirimden yapılan tekrarları ve diğer cihazı birleştirir (uygulama açılınca da çağrılır)
    static func sync(addingToday: Bool = false) {
        let today = ReviewCore.dayKey(Date())
        let local = ReviewCore.loadActiveDays()
        let snap = UserStore.shared.snapshot
        var cloud = Set(snap.studyDays ?? [])
        // Tek seferlik geçiş: eski "açılış serisi" günlerini koru ki kimsenin serisi sıfırlanmasın
        if snap.studyDays == nil, snap.streakDays > 0, let last = snap.lastActivityAt {
            for i in 0..<min(snap.streakDays, 400) {
                if let d = Calendar.current.date(byAdding: .day, value: -i, to: last) { cloud.insert(ReviewCore.dayKey(d)) }
            }
        }
        var all = local.union(cloud)
        if addingToday { all.insert(today) }
        let streak = ReviewCore.streak(activeDays: all)
        guard all != local || all != Set(snap.studyDays ?? []) || snap.streakDays != streak else { return }
        if all != local { ReviewCore.save(activeDays: all) }
        UserStore.shared.update { s in
            s.studyDays = all.sorted().suffix(400).map { $0 }
            s.streakDays = streak
            if addingToday { s.lastActivityAt = Date() }
        }
        WidgetCenter.shared.reloadAllTimelines()
        Task { @MainActor in ReviewScheduler.shared.reload() }
    }
}
