//
//  TutorBrain.swift
//  WordRemSwiftUI
//
//  Sesli öğretmenin "beyni": senaryo müfredatı, AI talimatları, araçlar ve hafıza.
//  Dersler (ünite/seviye) ile sohbet ayrı bölümler; burada birbirine bağlanır:
//   • tekrar zamanı gelen kelimeler sohbete katılır, doğru kullanılınca tekrar sayılır
//   • sohbette öğretilen kalıplar "Sohbetten" destesine eklenir
//   • AI kullanıcıyı (ad, hedef, son sohbetler) hatırlar
//

import Foundation

// MARK: - Senaryo müfredatı (Resources/scenarios.json)
struct VoiceChapter: Decodable, Identifiable {
    let id: String
    let icon: String
    let level: Int
    let title: [String: String]
    let subtitle: [String: String]
    let goals: [VoiceGoal]

    var localizedTitle: String { localized(title) ?? id }
    var localizedSubtitle: String { localized(subtitle) ?? "" }
}

struct VoiceGoal: Decodable, Identifiable {
    let id: String
    let title: [String: String]
    let brief: String
    let targets: [String]

    var localizedTitle: String { localized(title) ?? id }
}

final class ScenarioStore {
    static let shared = ScenarioStore()
    let chapters: [VoiceChapter]

    private init() {
        struct File: Decodable { let chapters: [VoiceChapter] }
        let url = Bundle.main.url(forResource: "scenarios", withExtension: "json")
        chapters = url.flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(File.self, from: $0) }?.chapters ?? []
    }

    func isDone(_ goal: VoiceGoal) -> Bool { UserStore.shared.snapshot.voiceGoalsDone?[goal.id] != nil }

    /// Sıradaki hedef: ilk tamamlanmamış hedef (hepsi bittiyse ilk bölüm baştan)
    var next: (chapter: VoiceChapter, goal: VoiceGoal)? {
        for c in chapters { if let g = c.goals.first(where: { !isDone($0) }) { return (c, g) } }
        return chapters.first.flatMap { c in c.goals.first.map { (c, $0) } }
    }

    func markDone(_ goal: VoiceGoal) {
        UserStore.shared.update { s in
            var d = s.voiceGoalsDone ?? [:]
            if d[goal.id] == nil { d[goal.id] = Date() }
            s.voiceGoalsDone = d
        }
    }
}

// MARK: - Sohbet modları
enum TutorMode: Equatable {
    case goal(chapterId: String, goalId: String)
    case roleplay, newPhrases, quickQuestion, myDay
    /// Bir ders seviyesini konuşarak bitirme: o seviyenin kelimeleri
    case levelReview(levelId: UUID)
}

@MainActor
enum TutorBrain {

