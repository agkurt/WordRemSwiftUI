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

    /// Günün tek bildirimi. Kullanıcıya göre üç akış:
    /// • Pro: seri tehlikede → yarım ders → pazar haftalık özet → tekrar sorusu → sıradaki ders / günün sorusu
    /// • Ücretsiz süresi bitmiş: gün aşırı Pro daveti (Lupa'nın ağzından), arada kelime tekrarı
    /// • Ücretsiz süresi duran: denemeye davet, sonra Pro'daki akış
    private static func content(for dayOffset: Int, fire: Date, words: [LearnedWord],
                                states: [String: ReviewState], days: Set<String>) -> UNMutableNotificationContent? {
        let c = UNMutableNotificationContent()
        c.sound = .default
        let streak = ReviewCore.streak(activeDays: days)
        let isPro = InAppPurchaseManager.shared.isPremium

        // Bildirimler Lupa'nın ağzından: başlık her zaman onun adı, metin kişisel
        c.title = LupaShared.name
        c.threadIdentifier = "lupa"

        if !isPro, FreeTrial.exhausted {
            // Sesli dersler kapalı: kelime tekrarı serbest, gün aşırı nazik Pro daveti (her seferinde farklı metin)
            let due = ReviewCore.due(by: fire, words: words, states: states)
            if dayOffset % 2 == 1, !due.isEmpty { return reviewContent(c, word: due[dayOffset % due.count], dueCount: due.count) }
            guard dayOffset % 2 == 0 else { return nil }
            let n = (Calendar.current.ordinality(of: .day, in: .era, for: fire) ?? 0) / 2
            c.body = LupaText.upsell(n)
            c.userInfo = ["kind": "upsell"]
            return c
        }

        if !isPro, dayOffset <= 1 {
            // Ücretsiz deneme dakikaları duruyor: ilk günlerde onu hatırlat
            c.body = LupaText.freeMinutesLeft
            c.userInfo = ["kind": "lupa", "question": LupaShared.questionIndex(for: fire)]
            return c
        }

        if dayOffset == 0, streak >= 2 {
            c.body = LupaText.streakRescue(streak)
            c.interruptionLevel = .timeSensitive
            c.userInfo = ["kind": "streak"]
            return c
        }

        if dayOffset == 1, let resume = pendingLesson {
            c.body = LupaText.resume(resume.title)
            c.userInfo = ["kind": "tutor", "chapterId": resume.chapterId, "goalId": resume.goalId]
            return c
        }

        // Pro'ya özel: pazar günü haftanın özeti (bu hafta biten dersler + seri)
        if isPro, Calendar.current.component(.weekday, from: fire) == 1 {
            let weekAgo = fire.addingTimeInterval(-7 * 86_400)
            let lessons = (UserStore.shared.snapshot.voiceGoalsDone ?? [:]).values.filter { $0 > weekAgo }.count
            if lessons > 0 {
                c.body = LupaText.weeklyRecap(lessons: lessons, streak: streak)
                c.userInfo = ["kind": "talk"]
                return c
            }
        }

        let due = ReviewCore.due(by: fire, words: words, states: states)
        if !due.isEmpty { return reviewContent(c, word: due[dayOffset % due.count], dueCount: due.count) }

        // Sıradaki ders ile Lupa'nın günün sorusu dönüşümlü
        if dayOffset % 2 == 0, let next = ScenarioStore.shared.next {
            c.body = LupaText.nextLesson(next.goal.localizedTitle)
            c.userInfo = ["kind": "tutor", "chapterId": next.chapter.id, "goalId": next.goal.id]
            return c
        }
        let q = LupaShared.questionIndex(for: fire)
        c.body = LupaText.question(LupaShared.question(q, lang: LearningLanguages.current))
        c.userInfo = ["kind": "lupa", "question": q]
        return c
    }

    /// Kelime sorusu (bildirimden "Hatırladım / Hatırlamadım")
    private static func reviewContent(_ c: UNMutableNotificationContent, word: LearnedWord, dueCount: Int) -> UNMutableNotificationContent {
        c.threadIdentifier = ""
        c.title = AL.s(.remReviewTitle)
            .replacingOccurrences(of: "{word}", with: word.meaning)
            .replacingOccurrences(of: "{lang}", with: targetLanguageName)
        c.body = AL.s(.remReviewBody) + (dueCount > 1 ? " " + AL.f(.remReviewMore, dueCount - 1) : "")
        c.categoryIdentifier = reviewCategory
        c.userInfo = ["kind": "review", "wordId": word.id]
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
            case "upsell":
                AppRouter.shared.route = .paywall
            case "lupa":
                AppRouter.shared.route = .lupa(question: info["question"] as? Int ?? LupaShared.questionIndex())
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
        /// Lupa widget'ı / bildirimi: serbest sohbet o günün sorusuyla açılır
        case lupa(question: Int)
        /// Ücretsiz süresi bitmiş kullanıcıya Pro daveti
        case paywall
    }
    @Published var route: Route?

    /// wordrem://lupa?q=3 · wordrem://talk
    func handle(_ url: URL) {
        guard url.scheme == "wordrem" else { return }
        switch url.host {
        case "lupa":
            let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "q" }?.value.flatMap(Int.init)
            route = .lupa(question: q ?? LupaShared.questionIndex())
        case "review": route = .review
        default: route = .talk
        }
    }
}

