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

// MARK: - Lupa (öğretmen) ortak verisi: uygulama + widget
/// "Lupa seni bekliyor" widget'ı, seri widget'ı ve bildirimler aynı günlük soruyu ve dil bilgisini kullanır.
enum LupaShared {
    static let name = "Lupa"
    static let widgetKind = "LupaWidget"
    static let streakWidgetKind = "StreakWidget"
    private static let targetKey = "lupaTargetLang"
    private static let nativeKey = "nativeLangCode"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: LearnedWordsStore.appGroupID) }

    static var targetLang: String { (defaults?.string(forKey: targetKey) ?? "en").lowercased() }
    static var nativeLang: String { (defaults?.string(forKey: nativeKey) ?? "en").lowercased() }

    /// Uygulama açılınca / dil değişince widget'ların dili güncellenir
    static func save(target: String, native: String) {
        let t = target.lowercased(), n = native.lowercased()
        guard t != defaults?.string(forKey: targetKey) || n != defaults?.string(forKey: nativeKey) else { return }
        defaults?.set(t, forKey: targetKey)
        defaults?.set(n, forKey: nativeKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Günün sorusu: her gün bir sonraki (herkes için aynı sıra, dil fark etmez)
    static func questionIndex(for date: Date = Date()) -> Int {
        (Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0) % questions.count
    }

    static func question(_ index: Int, lang: String) -> String {
        let q = questions[((index % questions.count) + questions.count) % questions.count]
        return q[lang.lowercased()] ?? q["en"]!
    }

    /// Widget'a dokununca: Lupa bu soruyla sohbeti açar
    static func url(question index: Int) -> URL { URL(string: "wordrem://lupa?q=\(index)")! }
    static let streakURL = URL(string: "wordrem://talk")!

    static let questions: [[String: String]] = [
        ["en": "How was your day?", "tr": "Günün nasıl geçti?", "de": "Wie war dein Tag?", "fr": "Comment s'est passée ta journée ?",
         "es": "¿Qué tal tu día?", "it": "Com'è andata la tua giornata?", "ru": "Как прошёл твой день?", "zh": "你今天过得怎么样？"],
        ["en": "What did you eat today?", "tr": "Bugün ne yedin?", "de": "Was hast du heute gegessen?", "fr": "Qu'est-ce que tu as mangé aujourd'hui ?",
         "es": "¿Qué comiste hoy?", "it": "Cosa hai mangiato oggi?", "ru": "Что ты сегодня ел?", "zh": "你今天吃了什么？"],
        ["en": "What are you doing this weekend?", "tr": "Bu hafta sonu ne yapıyorsun?", "de": "Was machst du am Wochenende?", "fr": "Qu'est-ce que tu fais ce week-end ?",
         "es": "¿Qué haces este fin de semana?", "it": "Cosa fai questo fine settimana?", "ru": "Что ты делаешь на выходных?", "zh": "这个周末你做什么？"],
        ["en": "What's your favorite place in your city?", "tr": "Şehrinde en sevdiğin yer neresi?", "de": "Was ist dein Lieblingsort in deiner Stadt?", "fr": "Quel est ton endroit préféré dans ta ville ?",
         "es": "¿Cuál es tu lugar favorito de tu ciudad?", "it": "Qual è il tuo posto preferito nella tua città?", "ru": "Какое твоё любимое место в городе?", "zh": "你在城市里最喜欢的地方是哪里？"],
        ["en": "What music are you listening to these days?", "tr": "Bu aralar hangi müzikleri dinliyorsun?", "de": "Welche Musik hörst du gerade?", "fr": "Quelle musique écoutes-tu en ce moment ?",
         "es": "¿Qué música escuchas estos días?", "it": "Che musica ascolti in questi giorni?", "ru": "Какую музыку ты сейчас слушаешь?", "zh": "你最近在听什么音乐？"],
        ["en": "Where would you love to travel?", "tr": "En çok nereye seyahat etmek istersin?", "de": "Wohin würdest du gern reisen?", "fr": "Où aimerais-tu voyager ?",
         "es": "¿A dónde te encantaría viajar?", "it": "Dove ti piacerebbe viaggiare?", "ru": "Куда бы ты хотел поехать?", "zh": "你最想去哪里旅行？"],
        ["en": "What made you smile today?", "tr": "Bugün seni ne gülümsetti?", "de": "Was hat dich heute zum Lächeln gebracht?", "fr": "Qu'est-ce qui t'a fait sourire aujourd'hui ?",
         "es": "¿Qué te hizo sonreír hoy?", "it": "Cosa ti ha fatto sorridere oggi?", "ru": "Что тебя сегодня порадовало?", "zh": "今天什么让你笑了？"],
        ["en": "What do you usually do in the morning?", "tr": "Sabahları genelde ne yaparsın?", "de": "Was machst du morgens normalerweise?", "fr": "Que fais-tu d'habitude le matin ?",
         "es": "¿Qué sueles hacer por la mañana?", "it": "Cosa fai di solito la mattina?", "ru": "Что ты обычно делаешь утром?", "zh": "你早上通常做什么？"],
        ["en": "What's your favorite food?", "tr": "En sevdiğin yemek ne?", "de": "Was ist dein Lieblingsessen?", "fr": "Quel est ton plat préféré ?",
         "es": "¿Cuál es tu comida favorita?", "it": "Qual è il tuo piatto preferito?", "ru": "Какое твоё любимое блюдо?", "zh": "你最喜欢的食物是什么？"],
        ["en": "Who do you love spending time with?", "tr": "En çok kiminle vakit geçirmeyi seversin?", "de": "Mit wem verbringst du am liebsten Zeit?", "fr": "Avec qui aimes-tu passer du temps ?",
         "es": "¿Con quién te encanta pasar tiempo?", "it": "Con chi ami passare il tempo?", "ru": "С кем ты любишь проводить время?", "zh": "你最喜欢和谁一起度过时间？"],
        ["en": "What did you do yesterday evening?", "tr": "Dün akşam ne yaptın?", "de": "Was hast du gestern Abend gemacht?", "fr": "Qu'as-tu fait hier soir ?",
         "es": "¿Qué hiciste ayer por la tarde?", "it": "Cosa hai fatto ieri sera?", "ru": "Что ты делал вчера вечером?", "zh": "你昨天晚上做了什么？"],
        ["en": "What's a hobby you really enjoy?", "tr": "Gerçekten keyif aldığın bir hobin ne?", "de": "Welches Hobby macht dir richtig Spaß?", "fr": "Quel loisir aimes-tu vraiment ?",
         "es": "¿Qué pasatiempo disfrutas de verdad?", "it": "Qual è un hobby che ti piace davvero?", "ru": "Какое хобби тебе по-настоящему нравится?", "zh": "你真正喜欢的爱好是什么？"],
        ["en": "What's the weather like where you are?", "tr": "Orada hava nasıl?", "de": "Wie ist das Wetter bei dir?", "fr": "Quel temps fait-il chez toi ?",
         "es": "¿Qué tiempo hace donde estás?", "it": "Che tempo fa da te?", "ru": "Какая у тебя сейчас погода?", "zh": "你那里天气怎么样？"],
        ["en": "What would you like to learn next?", "tr": "Sırada ne öğrenmek istersin?", "de": "Was möchtest du als Nächstes lernen?", "fr": "Qu'aimerais-tu apprendre ensuite ?",
         "es": "¿Qué te gustaría aprender ahora?", "it": "Cosa ti piacerebbe imparare adesso?", "ru": "Чему бы ты хотел научиться дальше?", "zh": "你接下来想学什么？"],
    ]
}
