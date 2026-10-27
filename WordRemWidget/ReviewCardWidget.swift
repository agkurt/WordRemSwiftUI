//
//  ReviewCardWidget.swift
//  WordRemWidget
//
//  "Rem" widget'ları: unutulmak üzere olan kelime ana ekranda; dokun → anlamı aç → "Biliyorum / Tekrar".
//  Uygulama açılmadan SRS güncellenir (ReviewCore, App Group). Kilit ekranında kalan tekrar + seri.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Etkileşimler (iOS 17 düğmeli widget)
struct RevealReviewWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Show meaning"
    @Parameter(title: "Word") var wordId: String

    init() {}
    init(wordId: String) { self.wordId = wordId }

    func perform() async throws -> some IntentResult {
        ReviewCore.revealedWordId = wordId
        WidgetCenter.shared.reloadTimelines(ofKind: ReviewCore.reviewWidgetKind)
        return .result()
    }
}

struct GradeReviewWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Grade word"
    @Parameter(title: "Word") var wordId: String
    @Parameter(title: "Remembered") var remembered: Bool

    init() {}
    init(wordId: String, remembered: Bool) {
        self.wordId = wordId
        self.remembered = remembered
    }

    func perform() async throws -> some IntentResult {
        ReviewCore.revealedWordId = nil
        ReviewCore.grade(wordId: wordId, remembered ? .good : .again)
        return .result()
    }
}

// MARK: - Zaman çizelgesi
struct ReviewEntry: TimelineEntry {
    let date: Date
    let word: LearnedWord?
    let revealed: Bool
    let dueCount: Int
    let streak: Int
    let lang: String
}

struct ReviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReviewEntry {
        ReviewEntry(date: Date(),
                    word: LearnedWord(id: "p", term: "aprender", meaning: "öğrenmek", phonetic: nil, languageCode: "ES", learnedAt: Date()),
                    revealed: false, dueCount: 3, streak: 5, lang: LearnedWordsStore.nativeLangCode)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReviewEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReviewEntry>) -> Void) {
        let now = Date()
        let states = ReviewCore.loadStates()
        // Bir sonraki kelimenin vadesi gelince ya da en geç bir saat sonra yenile
        let nextDue = states.values.map(\.due).filter { $0 > now }.min() ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry()], policy: .after(min(nextDue, now.addingTimeInterval(3600)))))
    }

    private func entry() -> ReviewEntry {
        let now = Date()
        let due = ReviewCore.due(by: now, words: LearnedWordsStore.load(), states: ReviewCore.loadStates())
        let word = due.first
        return ReviewEntry(date: now, word: word,
                           revealed: word != nil && ReviewCore.revealedWordId == word?.id,
                           dueCount: due.count,
                           streak: ReviewCore.streak(activeDays: ReviewCore.loadActiveDays()),
                           lang: LearnedWordsStore.nativeLangCode)
    }
}