/// Lupa'nın bildirim metinleri (kullanıcının uygulama dilinde)
@MainActor
enum LupaText {
    private static func pick(_ v: [String: String]) -> String {
        v[LanguageManager.shared.currentLanguageCode] ?? v["en"]!
    }

    static func streakRescue(_ n: Int) -> String {
        pick(["tr": "🔥 \(n) günlük serin bu gece bitiyor! Benimle 2 dakika konuş, kurtaralım.",
              "en": "🔥 Your \(n)-day streak ends tonight! Talk with me for 2 minutes and let's save it.",
              "de": "🔥 Deine \(n)-Tage-Serie endet heute Nacht! Sprich 2 Minuten mit mir und wir retten sie.",
              "fr": "🔥 Ta série de \(n) jours se termine ce soir ! Parle 2 minutes avec moi pour la sauver.",
              "es": "🔥 ¡Tu racha de \(n) días termina esta noche! Habla conmigo 2 minutos y la salvamos.",
              "it": "🔥 La tua serie di \(n) giorni finisce stanotte! Parla con me 2 minuti e la salviamo.",
              "ru": "🔥 Твоя серия из \(n) дн. закончится сегодня ночью! Поговори со мной 2 минуты, и мы её сохраним.",
              "zh": "🔥 你连续 \(n) 天的记录今晚就要断了！和我聊 2 分钟，一起保住它。"])
    }

    static func resume(_ lesson: String) -> String {
        pick(["tr": "“\(lesson)” dersinde kaldık. Hadi birlikte bitirelim, seni bekliyorum!",
              "en": "We stopped in the middle of “\(lesson)”. Let's finish it together, I'm waiting!",
              "de": "Wir sind mitten in „\(lesson)“ stehen geblieben. Lass es uns zusammen beenden!",
              "fr": "On s'est arrêtés au milieu de « \(lesson) ». Finissons-le ensemble, je t'attends !",
              "es": "Nos quedamos a mitad de “\(lesson)”. ¡Terminémoslo juntos, te espero!",
              "it": "Ci siamo fermati a metà di “\(lesson)”. Finiamolo insieme, ti aspetto!",
              "ru": "Мы остановились посередине урока «\(lesson)». Давай закончим вместе, я жду!",
              "zh": "我们在“\(lesson)”中途停下了。一起把它完成吧，我在等你！"])
    }

