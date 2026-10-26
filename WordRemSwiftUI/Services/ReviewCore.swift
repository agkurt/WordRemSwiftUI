//
//  ReviewCore.swift
//  WordRemSwiftUI
//
//  Aralıklı tekrarın (SRS) ortak çekirdeği. Hem uygulama hem widget bu dosyayı derler:
//  widget'tan "Biliyorum / Tekrar" denince durum App Group'ta aynı şekilde güncellenir.
//

import Foundation
import WidgetKit

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

enum ReviewCore {
    static let statesKey = "reviewStates"
    static let daysKey = "reviewActiveDays"
    /// Etkileşimli tekrar widget'ı
    static let reviewWidgetKind = "ReviewCardWidget"
    /// Widget'ta anlamı açılmış kelime
    static let revealedKey = "widgetRevealedWordId"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: LearnedWordsStore.appGroupID) }
    private static var calendar: Calendar { Calendar.current }

    // MARK: - Kalıcı durum
    static func loadStates() -> [String: ReviewState] {
        guard let data = defaults?.data(forKey: statesKey),
              let decoded = try? JSONDecoder().decode([String: ReviewState].self, from: data) else { return [:] }
        return decoded
    }

    static func save(states: [String: ReviewState], activeDays: Set<String>) {
        if let data = try? JSONEncoder().encode(states) { defaults?.set(data, forKey: statesKey) }
        defaults?.set(Array(activeDays), forKey: daysKey)
        WidgetCenter.shared.reloadTimelines(ofKind: reviewWidgetKind)
    }

    static func save(activeDays: Set<String>) {
        defaults?.set(Array(activeDays), forKey: daysKey)
    }

    static func loadActiveDays() -> Set<String> { Set(defaults?.stringArray(forKey: daysKey) ?? []) }

    static var revealedWordId: String? {
        get { defaults?.string(forKey: revealedKey) }
        set { defaults?.set(newValue, forKey: revealedKey) }
    }

    // MARK: - Planlama (SM-2)
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

    /// Cevabı işler: yeni aralık + bir sonraki vade
    static func applying(_ grade: ReviewGrade, to current: ReviewState, now: Date = Date()) -> ReviewState {
        var s = schedule(current, grade)
        s.lastReviewed = now
        s.due = grade == .again
            ? now.addingTimeInterval(10 * 60)
            : (calendar.date(byAdding: .day, value: max(1, Int(s.interval.rounded())), to: calendar.startOfDay(for: now)) ?? now)
        return s
    }

    /// Uygulama açık değilken (widget, bildirim) tek kelimeyi değerlendir
    static func grade(wordId: String, _ grade: ReviewGrade) {
        var states = loadStates()
        var days = loadActiveDays()
        states[wordId] = applying(grade, to: states[wordId] ?? ReviewState(due: Date()))
        days.insert(dayKey(Date()))
        save(states: states, activeDays: days)
    }

    // MARK: - Sorgular
    /// `date` itibarıyla vadesi gelmiş kelimeler, en gecikmiş önce
    static func due(by date: Date, words: [LearnedWord], states: [String: ReviewState]) -> [LearnedWord] {
        words
            .filter { (states[$0.id]?.due ?? startOfTomorrow(from: $0.learnedAt)) <= date }
            .sorted { (states[$0.id]?.due ?? .distantPast) < (states[$1.id]?.due ?? .distantPast) }
    }

    /// Bugün ya da dün tekrar yapıldıysa devam eden gün serisi
    static func streak(activeDays: Set<String>, now: Date = Date()) -> Int {
        var day = calendar.startOfDay(for: now)
        if !activeDays.contains(dayKey(day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  activeDays.contains(dayKey(yesterday)) else { return 0 }
            day = yesterday
        }
        var count = 0
        while activeDays.contains(dayKey(day)) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    static func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func startOfTomorrow(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    }
}
