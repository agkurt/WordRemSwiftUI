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