    static func nextLesson(_ lesson: String) -> String {
        pick(["tr": "Bugün “\(lesson)” konuşalım mı? Senin için hazırladım.",
              "en": "Shall we do “\(lesson)” today? I've got it ready for you.",
              "de": "Wollen wir heute „\(lesson)“ machen? Ich habe alles vorbereitet.",
              "fr": "On fait « \(lesson) » aujourd'hui ? Je l'ai préparé pour toi.",
              "es": "¿Hacemos “\(lesson)” hoy? Ya lo tengo listo para ti.",
              "it": "Facciamo “\(lesson)” oggi? L'ho preparato per te.",
              "ru": "Займёмся сегодня уроком «\(lesson)»? Я всё подготовила.",
              "zh": "今天来练“\(lesson)”好吗？我已经为你准备好了。"])
    }

    static func question(_ q: String) -> String {
        pick(["tr": "Sana bir sorum var: “\(q)” Sesli cevapla!",
              "en": "I have a question for you: “\(q)” Answer me out loud!",
              "de": "Ich habe eine Frage an dich: „\(q)“ Antworte mir laut!",
              "fr": "J'ai une question pour toi : « \(q) » Réponds-moi à voix haute !",
              "es": "Tengo una pregunta para ti: “\(q)” ¡Respóndeme en voz alta!",
              "it": "Ho una domanda per te: “\(q)” Rispondimi a voce!",
              "ru": "У меня к тебе вопрос: «\(q)» Ответь вслух!",
              "zh": "我有个问题问你：“\(q)” 开口回答我吧！"])
    }
}

extension LupaText {
    /// Ücretsiz süresi bitmiş kullanıcı: gün aşırı, her seferinde farklı bir Pro daveti
    static func upsell(_ n: Int) -> String {
        let variants: [[String: String]] = [
            ["tr": "Deneme dersimiz bitti ama ben hâlâ buradayım! WordRem Pro ile her gün sınırsız konuşalım.",
             "en": "Our trial lesson is over, but I'm still here! Let's talk every day without limits with WordRem Pro.",
             "de": "Unsere Probestunde ist vorbei, aber ich bin noch da! Mit WordRem Pro sprechen wir jeden Tag ohne Limit.",
             "fr": "Notre leçon d'essai est finie, mais je suis toujours là ! Parlons chaque jour sans limite avec WordRem Pro.",
             "es": "Nuestra clase de prueba terminó, ¡pero sigo aquí! Hablemos cada día sin límites con WordRem Pro.",
             "it": "La nostra lezione di prova è finita, ma io sono ancora qui! Parliamo ogni giorno senza limiti con WordRem Pro.",
             "ru": "Пробный урок закончился, но я всё ещё здесь! С WordRem Pro будем говорить каждый день без ограничений.",
             "zh": "试听课结束了，但我还在这里！用 WordRem Pro，我们每天都能无限畅聊。"],
            ["tr": "İlk derste harika başladın. Devam etmek istersen WordRem Pro ile seni bekliyorum.",
             "en": "You made a great start in your first lesson. If you want to keep going, I'm waiting for you in WordRem Pro.",
             "de": "Du hattest einen tollen Start. Wenn du weitermachen willst, warte ich in WordRem Pro auf dich.",
             "fr": "Tu as super bien commencé. Si tu veux continuer, je t'attends dans WordRem Pro.",
             "es": "Empezaste genial en tu primera clase. Si quieres seguir, te espero en WordRem Pro.",
             "it": "Hai iniziato alla grande. Se vuoi continuare, ti aspetto in WordRem Pro.",
             "ru": "Ты отлично начал на первом уроке. Если хочешь продолжить, я жду тебя в WordRem Pro.",
             "zh": "你第一节课开了个好头。想继续的话，我在 WordRem Pro 等你。"],
            ["tr": "Bir dili konuşarak öğrenmenin sırrı her gün biraz pratik. WordRem Pro ile istediğin kadar konuşabilirsin.",
             "en": "The secret to speaking a language is a little practice every day. With WordRem Pro you can talk as much as you like.",
             "de": "Das Geheimnis beim Sprechenlernen: jeden Tag ein bisschen Übung. Mit WordRem Pro sprichst du so viel du willst.",
             "fr": "Le secret pour parler une langue : un peu de pratique chaque jour. Avec WordRem Pro, parle autant que tu veux.",
             "es": "El secreto para hablar un idioma es practicar un poco cada día. Con WordRem Pro puedes hablar todo lo que quieras.",
             "it": "Il segreto per parlare una lingua è un po' di pratica ogni giorno. Con WordRem Pro parli quanto vuoi.",
             "ru": "Секрет разговорной речи — немного практики каждый день. С WordRem Pro говори сколько хочешь.",
             "zh": "学会说一门语言的秘诀是每天练一点。有了 WordRem Pro，你想说多少就说多少。"],
        ]
        return pick(variants[((n % variants.count) + variants.count) % variants.count])
    }

