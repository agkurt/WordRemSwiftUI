//
//  SmartReminders.swift
//  WordRemSwiftUI
//
//  WordRem'in "Rem"i: akıllı yerel hatırlatmalar (sunucu yok, maliyet yok).
//   • Tekrar: unutulmak üzere olan gerçek kelimeyle soru; bildirimden "Hatırladım / Hatırlamadım" → SRS güncellenir.
//   • Öğretmen: yarım kalan sesli ders ertesi gün "kaldığınız yerden devam".
//   • Seri: o gün çalışılmadıysa tek bir uyarı; çalışıldıysa hiç bildirim yok.
//  Kurallar: kullanıcının alışkın olduğu saatte, günde en fazla bir bildirim;
//  üst üste 3 bildirim açılmazsa gün aşırı (bildirim yorgunluğu olmasın).
//

import Foundation
import UserNotifications
import os

private let remLog = Logger(subsystem: "com.twinflare.WordRemSwiftUI", category: "reminders")

@MainActor
enum SmartReminders {

    static let reviewCategory = "REVIEW_WORD"
    static let rememberedAction = "REMEMBERED"
    static let forgotAction = "FORGOT"

    private static let prefix = "smart."
    private static let defaults = UserDefaults.standard
    private static let habitKey = "rem.habitMinutes"
    private static let scheduledKey = "rem.scheduled"   // [kimlik: tetiklenme zamanı]
    private static let openedKey = "rem.opened"

    // MARK: - Kurulum
    static func registerCategories() {
        let remembered = UNNotificationAction(identifier: rememberedAction, title: AL.s(.remRemembered), options: [])
        let forgot = UNNotificationAction(identifier: forgotAction, title: AL.s(.remForgot), options: [])
        let review = UNNotificationCategory(identifier: reviewCategory, actions: [remembered, forgot],
                                            intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([review])
    }

    // MARK: - Alışkanlık saati
    /// Uygulama her açıldığında saati not et (son 20 açılış)
    static func noteAppOpened(_ date: Date = Date()) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        guard (6 * 60...23 * 60).contains(minutes) else { return }
        var samples = defaults.array(forKey: habitKey) as? [Int] ?? []
        samples.append(minutes)
        defaults.set(Array(samples.suffix(20)), forKey: habitKey)
    }

    /// Kullanıcının genelde uygulamayı açtığı saat (medyan); veri yoksa 19:30
    static var habitMinutes: Int {
        let samples = (defaults.array(forKey: habitKey) as? [Int] ?? []).sorted()
        guard samples.count >= 3 else { return 19 * 60 + 30 }
        return min(max(samples[samples.count / 2], 9 * 60), 21 * 60 + 30)
    }

    // MARK: - Açılma takibi
    static func noteOpened(_ identifier: String) {
        var opened = Set(defaults.stringArray(forKey: openedKey) ?? [])
        opened.insert(identifier)
        defaults.set(Array(opened.suffix(30)), forKey: openedKey)
    }

    /// Tetiklenmiş son bildirimlerden üst üste kaç tanesi açılmadı
    private static var ignoredInARow: Int {
        let scheduled = defaults.dictionary(forKey: scheduledKey) as? [String: Date] ?? [:]
        let opened = Set(defaults.stringArray(forKey: openedKey) ?? [])
        let fired = scheduled.filter { $0.value < Date() }.sorted { $0.value > $1.value }
        var count = 0
        for (id, _) in fired { if opened.contains(id) { break }; count += 1 }
        return count
    }