// MARK: - Görünüm
struct ReviewCardView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReviewEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:      inline
            case .accessoryCircular:    circular
            case .accessoryRectangular: rectangular
            default:                    card
            }
        }
        .containerBackground(for: .widget) { Palette.paper }
    }

    private var s: ReviewStrings { ReviewStrings(lang: entry.lang) }

    // Ana ekran kartı
    @ViewBuilder
    private var card: some View {
        if let word = entry.word {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(s.reviews(entry.dueCount).uppercased())
                        .font(.system(size: 10, weight: .bold)).tracking(1.1)
                        .foregroundStyle(Palette.accent)
                    Spacer()
                    if entry.streak > 0 {
                        Text("🔥 \(entry.streak)").font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
                    }
                }
                Spacer(minLength: 4)
                Text(word.term)
                    .font(.system(size: family == .systemMedium ? 30 : 24, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2).minimumScaleFactor(0.6)
                if entry.revealed {
                    Text(word.meaning)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                Spacer(minLength: 6)
                if entry.revealed {
                    HStack(spacing: 8) {
                        Button(intent: GradeReviewWordIntent(wordId: word.id, remembered: false)) {
                            Label(s.again, systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .tint(Palette.muted)
                        Button(intent: GradeReviewWordIntent(wordId: word.id, remembered: true)) {
                            Label(s.known, systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .tint(Palette.accent)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .labelStyle(family == .systemMedium ? AnyLabelStyle(.titleAndIcon) : AnyLabelStyle(.iconOnly))
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(intent: RevealReviewWordIntent(wordId: word.id)) {
                        Text(s.show).frame(maxWidth: .infinity)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.ink)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("WordRem").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundStyle(Palette.accent)
                Spacer(minLength: 0)
                Text(s.allDone)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.ink)
                Text(entry.streak > 0 ? "🔥 \(s.streak(entry.streak))" : s.comeBack)
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // Kilit ekranı
    private var inline: some View {
        Text(entry.dueCount > 0 ? "↻ \(s.reviews(entry.dueCount)) · 🔥\(entry.streak)" : "✓ \(s.allDone) · 🔥\(entry.streak)")
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(entry.dueCount)").font(.system(size: 20, weight: .bold, design: .rounded))
                Image(systemName: entry.dueCount > 0 ? "arrow.triangle.2.circlepath" : "checkmark").font(.system(size: 10, weight: .bold))
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.dueCount > 0 ? s.reviews(entry.dueCount) : s.allDone)
                .font(.system(size: 13, weight: .semibold))
            if let word = entry.word {
                Text(word.term).font(.system(size: 16, weight: .bold)).lineLimit(1)
            }
            Text("🔥 \(s.streak(entry.streak))").font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Label stillerini koşullu seçmek için
struct AnyLabelStyle: LabelStyle {
    private let make: (Configuration) -> AnyView
    init<S: LabelStyle>(_ style: S) { make = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}

// MARK: - Metinler (widget kendi küçük çeviri tablosunu taşır)
struct ReviewStrings {
    let lang: String
    private func pick(_ v: [String: String]) -> String { v[lang] ?? v["en"]! }

    var show: String { pick(["tr": "Göster", "en": "Show", "de": "Zeigen", "fr": "Voir", "es": "Ver", "it": "Mostra", "ru": "Показать", "zh": "显示"]) }
    var known: String { pick(["tr": "Biliyorum", "en": "Got it", "de": "Weiß ich", "fr": "Je sais", "es": "Lo sé", "it": "Lo so", "ru": "Знаю", "zh": "记得"]) }
    var again: String { pick(["tr": "Tekrar", "en": "Again", "de": "Nochmal", "fr": "Encore", "es": "Otra vez", "it": "Ancora", "ru": "Ещё раз", "zh": "再来"]) }
    var allDone: String { pick(["tr": "Hepsi tamam", "en": "All caught up", "de": "Alles erledigt", "fr": "Tout est à jour", "es": "Todo al día", "it": "Tutto fatto", "ru": "Всё повторено", "zh": "全部完成"]) }
    var comeBack: String { pick(["tr": "Yeni kelimeler öğren", "en": "Learn some new words", "de": "Lerne neue Wörter", "fr": "Apprends de nouveaux mots", "es": "Aprende palabras nuevas", "it": "Impara nuove parole", "ru": "Выучи новые слова", "zh": "学些新单词"]) }

    func reviews(_ n: Int) -> String {
        switch lang {
        case "tr": return "\(n) tekrar"
        case "de": return "\(n) Wiederholungen"
        case "fr": return "\(n) à réviser"
        case "es": return "\(n) repasos"
        case "it": return "\(n) ripassi"
        case "ru": return "Повторить: \(n)"
        case "zh": return "\(n) 个待复习"
        default:   return "\(n) to review"
        }
    }

    func streak(_ n: Int) -> String {
        switch lang {
        case "tr": return "\(n) gün seri"
        case "de": return "\(n) Tage Serie"
        case "fr": return "\(n) jours d'affilée"
        case "es": return "\(n) días seguidos"
        case "it": return "\(n) giorni di fila"
        case "ru": return "Серия: \(n) дн."
        case "zh": return "连续 \(n) 天"
        default:   return "\(n)-day streak"
        }
    }
}

struct ReviewCardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ReviewCore.reviewWidgetKind, provider: ReviewProvider()) { entry in
            ReviewCardView(entry: entry)
        }
        .configurationDisplayName("WordRem")
        .description(ReviewStrings(lang: LearnedWordsStore.nativeLangCode).reviews(0).replacingOccurrences(of: "0", with: "").trimmingCharacters(in: .whitespaces))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

// MARK: - "Lupa seni bekliyor": günün sorusu; dokununca Lupa sohbeti bu soruyla açar
struct LupaEntry: TimelineEntry {
    let date: Date
    let index: Int
    let target: String
    let native: String
}

/// Gece yarısı yeni gün: yeni soru, seri durumu sıfırlanır
private func nextMidnight(after date: Date) -> Date {
    Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date)) ?? date.addingTimeInterval(3600)
}

struct LupaProvider: TimelineProvider {
    func placeholder(in context: Context) -> LupaEntry { LupaEntry(date: Date(), index: 0, target: "en", native: LupaShared.nativeLang) }
    func getSnapshot(in context: Context, completion: @escaping (LupaEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LupaEntry>) -> Void) {
        let now = Date()
        completion(Timeline(entries: [entry(now)], policy: .after(nextMidnight(after: now))))
    }
    private func entry(_ now: Date = Date()) -> LupaEntry {
        LupaEntry(date: now, index: LupaShared.questionIndex(for: now), target: LupaShared.targetLang, native: LupaShared.nativeLang)
    }
}

struct LupaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LupaEntry
    private var s: LupaStrings { LupaStrings(lang: entry.native) }
    private var question: String { LupaShared.question(entry.index, lang: entry.target) }
    private var meaning: String { LupaShared.question(entry.index, lang: entry.native) }

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text(LupaShared.name).font(.system(size: 12, weight: .bold))
                    Text(question).font(.system(size: 14, weight: .semibold)).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                card
            }
        }
        .widgetURL(LupaShared.url(question: entry.index))
        .containerBackground(for: .widget) { Palette.paper }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("L")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Palette.accent, in: Circle())
                Text(s.waiting.uppercased())
                    .font(.system(size: 10, weight: .bold)).tracking(1.0)
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 6)
            Text(question)
                .font(.system(size: family == .systemMedium ? 24 : 19, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.ink)
                .lineLimit(3).minimumScaleFactor(0.6)
            if entry.target != entry.native {
                Text(meaning)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
                    .padding(.top, 3)
            }
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                Image(systemName: "mic.fill").font(.system(size: 11, weight: .bold))
                Text(s.answer).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Palette.accent, in: Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct LupaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: LupaShared.widgetKind, provider: LupaProvider()) { LupaWidgetView(entry: $0) }
            .configurationDisplayName(LupaShared.name)
            .description(LupaStrings(lang: LupaShared.nativeLang).description)
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct LupaStrings {
    let lang: String
    private func pick(_ v: [String: String]) -> String { v[lang] ?? v["en"]! }
    var waiting: String { pick(["tr": "Lupa seni bekliyor", "en": "Lupa is waiting", "de": "Lupa wartet auf dich", "fr": "Lupa t'attend",
                                "es": "Lupa te espera", "it": "Lupa ti aspetta", "ru": "Lupa ждёт тебя", "zh": "Lupa 在等你"]) }
    var answer: String { pick(["tr": "Cevapla", "en": "Answer", "de": "Antworten", "fr": "Répondre",
                               "es": "Responder", "it": "Rispondi", "ru": "Ответить", "zh": "回答"]) }
    var description: String { pick(["tr": "Lupa'nın günün sorusu: dokun, sesli cevapla.", "en": "Lupa's question of the day: tap and answer out loud.",
                                     "de": "Lupas Frage des Tages: tippen und laut antworten.", "fr": "La question du jour de Lupa : touche et réponds à voix haute.",
                                     "es": "La pregunta del día de Lupa: toca y responde en voz alta.", "it": "La domanda del giorno di Lupa: tocca e rispondi a voce.",
                                     "ru": "Вопрос дня от Lupa: нажми и ответь вслух.", "zh": "Lupa 的每日一问：点一下，开口回答。"]) }
}

// MARK: - Seri: alev, gün sayısı, bugün tamam mı; son 7 gün
struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let doneToday: Bool
    let week: [Bool]          // eskiden yeniye 7 gün
    let lang: String
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 5, doneToday: true, week: [true, true, false, true, true, true, true], lang: LupaShared.nativeLang)
    }
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let now = Date()
        completion(Timeline(entries: [entry(now)], policy: .after(nextMidnight(after: now))))
    }
    private func entry(_ now: Date = Date()) -> StreakEntry {
        let days = ReviewCore.loadActiveDays()
        let cal = Calendar.current
        let week = (0..<7).reversed().map { i -> Bool in
            guard let d = cal.date(byAdding: .day, value: -i, to: now) else { return false }
            return days.contains(ReviewCore.dayKey(d))
        }
        return StreakEntry(date: now, streak: ReviewCore.streak(activeDays: days, now: now),
                           doneToday: days.contains(ReviewCore.dayKey(now)), week: week, lang: LupaShared.nativeLang)
    }
}