    /// Ücretsiz deneme dakikaları henüz kullanılmadı
    static var freeMinutesLeft: String {
        pick(["tr": "Ücretsiz deneme dakikaların hâlâ duruyor. Gel, ilk sohbetimizi yapalım!",
              "en": "Your free trial minutes are still waiting. Come have our first chat!",
              "de": "Deine kostenlosen Probeminuten warten noch. Komm, lass uns zum ersten Mal sprechen!",
              "fr": "Tes minutes d'essai gratuites t'attendent encore. Viens, faisons notre première discussion !",
              "es": "Tus minutos de prueba gratis siguen esperando. ¡Ven, tengamos nuestra primera charla!",
              "it": "I tuoi minuti di prova gratuiti ti aspettano ancora. Vieni, facciamo la nostra prima chiacchierata!",
              "ru": "Твои бесплатные пробные минуты ещё ждут. Давай поговорим в первый раз!",
              "zh": "你的免费试用时间还在等你。来，我们第一次聊聊吧！"])
    }

    /// Pro: pazar günü haftanın özeti
    static func weeklyRecap(lessons: Int, streak: Int) -> String {
        let s = streak >= 2
        return pick(["tr": "Bu hafta \(lessons) ders bitirdin\(s ? ", \(streak) günlük serin de sürüyor 🔥" : "")! Seninle gurur duyuyorum. Yeni haftaya bir sohbetle başlayalım mı?",
                     "en": "You finished \(lessons) lessons this week\(s ? " and your \(streak)-day streak is going strong 🔥" : "")! I'm proud of you. Shall we start the new week with a chat?",
                     "de": "Du hast diese Woche \(lessons) Lektionen geschafft\(s ? " und deine \(streak)-Tage-Serie läuft 🔥" : "")! Ich bin stolz auf dich. Starten wir die neue Woche mit einem Gespräch?",
                     "fr": "Tu as terminé \(lessons) leçons cette semaine\(s ? " et ta série de \(streak) jours continue 🔥" : "")! Je suis fière de toi. On commence la semaine par une discussion ?",
                     "es": "¡Terminaste \(lessons) lecciones esta semana\(s ? " y tu racha de \(streak) días sigue 🔥" : "")! Estoy orgullosa de ti. ¿Empezamos la semana con una charla?",
                     "it": "Hai finito \(lessons) lezioni questa settimana\(s ? " e la tua serie di \(streak) giorni continua 🔥" : "")! Sono fiera di te. Iniziamo la settimana con una chiacchierata?",
                     "ru": "На этой неделе ты прошёл уроков: \(lessons)\(s ? ", а серия из \(streak) дн. продолжается 🔥" : "")! Я горжусь тобой. Начнём новую неделю с разговора?",
                     "zh": "这周你完成了 \(lessons) 节课\(s ? "，连续 \(streak) 天的记录还在继续 🔥" : "")！我为你骄傲。新的一周从聊天开始吧？"])
    }
}
