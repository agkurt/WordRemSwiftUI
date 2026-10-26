//
//  DemoData.swift
//  WordRemSwiftUI
//
//  Sadece Debug: App Store ekran görüntüleri için gerçekçi demo verisi.
//  `-DemoData YES` → ilerleme, seri, öğrenilmiş kelimeler ve bugün tekrarı olan kartlar.
//  `-StartTab <0…3>` → açılış sekmesi, `-DemoQuiz YES` → Pratik'te ilk açık seviyenin quiz'i.
//

import Foundation

enum DemoData {

    static var isOn: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "DemoData")
        #else
        return false
        #endif
    }

    static var startTab: AppTab? {
        #if DEBUG
        guard UserDefaults.standard.object(forKey: "StartTab") != nil else { return nil }
        return AppTab(rawValue: UserDefaults.standard.integer(forKey: "StartTab"))
        #else
        return nil
        #endif
    }

    static var autoOpenQuiz: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "DemoQuiz")
        #else
        return false
        #endif
    }

    /// Hedef dilin kursundan ilk 7 seviyeyi tamamlanmış, 8.'yi açık yapar; 60 kelimeyi öğrenilmiş sayar.
    @MainActor
    static func seedIfNeeded() {
        guard isOn,
              let code = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode"),
              let lang = ContentStore.shared.language(code: code),
              let course = ContentStore.shared.courses.first(where: { $0.targetLangId == lang.id })
        else { return }

        let levels = ContentStore.shared.levels(courseId: course.id)
        let now = Date()
        let cal = Calendar.current

        UserStore.shared.update { s in
            s.username = "Ahmet"
            s.usernameChanges = 1
            s.totalXp = 1_240
            s.streakDays = 12
            s.lastActivityAt = now
            s.totalAnswers = 412
            s.correctAnswers = 371
            s.achievements = ["first_steps", "first_streak", "100_xp", "5_levels", "50_correct", "500_xp"]
            // Konuşma planı: ilk bölümün ilk iki hedefi bitmiş, üçüncüsü sırada
            var done = s.voiceGoalsDone ?? [:]
            for g in (ScenarioStore.shared.chapters.first?.goals.prefix(2) ?? []) { done[LearningLanguages.goalKey(g.id)] = now }
            s.voiceGoalsDone = done
            for (i, level) in levels.enumerated() where i < 8 {
                s.progress[level.id.uuidString] = i < 7
                    ? LevelProgressRecord(status: .completed, bestScore: [100, 95, 90, 100, 85, 95, 80][i],
                                          attempts: 1, xpEarned: level.xpReward, stars: [3, 3, 2, 3, 2, 3, 2][i],
                                          completedAt: now, lastPlayedAt: now)
                    : LevelProgressRecord(status: .unlocked)
            }
        }

        let native = OL.nativeLangCode
        let words = levels.prefix(6).flatMap { ContentStore.shared.words(levelId: $0.id) }
        let learned = words.enumerated().map { i, w in
            LearnedWord(id: w.id.uuidString, term: w.term,
                        meaning: w.displayTranslation(phoneCode: native), phonetic: w.pronunciation,
                        languageCode: code.uppercased(),
                        learnedAt: cal.date(byAdding: .hour, value: -(i * 5 + 2), to: now) ?? now)
        }
        LearnedWordsStore.add(learned.reversed(), nativeLangCode: native)

        // 14 kart bugün tekrar bekliyor, kalanlar ileride; son 12 gün aktif
        let defaults = UserDefaults(suiteName: LearnedWordsStore.appGroupID)
        var states: [String: ReviewState] = [:]
        for (i, w) in learned.enumerated() {
            let due = i < 14 ? cal.date(byAdding: .hour, value: -1, to: now)!
                             : cal.date(byAdding: .day, value: 1 + i % 9, to: now)!
            states[w.id] = ReviewState(interval: Double(1 + i % 25), ease: 2.5, reps: 1 + i % 4,
                                       lapses: 0, due: due, lastReviewed: cal.date(byAdding: .day, value: -1, to: now))
        }
        defaults?.set(try? JSONEncoder().encode(states), forKey: "reviewStates")
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.dateFormat = "yyyy-MM-dd"
        let days = (1...12).compactMap { cal.date(byAdding: .day, value: -$0, to: now) }.map(fmt.string)
        defaults?.set(days, forKey: "reviewActiveDays")
        ReviewScheduler.shared.reload()
    }

    /// Ders sonu ekranı önizlemesi (ekran görüntüsü): mağaza diline uygun başlık ve ifadeler
    static var lessonCompletePreview: (title: String, phrases: [(String, String)]) {
        let title = ScenarioStore.shared.chapters.first?.goals.first?.localizedTitle ?? ""
        let target = (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased()
        if target == "es" {
            return (title, [("¡Mucho gusto!", "Nice to meet you!"), ("Me llamo Ahmet.", "My name is Ahmet."),
                            ("Soy de Estambul.", "I'm from Istanbul.")])
        }
        return (title, [("Nice to meet you.", "Tanıştığıma memnun oldum."), ("Hello, my name is Ahmet.", "Merhaba, benim adım Ahmet."),
                        ("I'm good, thank you.", "İyiyim, teşekkür ederim.")])
    }
}