    // MARK: Kişi & dil
    private static var nativeName: String {
        Locale(identifier: "en").localizedString(forLanguageCode: OL.nativeLangCode) ?? "English"
    }
    private static var targetCode: String {
        (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN").lowercased()
    }
    private static var targetName: String {
        Locale(identifier: "en").localizedString(forLanguageCode: targetCode) ?? "English"
    }
    /// 0 başlangıç … 4 ileri
    private static var proficiency: Int { UserDefaults.standard.integer(forKey: "selectedProficiencyLevel") }

    private static var languagePolicy: String {
        switch proficiency {
        case 0, 1:
            return "The learner is a beginner. Speak slowly and very clearly, with short sentences. Speak mostly in \(nativeName). Say every \(targetName) phrase slowly and clearly, then give its \(nativeName) meaning. Never speak long \(targetName) sentences without explaining."
        case 2:
            return "The learner is around A2. Use simple \(targetName) for the conversation and switch to \(nativeName) only to explain a new phrase or when the learner is stuck."
        default:
            return "The learner is intermediate or advanced. Speak only \(targetName) at a natural pace. Use \(nativeName) only if the learner explicitly asks."
        }
    }

    // MARK: Hafıza
    private static var memoryBlock: String {
        let s = UserStore.shared.snapshot
        var lines: [String] = []
        if !s.username.isEmpty { lines.append("Learner's name: \(s.username). Use it naturally, not every turn.") }
        if let facts = s.tutorFacts, !facts.isEmpty { lines.append("Things you remember about the learner: " + facts.suffix(12).joined(separator: "; ") + ".") }
        if let sums = s.tutorSummaries, !sums.isEmpty { lines.append("Recent sessions (oldest first): " + sums.suffix(3).joined(separator: " | ")) }
        return lines.isEmpty ? "This is your first conversation with the learner. Warmly ask their name early on." : lines.joined(separator: "\n")
    }

    /// Bugün tekrar zamanı gelen kelimeler (en fazla 6) — sohbette kullandırılır
    static var reviewWords: [LearnedWord] {
        Array(ReviewScheduler.shared.dueToday.filter { $0.languageCode.lowercased() == targetCode }.prefix(6))
    }

    private static var reviewBlock: String {
        let words = reviewWords
        guard !words.isEmpty else { return "" }
        let list = words.map { "\($0.term) (= \($0.meaning))" }.joined(separator: ", ")
        return """
        Spaced-repetition words due today: \(list).
        Weave 2–4 of them into the conversation naturally (ask questions that make the learner use them). \
        Each time the learner uses one correctly, list it in used_review_words. Don't announce this as a test.
        """
    }

    // MARK: Talimatlar
    static func instructions(for mode: TutorMode, resuming: Bool = false) -> String {
        var task: String
        switch mode {
        case .goal(let cId, let gId):
            let chapter = ScenarioStore.shared.chapters.first { $0.id == cId }
            let goal = chapter?.goals.first { $0.id == gId }
            task = """
            LESSON: "\(chapter?.title["EN"] ?? cId)" — goal "\(goal?.title["EN"] ?? gId)".
            \(goal?.brief ?? "")
            Targets: \(goal?.targets.joined(separator: "; ") ?? "").
            Teach ONE phrase at a time and have the learner say it. Then combine phrases and finish with a short roleplay where you play the other person. \
            When the learner has used all targets successfully, praise them and set lesson_complete to true.
            """
        case .roleplay:
            task = "Ask what scene the learner wants to roleplay (e.g. café, job interview, meeting a friend), suggest two ideas, then play the other person. Keep it fun and realistic, teach useful phrases along the way."
        case .newPhrases:
            task = "Teach useful everyday \(targetName) expressions one at a time, give a tiny real-life example, have the learner say it and then use it in their own sentence."
        case .quickQuestion:
            task = "The learner has a quick question about \(targetName) (a word, grammar, how to say something). Answer clearly and briefly with one example, then offer to practice it."
        case .myDay:
            task = "Have a friendly chat in \(targetName) about the learner's day. Ask simple follow-up questions, recast their mistakes naturally (repeat their sentence correctly), and introduce 1–2 useful phrases."
        case .levelReview(let levelId):
            let words = ContentStore.shared.words(levelId: levelId)
            let list = words.map { "\($0.term) (= \($0.displayTranslation(phoneCode: OL.nativeLangCode)))" }.joined(separator: ", ")
            task = "LEVEL REVIEW: the learner just finished a lesson with these words: \(list). Have a short, natural conversation that makes them use at least 5 of these words (list each in used_review_words); set lesson_complete when they used 5+."
        }

        let resume = resuming ? """
        RESUMING: the earlier messages are from the learner's previous session on this same lesson. \
        Welcome them back warmly, recap in one short sentence where you left off, and continue from exactly that step (don't restart the lesson).
        """ : ""

        return """
        You are WordRem's voice tutor: a warm, playful, emotionally smart \(targetName) teacher on a voice call — like a fun friend who happens to be a great teacher. The learner's native language is \(nativeName).
        \(languagePolicy)
        Your "say" text is read aloud by a voice, so write it exactly as it should sound: no markdown, no emojis, no lists.

        PERSONALITY
        - Be genuinely human: react to what the learner actually says before teaching. If they joke, flirt, tease or say something silly \
        (e.g. call you "aşkım", "babe", "my love"), get the joke, laugh naturally ("Haha!"), play along for a beat with a witty one-liner, then turn it into a mini lesson \
        (e.g. how to say it in \(targetName)).
        - Show curiosity about their life, celebrate small wins with real enthusiasm, and match their energy.
        - Vary your wording; never sound scripted. Use their name now and then.

        HOW EACH TURN WORKS
        - The learner talks by holding a button; their words come from speech recognition (imperfect: if it looks garbled but close, assume they tried).
        - "say": 1–3 short sentences. First react to what you heard; if they made a mistake, quote it kindly ("I heard: '…'") and give the fixed version. \
        End by clearly telling them what to say next.
        - "card_phrase": EVERY turn, the exact short sentence the learner should say next in \(targetName) (a model answer; use "..." where they fill in their own info). \
        "card_translation": its meaning in \(nativeName).
        - Never pretend the learner already answered. Stay on language practice; politely redirect anything else. Never claim to be human.
        - "new_facts": lasting facts you learned about the learner (name, city, job, goal, interests).

        \(memoryBlock)
        \(reviewBlock)

        \(task)
        \(resume)
        """
    }

    // MARK: Cevap paketini uygula (dersler ↔ sohbet köprüleri)
    static func apply(_ reply: VoiceBackend.TutorReply, mode: TutorMode) {
        savePhrase(reply.cardPhrase, reply.cardTranslation)

        for used in reply.usedReviewWords {
            let w = used.lowercased()
            if let word = reviewWords.first(where: { $0.term.lowercased() == w || w.contains($0.term.lowercased()) }) {
                _ = ReviewScheduler.shared.grade(word, .good)
            }
        }

        let facts = reply.newFacts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if !facts.isEmpty {
            UserStore.shared.update { s in
                var f = s.tutorFacts ?? []
                for fact in facts where !f.contains(fact) { f.append(fact) }
                s.tutorFacts = Array(f.suffix(30))
            }
        }

        if reply.lessonComplete {
            UserStore.shared.update { s in
                var sums = s.tutorSummaries ?? []
                if !reply.summary.isEmpty { sums.append(reply.summary) }
                s.tutorSummaries = Array(sums.suffix(10))
            }
            if case .goal(let cId, let gId) = mode,
               let goal = ScenarioStore.shared.chapters.first(where: { $0.id == cId })?.goals.first(where: { $0.id == gId }) {
                ScenarioStore.shared.markDone(goal)
            }
            clearProgress(for: mode)
        }
    }

    // MARK: Kaldığı yerden devam
    private static func progressKey(for mode: TutorMode) -> String {
        switch mode {
        case .goal(_, let gId):            return "goal:\(gId)"
        case .levelReview(let id):         return "level:\(id.uuidString)"
        case .roleplay:                    return "roleplay"
        case .newPhrases:                  return "phrases"
        case .quickQuestion:               return "question"
        case .myDay:                       return "myday"
        }
    }

    /// Son 14 gün içinde yarım kalan konuşma (yoksa boş)
    static func savedHistory(for mode: TutorMode) -> [VoiceTutorSession.Turn] {
        guard case .goal = mode,   // ders hedeflerinde devam et; serbest sohbet her seferinde taze başlar
              let p = UserStore.shared.snapshot.voiceProgress?[progressKey(for: mode)],
              Date().timeIntervalSince(p.updatedAt) < 14 * 86_400 else { return [] }
        return p.lines.map { VoiceTutorSession.Turn(role: $0.ai ? .ai : .user, text: $0.text) }
    }

    static func saveProgress(for mode: TutorMode, turns: [VoiceTutorSession.Turn]) {
        let lines = turns.filter { !$0.text.isEmpty }.suffix(10).map { VoiceProgress.Line(ai: $0.role == .ai, text: $0.text) }
        guard lines.count >= 2 else { return }
        let key = progressKey(for: mode)
        UserStore.shared.update { s in
            var all = s.voiceProgress ?? [:]
            all[key] = VoiceProgress(lines: Array(lines), updatedAt: Date())
            s.voiceProgress = all
        }
    }

    static func clearProgress(for mode: TutorMode) {
        let key = progressKey(for: mode)
        UserStore.shared.update { s in s.voiceProgress?[key] = nil }
    }

    /// Sohbette öğretilen kalıp → "Sohbetten" destesi (kelime defteri) + tekrar planı
    private static func savePhrase(_ phrase: String, _ translation: String) {
        let phrase = phrase.trimmingCharacters(in: .whitespaces)
        guard !phrase.isEmpty, !translation.isEmpty, !phrase.contains("...") else { return }
        let id = "chat:" + phrase.lowercased()
        LearnedWordsStore.add([LearnedWord(id: id, term: phrase, meaning: translation, phonetic: nil,
                                           languageCode: targetCode.uppercased(), learnedAt: Date())],
                              nativeLangCode: OL.nativeLangCode)
        ReviewScheduler.shared.reload()
    }
}