    // MARK: - Planlama
    /// Uygulama arka plana geçerken / çalışma sonrası çağrılır: önümüzdeki 4 güne en fazla birer bildirim kurar.
    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            remLog.info("notifications not authorized")
            return
        }

        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        // Geçmişte tetiklenenleri (açılma takibi için) sakla, iptal edilenleri unut
        var scheduled = (defaults.dictionary(forKey: scheduledKey) as? [String: Date] ?? [:]).filter { $0.value < Date() }
        let ignored = ignoredInARow
        let words = LearnedWordsStore.load()
        let states = ReviewCore.loadStates()
        let days = ReviewCore.loadActiveDays()
        let now = Date()
        let calendar = Calendar.current
        let gap = ignored >= 3 ? 2 : 1   // açılmıyorsa gün aşırı

        for dayOffset in stride(from: 0, to: 4, by: gap) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else { continue }
            let studiedThatDay = days.contains(ReviewCore.dayKey(day))
            var fire = day.addingTimeInterval(TimeInterval(habitMinutes * 60))
            if dayOffset == 0 {
                guard !studiedThatDay else { continue }          // bugün çalıştıysa rahatsız etme
                if fire < now.addingTimeInterval(20 * 60) {       // alışkın saat geçtiyse akşam son bir şans
                    let late = day.addingTimeInterval(21 * 3600)
                    guard late > now.addingTimeInterval(20 * 60) else { continue }
                    fire = late
                }
            }
            guard let content = content(for: dayOffset, fire: fire, words: words, states: states, days: days) else { continue }
            let id = prefix + ReviewCore.dayKey(day)
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let request = UNNotificationRequest(identifier: id, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(request)
            scheduled[id] = fire
            remLog.info("scheduled \(id, privacy: .public) at \(fire.formatted(), privacy: .public): \(content.title, privacy: .public) — \(content.body, privacy: .public)")
        }
        defaults.set(scheduled, forKey: scheduledKey)
    }

    /// Günün tek bildirimi; öncelik: seri tehlikede (bugün) → yarım ders (yarın) → tekrar sorusu → nazik davet
    private static func content(for dayOffset: Int, fire: Date, words: [LearnedWord],
                                states: [String: ReviewState], days: Set<String>) -> UNMutableNotificationContent? {
        let c = UNMutableNotificationContent()
        c.sound = .default
        let streak = ReviewCore.streak(activeDays: days)

        if dayOffset == 0, streak >= 2 {
            c.title = AL.f(.remStreakTitle, streak)
            c.body = AL.s(.remStreakBody)
            c.userInfo = ["kind": "streak"]
            return c
        }

        if dayOffset == 1, let resume = pendingLesson {
            c.title = AL.s(.remTutorTitle)
            c.body = AL.s(.remTutorBody).replacingOccurrences(of: "{goal}", with: resume.title)
            c.userInfo = ["kind": "tutor", "chapterId": resume.chapterId, "goalId": resume.goalId]
            return c
        }

        let due = ReviewCore.due(by: fire, words: words, states: states)
        if !due.isEmpty {
            let word = due[dayOffset % due.count]   // her gün farklı bir kelime
            c.title = AL.s(.remReviewTitle)
                .replacingOccurrences(of: "{word}", with: word.meaning)
                .replacingOccurrences(of: "{lang}", with: targetLanguageName)
            c.body = AL.s(.remReviewBody) + (due.count > 1 ? " " + AL.f(.remReviewMore, due.count - 1) : "")
            c.categoryIdentifier = reviewCategory
            c.userInfo = ["kind": "review", "wordId": word.id]
            return c
        }

        // Kelime yoksa: seri varsa koru, yoksa iki günde bir nazik davet
        guard streak >= 2 || dayOffset % 2 == 1 else { return nil }
        c.title = streak >= 2 ? AL.f(.remStreakTitle, streak) : AL.s(.remDailyTitle)
        c.body = streak >= 2 ? AL.s(.remStreakBody) : AL.s(.remDailyBody)
        c.userInfo = ["kind": "streak"]
        return c
    }

    /// Son 3 gün içinde yarım bırakılmış ders hedefi
    private static var pendingLesson: (chapterId: String, goalId: String, title: String)? {
        guard let progress = UserStore.shared.snapshot.voiceProgress else { return nil }
        let recent = progress.filter { $0.key.hasPrefix("goal:") && Date().timeIntervalSince($0.value.updatedAt) < 3 * 86_400 }
        guard let latest = recent.max(by: { $0.value.updatedAt < $1.value.updatedAt }) else { return nil }
        let goalId = String(latest.key.dropFirst("goal:".count))
        for chapter in ScenarioStore.shared.chapters {
            if let goal = chapter.goals.first(where: { $0.id == goalId }), !ScenarioStore.shared.isDone(goal) {
                return (chapter.id, goal.id, goal.localizedTitle)
            }
        }
        return nil
    }

    private static var targetLanguageName: String {
        UserDefaults.standard.string(forKey: "selectedTargetLanguageName")
            ?? LanguageManager.shared.languageName(for: UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en")
    }

    // MARK: - Bildirimden gelen cevaplar
    static func handle(_ response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        noteOpened(response.notification.request.identifier)

        switch response.actionIdentifier {
        case rememberedAction:
            if let id = info["wordId"] as? String { ReviewCore.grade(wordId: id, .good) }
            ReviewScheduler.shared.reload()
        case forgotAction:
            if let id = info["wordId"] as? String {
                ReviewCore.grade(wordId: id, .again)
                await showAnswer(wordId: id)
            }
            ReviewScheduler.shared.reload()
        case UNNotificationDefaultActionIdentifier:
            switch info["kind"] as? String {
            case "tutor":
                if let c = info["chapterId"] as? String, let g = info["goalId"] as? String {
                    AppRouter.shared.route = .tutor(chapterId: c, goalId: g)
                }
            case "review":
                AppRouter.shared.route = .review
            default:
                AppRouter.shared.route = .talk
            }
        default:
            break
        }
        await reschedule()
    }

    /// "Hatırlamadım" deyince cevabı hemen göster
    private static func showAnswer(wordId: String) async {
        guard let word = LearnedWordsStore.load().first(where: { $0.id == wordId }) else { return }
        let c = UNMutableNotificationContent()
        c.title = "\(word.meaning) = \(word.term)"
        c.body = AL.s(.remAnswerBody)
        c.userInfo = ["kind": "review"]
        let request = UNNotificationRequest(identifier: "answer.\(wordId)", content: c,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        try? await UNUserNotificationCenter.current().add(request)
    }
}

/// Bildirim/widget'tan uygulama içine yönlendirme
@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    enum Route: Equatable {
        case talk, review
        case tutor(chapterId: String, goalId: String)
    }
    @Published var route: Route?
}
