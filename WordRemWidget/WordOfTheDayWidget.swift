//
//  WordOfTheDayWidget.swift
//  WordRemWidget
//
//  Kullanıcının quiz'de öğrendiği kelimelerden birini ana ekranda gösterir.
//  Kelime her 3 saatte bir değişir.
//

import WidgetKit
import SwiftUI

// MARK: - Entry
struct WordEntry: TimelineEntry {
    let date: Date
    let word: LearnedWord?
    let learnedCount: Int
    let nativeLangCode: String
}

// MARK: - Provider
struct WordOfTheDayProvider: TimelineProvider {

    private static let rotationHours = 3

    func placeholder(in context: Context) -> WordEntry {
        WordEntry(date: .now, word: .sample, learnedCount: 42, nativeLangCode: "en")
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        let words = LearnedWordsStore.load()
        // Widget galerisinde boş görünmesin
        let word = words.isEmpty && context.isPreview ? .sample : pick(from: words, at: .now)
        completion(WordEntry(date: .now, word: word, learnedCount: words.count,
                             nativeLangCode: LearnedWordsStore.nativeLangCode))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let words = LearnedWordsStore.load()
        let native = LearnedWordsStore.nativeLangCode
        let calendar = Calendar.current
        let now = Date()
        // Mevcut 3 saatlik dilimin başından itibaren 24 saatlik giriş üret
        let hour = calendar.component(.hour, from: now)
        let slotStart = calendar.date(bySettingHour: hour - hour % Self.rotationHours,
                                      minute: 0, second: 0, of: now) ?? now

        let entries: [WordEntry] = (0..<(24 / Self.rotationHours)).compactMap { i in
            guard let date = calendar.date(byAdding: .hour, value: i * Self.rotationHours, to: slotStart) else { return nil }
            return WordEntry(date: date, word: pick(from: words, at: date),
                             learnedCount: words.count, nativeLangCode: native)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Aynı zaman dilimi için her zaman aynı kelimeyi seçer (widget yenilense de kelime zıplamaz)
    private func pick(from words: [LearnedWord], at date: Date) -> LearnedWord? {
        guard !words.isEmpty else { return nil }
        let slot = Int(date.timeIntervalSince1970) / (Self.rotationHours * 3600)
        // Ardışık dilimler listede yan yana kelimeleri seçmesin diye büyük bir asal ile dağıt
        return words[(slot &* 7919) % words.count]
    }
}

// MARK: - Palette
private enum Palette {
    static let accent = Color(red: 0.761, green: 0.318, blue: 0.184) // #C2512F — uygulamanın imza rengi (terracotta)
    static let ink    = Color.primary
    static let muted  = Color.secondary
    static let paper  = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor.systemBackground
        : UIColor(red: 0.965, green: 0.949, blue: 0.918, alpha: 1) })   // #F6F2EA
}

// MARK: - Views
struct WordOfTheDayView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WordEntry

    var body: some View {
        Group {
            if let word = entry.word {
                switch family {
                case .systemMedium: medium(word)
                default:            small(word)
                }
            } else {
                emptyState
            }
        }
        .containerBackground(for: .widget) {
            // Açık modda uygulamanın kâğıt zemini, koyu modda sistem zemini
            Palette.paper
        }
    }

    // Küçük: dil etiketi, kelime, anlam
    private func small(_ word: LearnedWord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            languageTag(word)
            Spacer(minLength: 6)
            Text(word.term)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            if let phonetic = word.phonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            Spacer(minLength: 6)
            Rectangle()
                .fill(Palette.accent)
                .frame(width: 18, height: 2)
                .padding(.bottom, 6)
            Text(word.meaning)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // Orta: solda kelime, sağda anlam + öğrenilen kelime sayısı
    private func medium(_ word: LearnedWord) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                languageTag(word)
                Spacer(minLength: 8)
                Text(word.term)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let phonetic = word.phonetic, !phonetic.isEmpty {
                    Text(phonetic)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(word.meaning)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Text(WidgetStrings.learnedCount(entry.learnedCount, lang: entry.nativeLangCode))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
            }
            .frame(width: 112, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .leading)
        }
    }

    private func languageTag(_ word: LearnedWord) -> some View {
        Text(languageName(word.languageCode).uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(Palette.accent)
            .lineLimit(1)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WordRem")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Palette.accent)
            Spacer(minLength: 0)
            Text(WidgetStrings.emptyTitle(lang: entry.nativeLangCode))
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.ink)
            Text(WidgetStrings.emptyBody(lang: entry.nativeLangCode))
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func languageName(_ code: String) -> String {
        Locale(identifier: entry.nativeLangCode)
            .localizedString(forLanguageCode: code.lowercased()) ?? code
    }
}

// MARK: - Strings (widget kendi küçük çeviri tablosunu taşır)
enum WidgetStrings {
    static func emptyTitle(lang: String) -> String {
        switch lang {
        case "tr": return "Günün kelimesi"
        case "de": return "Wort des Tages"
        case "fr": return "Mot du jour"
        case "es": return "Palabra del día"
        case "it": return "Parola del giorno"
        case "ru": return "Слово дня"
        case "zh": return "每日一词"
        default:   return "Word of the day"
        }
    }

    static func emptyBody(lang: String) -> String {
        switch lang {
        case "tr": return "Bir ders bitir, öğrendiğin kelimeler burada görünsün."
        case "de": return "Schließe eine Lektion ab, um deine Wörter hier zu sehen."
        case "fr": return "Termine une leçon pour voir tes mots ici."
        case "es": return "Completa una lección para ver tus palabras aquí."
        case "it": return "Completa una lezione per vedere qui le tue parole."
        case "ru": return "Пройди урок, и выученные слова появятся здесь."
        case "zh": return "完成一节课，学过的单词就会显示在这里。"
        default:   return "Finish a lesson to see the words you've learned here."
        }
    }

    static func learnedCount(_ n: Int, lang: String) -> String {
        switch lang {
        case "tr": return "\(n) kelime öğrendin"
        case "de": return "\(n) Wörter gelernt"
        case "fr": return "\(n) mots appris"
        case "es": return "\(n) palabras aprendidas"
        case "it": return "\(n) parole imparate"
        case "ru": return "Выучено слов: \(n)"
        case "zh": return "已学 \(n) 个单词"
        default:   return n == 1 ? "1 word learned" : "\(n) words learned"
        }
    }
}

// MARK: - Widget
struct WordOfTheDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: LearnedWordsStore.widgetKind, provider: WordOfTheDayProvider()) { entry in
            WordOfTheDayView(entry: entry)
        }
        .configurationDisplayName("Word of the Day")
        .description("A word you've learned in WordRem, refreshed every few hours.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension LearnedWord {
    static let sample = LearnedWord(id: "sample", term: "aprender", meaning: "to learn",
                                    phonetic: "/a.pɾenˈdeɾ/", languageCode: "ES", learnedAt: .now)
}

#Preview(as: .systemSmall) {
    WordOfTheDayWidget()
} timeline: {
    WordEntry(date: .now, word: .sample, learnedCount: 42, nativeLangCode: "en")
    WordEntry(date: .now, word: nil, learnedCount: 0, nativeLangCode: "tr")
}

#Preview(as: .systemMedium) {
    WordOfTheDayWidget()
} timeline: {
    WordEntry(date: .now, word: .sample, learnedCount: 42, nativeLangCode: "en")
}
