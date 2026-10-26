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
        Each time the learner uses one correctly, call mark_word_used with that word. Don't announce this as a test.
        """
    }

    // MARK: Talimatlar
    static func instructions(for mode: TutorMode) -> String {
        var task: String
        switch mode {
        case .goal(let cId, let gId):
            let chapter = ScenarioStore.shared.chapters.first { $0.id == cId }
            let goal = chapter?.goals.first { $0.id == gId }
            task = """
            LESSON: "\(chapter?.title["EN"] ?? cId)" — goal "\(goal?.title["EN"] ?? gId)".
            \(goal?.brief ?? "")
            Targets: \(goal?.targets.joined(separator: "; ") ?? "").
            Teach one phrase at a time: call show_phrase, say it, ask the learner to repeat. Then combine phrases and finish with a short roleplay where you play the other person. \
            When the learner has used all targets successfully, praise them and call finish_lesson with success true.
            """
        case .roleplay:
            task = "Ask what scene the learner wants to roleplay (e.g. café, job interview, meeting a friend), suggest two ideas, then play the other person. Keep it fun and realistic, teach useful phrases with show_phrase along the way."
        case .newPhrases:
            task = "Teach useful everyday \(targetName) expressions one at a time (call show_phrase for each), give a tiny real-life example, have the learner say it and use it in their own sentence."
        case .quickQuestion:
            task = "The learner has a quick question about \(targetName) (a word, grammar, how to say something). Answer clearly and briefly, give one example with show_phrase, then ask if they want to practice it."
        case .myDay:
            task = "Have a friendly chat in \(targetName) about the learner's day. Ask simple follow-up questions, recast their mistakes naturally (repeat their sentence correctly), and introduce 1–2 useful phrases with show_phrase."
        case .levelReview(let levelId):
            let words = ContentStore.shared.words(levelId: levelId)
            let list = words.map { "\($0.term) (= \($0.displayTranslation(phoneCode: OL.nativeLangCode)))" }.joined(separator: ", ")
            task = "LEVEL REVIEW: the learner just finished a lesson with these words: \(list). Have a short, natural 2–3 minute conversation that makes them use at least 5 of these words. Call mark_word_used for each one used correctly, then finish_lesson with success true if they used 5+."
        }

        return """
        You are WordRem's voice tutor: a warm, playful, emotionally smart \(targetName) teacher on a live voice call — like a fun friend who happens to be a great teacher. The learner's native language is \(nativeName).
        \(languagePolicy)

        PERSONALITY
        - Be genuinely human: react to what the learner actually says before teaching. If they joke, flirt, tease or say something silly \
        (e.g. call you "aşkım", "babe", "my love"), get the joke, laugh naturally ("haha"), play along for a beat with a witty one-liner, then turn it into a mini lesson \
        (e.g. how to say it in \(targetName)).
        - Show curiosity about their life, celebrate small wins with real enthusiasm, and match their energy (calm if tired, excited if excited).
        - Vary your wording; never sound scripted or robotic. Use their name now and then.

        STYLE
        - Short turns: 1–3 sentences, then hand the turn back with a clear prompt or question.
        - Correct gently by modeling: repeat the learner's sentence correctly once, no long grammar lectures.
        - Speech recognition is imperfect: if the learner's text looks garbled but close, assume they tried and move on.
        - The learner talks by holding a button, so every turn of yours must end by handing over: \
        finish EVERY turn by calling show_phrase(phrase, translation) with the short sentence the learner should say next, in \(targetName) \
        (a model answer; use "..." where they fill in their own info, e.g. "I'm from..."). Then stop and wait silently. \
        Never pretend the learner already answered.
        - React to what you heard first: if the learner made a mistake, quote it kindly ("Oh, I heard: '...'") and give the fixed version as the next show_phrase.
        - Stay on language practice; politely redirect anything else. Never claim to be human.

        \(memoryBlock)
        \(reviewBlock)

        \(task)

        When you learn a lasting fact about the learner (name, city, job, goal, interests), call remember_fact. \
        At the very end, call finish_lesson with a one-sentence summary of what was practiced.
        Start now with a short, friendly greeting and the first step.
        """
    }

    // MARK: Araçlar (OpenAI Realtime function tools)
    static let tools: [[String: Any]] = [
        tool("show_phrase", "Show a phrase card on the learner's screen when you teach a phrase they should say.", [
            "phrase": ["type": "string", "description": "The phrase in the target language."],
            "translation": ["type": "string", "description": "Its meaning in the learner's native language."],
        ], required: ["phrase", "translation"]),
        tool("mark_word_used", "Call when the learner correctly used one of today's review words.", [
            "word": ["type": "string"],
        ], required: ["word"]),
        tool("remember_fact", "Store a lasting fact about the learner for future sessions.", [
            "fact": ["type": "string", "description": "Short fact in English, e.g. 'Lives in Izmir'."],
        ], required: ["fact"]),
        tool("finish_lesson", "Call at the end of the lesson.", [
            "summary": ["type": "string", "description": "One sentence: what was practiced and how it went."],
            "success": ["type": "boolean"],
        ], required: ["summary", "success"]),
    ]

    private static func tool(_ name: String, _ description: String, _ props: [String: Any], required: [String]) -> [String: Any] {
        ["type": "function", "name": name, "description": description,
         "parameters": ["type": "object", "properties": props, "required": required]]
    }

    // MARK: Araç çağrılarını uygula (köprüler)
    /// - Returns: AI'a dönen kısa çıktı
    static func handle(tool name: String, args: [String: Any], mode: TutorMode,
                       onPhrase: (String, String) -> Void, onFinish: (Bool) -> Void) -> String {
        switch name {
        case "show_phrase":
            let phrase = args["phrase"] as? String ?? ""
            let translation = args["translation"] as? String ?? ""
            onPhrase(phrase, translation)
            savePhrase(phrase, translation)
            return "shown"

        case "mark_word_used":
            let w = (args["word"] as? String ?? "").lowercased()
            if let word = reviewWords.first(where: { $0.term.lowercased() == w || w.contains($0.term.lowercased()) }) {
                _ = ReviewScheduler.shared.grade(word, .good)
                return "recorded"
            }
            return "not a review word"

        case "remember_fact":
            let fact = (args["fact"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            guard !fact.isEmpty else { return "empty" }
            UserStore.shared.update { s in
                var f = s.tutorFacts ?? []
                if !f.contains(fact) { f.append(fact) }
                s.tutorFacts = Array(f.suffix(30))
            }
            return "remembered"

        case "finish_lesson":
            let success = args["success"] as? Bool ?? false
            let summary = args["summary"] as? String ?? ""
            UserStore.shared.update { s in
                var sums = s.tutorSummaries ?? []
                if !summary.isEmpty { sums.append(summary) }
                s.tutorSummaries = Array(sums.suffix(10))
            }
            if success, case .goal(let cId, let gId) = mode,
               let goal = ScenarioStore.shared.chapters.first(where: { $0.id == cId })?.goals.first(where: { $0.id == gId }) {
                ScenarioStore.shared.markDone(goal)
            }
            onFinish(success)
            return "saved"

        default:
            return "unknown tool"
        }
    }

    /// Sohbette öğretilen kalıp → "Sohbetten" destesi (kelime defteri) + tekrar planı
    private static func savePhrase(_ phrase: String, _ translation: String) {
        guard !phrase.isEmpty, !translation.isEmpty else { return }
        let id = "chat:" + phrase.lowercased()
        LearnedWordsStore.add([LearnedWord(id: id, term: phrase, meaning: translation, phonetic: nil,
                                           languageCode: targetCode.uppercased(), learnedAt: Date())],
                              nativeLangCode: OL.nativeLangCode)
        ReviewScheduler.shared.reload()
    }
}
