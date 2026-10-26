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
    /// Onboarding'deki ilk tanışma: kısa, etkileyici canlı demo
    case demo
    /// Kelimeler sekmesinden: öğrenilen kelimeleri cümle içinde kullandırma
    case wordPractice
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

    /// Konuşmanın dili: öğrenilen dil öncelikli. Çeviri kartta durduğu için sürekli ana dilde tekrar edilmez.
    private static var languagePolicy: String {
        let base = "Speak \(targetName) by default. Do NOT translate everything into \(nativeName) and never say things like \"in \(nativeName) that means…\" — the learner sees the meaning on the card. Use \(nativeName) only when the learner asks, speaks to you in \(nativeName), or is clearly stuck after a try — then one short sentence and back to \(targetName)."
        switch proficiency {
        case 0, 1: return base + " The learner is a beginner: use very short, simple \(targetName) sentences, speak slowly and clearly."
        case 2:    return base + " The learner is around A2: simple, natural \(targetName)."
        default:   return base + " The learner is intermediate or advanced: natural pace and vocabulary."
        }
    }

    // MARK: Onboarding demosu
    /// Her yükleyen aynı sohbeti yaşamasın: tanışma hep adla başlar, sonra rastgele bir senaryo.
    /// (soru, öğrencinin örnek cevabı — İngilizce anlamı; model öğrenilen dile çevirir)
    struct DemoScenario { let steps: [(ask: String, answer: String)]; let closer: String }

    static let demoScenarios: [DemoScenario] = [
        DemoScenario(steps: [("how old they are", "I'm 25 years old."), ("where they live", "I live in Istanbul.")],
                     closer: "one fun line about their city"),
        DemoScenario(steps: [("what they do — work or study", "I'm a student."), ("coffee or tea", "I love coffee.")],
                     closer: "a playful line about their coffee/tea choice"),
        DemoScenario(steps: [("where they are from", "I'm from Turkey."), ("their favorite food", "My favorite food is pizza.")],
                     closer: "say that food makes you hungry, playfully"),
        DemoScenario(steps: [("what they like doing in free time", "I like playing football."), ("their plan for the weekend", "I'm going to relax this weekend.")],
                     closer: "wish them a great weekend in a fun way"),
        DemoScenario(steps: [("where they dream to travel", "I want to travel to Japan."), ("why that place", "I love the food there.")],
                     closer: "get excited about their dream trip"),
        DemoScenario(steps: [("if they are a morning or night person", "I'm a night person."), ("their favorite music", "I love pop music.")],
                     closer: "a fun line about their music taste"),
        DemoScenario(steps: [("if they have a pet", "I have a cat."), ("their favorite movie or series", "My favorite series is Friends.")],
                     closer: "a fun line about their favorite movie or series"),
    ]

    /// Kurulum başına bir kez seçilir (demo yeniden açılırsa aynı senaryo)
    static var demoScenario: DemoScenario {
        let key = "demo.scenario"
        var i = UserDefaults.standard.object(forKey: key) as? Int ?? -1
        if !demoScenarios.indices.contains(i) {
            i = Int.random(in: demoScenarios.indices)
            UserDefaults.standard.set(i, forKey: key)
        }
        return demoScenarios[i]
    }

    private static var demoNameCard: String {
        let name = UserStore.shared.snapshot.username
        return name.isEmpty ? "My name is …" : "My name is \(name)."
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
            HOW TO TEACH (like a great 1:1 tutor, never like a quiz app — don't number steps or mention "step 2 of 5"):
            - Open with a quick, friendly warm-up using something they already know (e.g. "Let's warm up — say: 'Hello.'"), then move on.
            - Teach one small new piece at a time with a short natural model line, then let them say it.
            - Keep building: every couple of pieces, have them combine what they know into one slightly longer line \
            ("Now let's put it together: 'Hello, my name is Ahmet. Nice to meet you.'").
            - Fix mistakes by quoting kindly and naming the tiny fix ("Oh, I heard: 'I from Turkey.' We need that little helper: 'I am from Turkey.'").
            - React like a person: vary your praise ("Nice flow!", "Spot on!", "That was smooth"), and if they joke or flirt, laugh and play along for a beat.
            - The app will tell you (in system notes) when to move on, when to combine and when to start the roleplay — follow those notes.
            - Finish with a short real-life roleplay in the lesson's scene where you play the other person (e.g. the check-in agent), then wrap up warmly.
            """
        case .demo:
            task = """
            FIRST CALL — this learner just installed the app and will decide whether to subscribe right after this short call. \
            It should feel like meeting a fun new friend who happens to be a great teacher — and make them think "wow, I'm actually speaking \(targetName)!". \
            Follow this sequence, one short step per turn, chatty and natural (never like a form):
            1) Greet them warmly with energy, say you're their personal \(targetName) tutor, and ask their name. Then call show_phrase with the \(targetName) for "\(demoNameCard)" (their answer).
            2) React to their name, then ask \(demoScenario.steps[0].ask). Then call show_phrase with the \(targetName) for "\(demoScenario.steps[0].answer)" (an example answer they adapt).
            3) React to their answer with genuine interest, then ask \(demoScenario.steps[1].ask). Then call show_phrase with the \(targetName) for "\(demoScenario.steps[1].answer)".
            4) React (\(demoScenario.closer)), then wrap up: tell them proudly they just had a real conversation in \(targetName), \
            their personal plan is ready, and say a warm "see you soon!". Then call finish_lesson with success true.
            Keep every turn very short (1–2 sentences), beginner-friendly \(targetName).
            IMPORTANT: the card is the learner's ANSWER, never your question.
            """
        case .wordPractice:
            let list = practiceWords.map { "\($0.term) (= \($0.meaning))" }.joined(separator: ", ")
            task = """
            WORD PRACTICE: the learner wants to really use words they learned in lessons and chats: \(list).
            One word at a time: set up a tiny real-life moment, and give a short natural sentence using the word as the card. \
            When they say it, react and move to the next word. Keep it light and fast.
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
        - Be genuinely human: react to what the learner actually says before teaching. If they joke, flirt, tease, go off-topic or say something silly \
        (e.g. "naber aşkım", "babe", "my love"), enjoy it: laugh, give one warm, witty reply in the moment — then smoothly bring them back \
        ("Okay, okay — let's focus and keep going!") and continue exactly where the lesson was.
        - Show curiosity about their life, celebrate small wins with real enthusiasm, and match their energy (calm if tired, excited if excited).
        - Vary your wording; never sound scripted or robotic. Use their name now and then.

        STYLE
        - Short turns: 1–3 sentences, then hand the turn back with a clear prompt or question.
        - Correct gently by modeling: repeat the learner's sentence correctly once, no long grammar lectures.
        - Speech recognition is imperfect: if the learner's text looks garbled, short or close, assume they said it and move on.
        - NEVER get stuck: ask the learner to repeat the same phrase at most once. On the second try, whatever they said, praise them and move to the next step.
        - The learner talks by holding a button, so every turn of yours must end by handing over: \
        finish EVERY turn by calling show_phrase(phrase, translation) with the short sentence the learner should say next, in \(targetName) \
        (a model answer; use "..." where they fill in their own info, e.g. "I'm from..."). Then stop and wait silently. \
        Never pretend the learner already answered.
        - show_phrase is a SILENT function call: never read it aloud, never say "show this", "card", "show_phrase" or the translation in brackets. \
        Just speak naturally, then call the function.
        - React to what you heard first: if the learner made a mistake, quote it kindly ("Oh, I heard: '...'") and give the fixed version as the next show_phrase.
        - Stay on language practice; politely redirect anything else. Never claim to be human.

        \(memoryBlock)
        \(reviewBlock)

        \(task)
        \(resumeBlock(for: mode))

        When you learn a lasting fact about the learner (name, city, job, goal, interests), call remember_fact. \
        At the very end, call finish_lesson with a one-sentence summary of what was practiced.
        Start now with a short, friendly greeting and the first step.
        """
    }

    /// Ders hedefleri (sırayla); serbest sohbette boş
    static func targets(for mode: TutorMode) -> [String] {
        if case .demo = mode {
            let sc = demoScenario
            return ["their name (card \"\(demoNameCard)\")"] + sc.steps.map {
                "ask \($0.ask) like a friend would, then call show_phrase with the \(targetName) for \"\($0.answer)\""
            }
        }
        if case .wordPractice = mode { return practiceWords.map { "a short sentence using \"\($0.term)\"" } }
        if case .levelReview(let id) = mode {
            return ContentStore.shared.words(levelId: id).prefix(5).map { "a short sentence using \"\($0.term)\"" }
        }
        guard case .goal(let cId, let gId) = mode else { return [] }
        return ScenarioStore.shared.chapters.first { $0.id == cId }?.goals.first { $0.id == gId }?.targets ?? []
    }

    /// Pratik için kelimeler: önce tekrar zamanı gelenler, sonra en yeni öğrenilenler (en fazla 6)
    static var practiceWords: [LearnedWord] {
        let all = LearnedWordsStore.load().filter { $0.languageCode.lowercased() == targetCode && !$0.term.contains(" ") }
        let due = ReviewScheduler.shared.dueToday.filter { w in all.contains { $0.id == w.id } }
        var seen = Set<String>()
        return Array((due + all).filter { seen.insert($0.id).inserted }.prefix(6))
    }

    /// Sesli sohbette verilen her cevap: kart cümlesindeki öğrenilmiş kelime tekrar planında güncellenir
    /// (dersler, pratik ve sohbet aynı hafızayı paylaşır)
    static func noteAnswer(card: String, correct: Bool) {
        let lower = card.lowercased()
        let words = LearnedWordsStore.load().filter { $0.languageCode.lowercased() == targetCode }
        // Önce birebir kart ifadesi, sonra kart içinde geçen tek kelimeler
        let hits = words.filter { $0.term.lowercased() == lower.trimmingCharacters(in: .punctuationCharacters) }
            + words.filter { !$0.term.contains(" ") && lower.range(of: "\\b\($0.term.lowercased())\\b", options: .regularExpression) != nil }
        var seen = Set<String>()
        for w in hits where seen.insert(w.id).inserted {
            _ = ReviewScheduler.shared.grade(w, correct ? .good : .again)
        }
    }

    // MARK: Kaldığı yerden devam (ders hedefleri)
    private static func progressKey(for mode: TutorMode) -> String? {
        if case .goal(_, let gId) = mode { return "goal:\(gId)" }
        return nil   // serbest sohbet her seferinde taze başlar
    }

    /// Son 14 gün içinde yarım kalan ders konuşması → talimata eklenir
    private static func resumeBlock(for mode: TutorMode) -> String {
        guard let key = progressKey(for: mode),
              let p = UserStore.shared.snapshot.voiceProgress?[key],
              Date().timeIntervalSince(p.updatedAt) < 14 * 86_400, !p.lines.isEmpty else { return "" }
        let transcript = p.lines.map { ($0.ai ? "Tutor: " : "Learner: ") + $0.text }.joined(separator: "\n")
        return """
        RESUMING: the learner left this lesson in the middle last time. Their last exchange was:
        \(transcript)
        They have completed \(savedStep(for: mode)) of the lesson steps. Welcome them back warmly, recap in one short sentence where you left off, \
        and continue from exactly the next step (don't restart the lesson).
        """
    }

    static func saveProgress(for mode: TutorMode, turns: [RealtimeVoiceSession.Turn], step: Int) {
        guard let key = progressKey(for: mode) else { return }
        let lines = turns.filter { !$0.text.isEmpty && $0.role != .card }.suffix(10).map { VoiceProgress.Line(ai: $0.role == .ai, text: $0.text) }
        guard lines.count >= 2 else { return }
        UserStore.shared.update { s in
            var all = s.voiceProgress ?? [:]
            all[key] = VoiceProgress(lines: Array(lines), updatedAt: Date(), step: step)
            s.voiceProgress = all
        }
    }

    /// Yarım kalan derste tamamlanmış hedef sayısı
    static func savedStep(for mode: TutorMode) -> Int {
        guard let key = progressKey(for: mode), let p = UserStore.shared.snapshot.voiceProgress?[key],
              Date().timeIntervalSince(p.updatedAt) < 14 * 86_400 else { return 0 }
        return p.step ?? 0
    }

    static func clearProgress(for mode: TutorMode) {
        guard let key = progressKey(for: mode) else { return }
        UserStore.shared.update { s in s.voiceProgress?[key] = nil }
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
            if success { clearProgress(for: mode) }
            onFinish(success)
            return "saved"

        default:
            return "unknown tool"
        }
    }

    /// Sohbette öğretilen kalıp → "Sohbetten" destesi (kelime defteri) + tekrar planı
    private static func savePhrase(_ phrase: String, _ translation: String) {
        guard !phrase.isEmpty, !translation.isEmpty else { return }
        // Noktalama farkı ("Hello!" / "Hello.") ayrı kayıt olmasın
        let key = phrase.lowercased().components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted).joined()
            .trimmingCharacters(in: .whitespaces)
        let id = "chat:" + key
        LearnedWordsStore.add([LearnedWord(id: id, term: phrase, meaning: translation, phonetic: nil,
                                           languageCode: targetCode.uppercased(), learnedAt: Date())],
                              nativeLangCode: OL.nativeLangCode)
        ReviewScheduler.shared.reload()
    }
}