struct StreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry
    private var s: StreakStrings { StreakStrings(lang: entry.lang) }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text("🔥 \(entry.streak) · \(entry.doneToday ? s.done : s.notYet)")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Circle().trim(from: 0, to: entry.doneToday ? 1 : 0.0001)
                        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90)).padding(2)
                    VStack(spacing: -1) {
                        Image(systemName: "flame.fill").font(.system(size: 12, weight: .bold))
                        Text("\(entry.streak)").font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                }
                .widgetAccentable()
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("🔥 \(s.days(entry.streak))").font(.system(size: 15, weight: .bold))
                    Text(entry.doneToday ? "✓ \(s.done)" : s.keepIt).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    weekDots(size: 7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 24, weight: .bold))
                            .foregroundStyle(entry.doneToday ? Palette.accent : Palette.muted)
                        Text("\(entry.streak)").font(.system(size: 40, weight: .bold, design: .serif)).foregroundStyle(Palette.ink)
                    }
                    Text(s.dayStreak(entry.streak)).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.muted)
                    Spacer(minLength: 6)
                    weekDots(size: 11)
                    Spacer(minLength: 6)
                    Text(entry.doneToday ? "✓ \(s.done)" : s.keepIt)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(entry.doneToday ? Palette.ink : Palette.accent)
                        .lineLimit(2).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .widgetURL(LupaShared.streakURL)
        .containerBackground(for: .widget) { Palette.paper }
    }

    private func weekDots(size: CGFloat) -> some View {
        HStack(spacing: size * 0.5) {
            ForEach(Array(entry.week.enumerated()), id: \.offset) { i, on in
                Circle()
                    .fill(on ? Palette.accent : Palette.muted.opacity(0.25))
                    .frame(width: size, height: size)
                    .overlay(i == 6 && !on ? Circle().stroke(Palette.accent, lineWidth: 1.2) : nil)
            }
        }
    }
}

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: LupaShared.streakWidgetKind, provider: StreakProvider()) { StreakWidgetView(entry: $0) }
            .configurationDisplayName(StreakStrings(lang: LupaShared.nativeLang).title)
            .description(StreakStrings(lang: LupaShared.nativeLang).description)
            .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct StreakStrings {
    let lang: String
    private func pick(_ v: [String: String]) -> String { v[lang] ?? v["en"]! }
    var title: String { pick(["tr": "Seri", "en": "Streak", "de": "Serie", "fr": "Série", "es": "Racha", "it": "Serie", "ru": "Серия", "zh": "连续学习"]) }
    var done: String { pick(["tr": "Bugün tamam", "en": "Done today", "de": "Heute erledigt", "fr": "Fait aujourd'hui",
                             "es": "Hecho hoy", "it": "Fatto oggi", "ru": "Сегодня готово", "zh": "今天已完成"]) }
    var notYet: String { pick(["tr": "Bugün henüz değil", "en": "Not yet today", "de": "Heute noch nicht", "fr": "Pas encore aujourd'hui",
                               "es": "Hoy aún no", "it": "Oggi non ancora", "ru": "Сегодня ещё нет", "zh": "今天还没有"]) }
    var keepIt: String { pick(["tr": "Lupa ile 2 dk konuş, seriyi koru", "en": "Talk to Lupa for 2 min to keep it", "de": "2 Min. mit Lupa sprechen und Serie halten",
                               "fr": "Parle 2 min avec Lupa pour la garder", "es": "Habla 2 min con Lupa y mantenla", "it": "Parla 2 min con Lupa e mantienila",
                               "ru": "Поговори с Lupa 2 мин, чтобы сохранить", "zh": "和 Lupa 聊 2 分钟，保持连续"]) }
    var description: String { pick(["tr": "Serin ve bu haftan bir bakışta.", "en": "Your streak and week at a glance.", "de": "Deine Serie und Woche auf einen Blick.",
                                    "fr": "Ta série et ta semaine en un coup d'œil.", "es": "Tu racha y tu semana de un vistazo.", "it": "La tua serie e la settimana a colpo d'occhio.",
                                    "ru": "Твоя серия и неделя с одного взгляда.", "zh": "一眼看到你的连续天数和本周。"]) }
    func days(_ n: Int) -> String { ReviewStrings(lang: lang).streak(n) }
    func dayStreak(_ n: Int) -> String {
        pick(["tr": "gün seri", "en": "day streak", "de": "Tage Serie", "fr": "jours d'affilée",
              "es": "días seguidos", "it": "giorni di fila", "ru": "дн. подряд", "zh": "天连续"])
    }
}
