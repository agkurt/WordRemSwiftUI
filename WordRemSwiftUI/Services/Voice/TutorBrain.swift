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
import NaturalLanguage

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

    /// Plan ilerlemesi dil başına ayrı (bkz. LearningLanguages.goalKey)
    func isDone(_ goal: VoiceGoal) -> Bool { UserStore.shared.snapshot.voiceGoalsDone?[LearningLanguages.goalKey(goal.id)] != nil }

    /// Sıradaki hedef: ilk tamamlanmamış hedef (hepsi bittiyse ilk bölüm baştan)
    var next: (chapter: VoiceChapter, goal: VoiceGoal)? {
        for c in chapters { if let g = c.goals.first(where: { !isDone($0) }) { return (c, g) } }
        return chapters.first.flatMap { c in c.goals.first.map { (c, $0) } }
    }

    func markDone(_ goal: VoiceGoal) {
        UserStore.shared.update { s in
            var d = s.voiceGoalsDone ?? [:]
            let key = LearningLanguages.goalKey(goal.id)
            if d[key] == nil { d[key] = Date() }
            s.voiceGoalsDone = d
        }
    }
}

// MARK: - Sohbet modları
enum TutorMode: Equatable {
    case goal(chapterId: String, goalId: String)
    case roleplay, newPhrases, quickQuestion, myDay
    /// Ana sayfadaki "Asistanınla konuş": öğrenci ne yapmak istediğini söyler, dolu dolu serbest sohbet
    case freeChat
    /// Onboarding'deki ilk tanışma: kısa, etkileyici canlı demo
    case demo
    /// Kelimeler sekmesinden: öğrenilen kelimeleri cümle içinde kullandırma
    case wordPractice
    /// Bir ders seviyesini konuşarak bitirme: o seviyenin kelimeleri
    case levelReview(levelId: UUID)
    /// Yeni dil ekleme: ana dilde kısa kurulum konuşması, bitince öğrenilen dil değişir
    case languageSetup(code: String)
}

@MainActor
enum TutorBrain {

    // MARK: Kişi & dil
    /// Öğretmenin sabit adı (öğrencinin ana diline göre): her derste aynı kişi
    static var tutorName: String {
        switch OL.nativeLangCode.lowercased() {
        case "tr": return "Aleyna"
        case "de": return "Lena"
        case "fr": return "Chloé"
        case "es": return "Lucía"
        case "it": return "Giulia"
        case "ru": return "Anya"
        case "zh": return "Xiaoyu"
        default: return "Emma"
        }
    }

    private static var nativeName: String {
        Locale(identifier: "en").localizedString(forLanguageCode: OL.nativeLangCode) ?? "English"
    }
    /// Serbest sohbette öğrenci başka bir dile geçmek isterse (switch_language): yalnızca bu konuşma için
    static var sessionLanguage: String?
    static let teachableCodes = ["en", "es", "de", "fr", "it", "ru", "zh", "tr"]

    private static var targetCode: String {
        sessionLanguage ?? (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "EN").lowercased()
    }
    private static var targetName: String {
        Locale(identifier: "en").localizedString(forLanguageCode: targetCode) ?? "English"
    }
    /// 0 başlangıç … 4 ileri
    private static var proficiency: Int { UserDefaults.standard.integer(forKey: "selectedProficiencyLevel") }

    /// Konuşmanın dili seviyeye göre: başlangıçta öğretmen öğrencinin ana dilinde anlatır, yalnızca öğrettiği
    /// ifadeler öğrenilen dilde (Pingo gibi); seviye arttıkça öğrenilen dil ağırlık kazanır.
    private static var languagePolicy: String {
        let cardNote = "The card always shows the \(targetName) line with its \(nativeName) meaning, so never read translations out loud word by word."
        switch proficiency {
        case 0, 1, 2:
            return """
            SPEAK, DON'T ANNOUNCE: never talk about what you are going to do ("I'll ask you a question", "I'll show you an example card", \
            "let me think for a second", "let's act out a little scene, then it's your turn"). Just ask the question, give the example, play the scene.
            TEACHING LANGUAGE: the learner is a beginner. Teach like a private tutor who speaks their language: \
            explain, give instructions, ask your questions, praise and give tips in \(nativeName). \
            Use \(targetName) only for the words and phrases you are teaching: put them in quotes and say them slowly and clearly. \
            Keep it a REAL CONVERSATION, not a drill: ask them genuine questions about themselves and their life (in \(nativeName)), \
            and the card is how THEY would answer in \(targetName). Bring in a new phrase by using it in a question or a tiny situation, \
            not by "repeat after me"; ask them to repeat a line only when you are working on pronunciation. React to what they actually tell you. \
            ONE LANGUAGE: every sentence you say is a \(nativeName) sentence, including your greeting and your reactions. \
            \(targetName) appears ONLY as the short quoted phrase you are teaching, never as a whole sentence of yours \
            (no \(targetName) greetings, thanks or comments around your \(nativeName)). \(cardNote)
            HOW TO TEACH A BEGINNER (be a real coach):
            - Give pronunciation tips in \(nativeName) that point at the exact sound: which letter, how long, where the stress is, \
            and compare it to a familiar \(nativeName) sound ("stretch the 'ee' in 'Tee'", "say 'bitte' crisply, short 'i'").
            - Mix small exercises: "How would you say '…' in \(targetName)?", a choice between two phrases, swapping one word \
            (Kaffee → Tee), then using it in a tiny real situation.
            - Teach the phrases natives actually use in daily life, not stiff textbook lines (but keep them short and clear).
            - Every few steps, recap in one sentence what they can already say.
            - In roleplays, everything you say IN CHARACTER is in \(targetName) (short and simple, that is the whole point of the roleplay); \
            only a few \(nativeName) words of help outside the character when they need it.
            """
        case 3:
            return "Speak simple, natural \(targetName) almost all the time. Use \(nativeName) only when they are stuck or a new word needs explaining: then make it one separate short \(nativeName) sentence. Never mix the two languages inside one sentence. \(cardNote) \(nativeFluency)"
        default:
            return "Speak \(targetName) at a natural pace. Use \(nativeName) only if the learner asks or is clearly stuck, in one short sentence. \(cardNote) \(nativeFluency)"
        }
    }

    /// Canlandırmalar gerçek hayat gibi: seviyeye göre küçük bir pürüz
    private static var roleplayFriction: String {
        proficiency <= 2
            ? "Make roleplays feel real but easy: one small realistic twist (e.g. \"we're out of tea, coffee?\"), always friendly and simple."
            : "Make roleplays feel real: add a little realistic friction once (you're slightly distracted, a detail is wrong, or you misunderstand them once) so they have to clarify, then resolve it."
    }

    /// Orta-ileri seviye: ders kitabı dili değil, gerçek günlük konuşma
    private static var nativeFluency: String {
        """
        NATURAL SPEECH: talk like a native speaker of \(targetName) does in everyday life, with natural connected speech and \
        common conversational fillers of \(targetName) (for English e.g. "gonna", "wanna", "you know", "I mean"). \
        If the learner uses a stiff, textbook phrase, praise it, then show the casual everyday way a native would say it and show that version.
        """
    }

    /// Öğrenci başka bir dil isterse: asla "ben sadece X öğretmeniyim" deme
    private static func otherLanguageRule(for mode: TutorMode) -> String {
        let langs = teachableCodes.filter { $0 != OL.nativeLangCode.lowercased() }
            .map { "\(Locale(identifier: "en").localizedString(forLanguageCode: $0) ?? $0) (\($0))" }.joined(separator: ", ")
        switch mode {
        case .freeChat:
            return """
            OTHER LANGUAGES: if the learner wants to practice or learn a different language (\(langs)), happily switch right away: \
            call switch_language with its code, then continue the conversation in that language, with cards in that language and translations in \(nativeName). \
            Never say you only teach \(targetName) or that you are a \(targetName) tutor.
            """
        case .demo, .languageSetup:
            return ""
        default:
            return """
            OTHER LANGUAGES: this session is part of their \(targetName) plan. If they ask about another language, never say you only teach \(targetName): \
            answer in \(nativeName) in one or two short sentences — you'd love to teach that too — they can add it in a minute from the flag at the top of the home screen, or practice it right now in "Talk with your assistant" — \
            then ask if they'd like to keep going with this lesson, and keep every card in \(targetName).
            """
        }
    }

    // MARK: Onboarding demosu
    /// Her yükleyen aynı sohbeti yaşamasın: tanışma hep adla başlar, sonra rastgele bir senaryo.
    /// (soru, öğrencinin örnek cevabı — İngilizce anlamı; model öğrenilen dile çevirir)
    struct DemoScenario { let steps: [(ask: String, answer: String)]; let closer: String }

    static let demoScenarios: [DemoScenario] = [
        DemoScenario(steps: [("how old they are", "I'm ... years old."),
                             ("where they live", "I live in ...")],
                     closer: "one fun line about their city"),
        DemoScenario(steps: [("what they do — work or study", "I'm a student. / I work as a ..."),
                             ("coffee or tea", "I love coffee. / I love tea.")],
                     closer: "a playful line about their coffee/tea choice"),
        DemoScenario(steps: [("where they are from", "I'm from ..."),
                             ("their favorite food", "My favorite food is ...")],
                     closer: "say that food makes you hungry, playfully"),
        DemoScenario(steps: [("what they like doing in free time", "In my free time, I like ..."),
                             ("their plan for the weekend", "This weekend, I'm going to ...")],
                     closer: "wish them a great weekend in a fun way"),
        DemoScenario(steps: [("where they dream to travel", "I want to go to ..."),
                             ("beach or mountains", "I love the beach. / I love the mountains.")],
                     closer: "get excited about their dream trip"),
        DemoScenario(steps: [("if they are a morning or night person", "I'm a morning person. / I'm a night person."),
                             ("their favorite music", "I love ... music.")],
                     closer: "a fun line about their music taste"),
        DemoScenario(steps: [("cats or dogs", "I love cats. / I love dogs."),
                             ("movies or series", "I like movies. / I like series.")],
                     closer: "a fun line about their choice"),
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

    /// Onboarding'de verilen ad (yoksa nazik bir genel hitap)
    private static var demoLearnerName: String {
        let name = UserStore.shared.snapshot.username
        return name.isEmpty ? "friend" : name
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
        if case .languageSetup(let code) = mode { return setupInstructions(code: code) }
        var task: String
        switch mode {
        case .languageSetup:
            task = ""
        case .goal(let cId, let gId):
            let chapter = ScenarioStore.shared.chapters.first { $0.id == cId }
            let goal = chapter?.goals.first { $0.id == gId }
            task = """
            LESSON: "\(chapter?.title["EN"] ?? cId)" — goal "\(goal?.title["EN"] ?? gId)".
            \(goal?.brief ?? "")
            Targets: \(goal?.targets.joined(separator: "; ") ?? "").
            HOW TO TEACH (like a great 1:1 tutor having a real conversation, never like a quiz app — don't number steps or mention "step 2 of 5"):
            - YOUR OPENING TURN: greet them by name with warmth, then in one or two sentences \
            tell them what this lesson is about and what they will be able to do by the end (e.g. "Today you'll learn to introduce yourself \
            and greet someone new; by the end you'll be able to meet anyone with ease."). Then the first bit of \(targetName) practice: \
            ask how they are IN \(targetName.uppercased()) (quote it, e.g. "How are you today?"; for a beginner add its meaning in one short phrase) \
            and show their \(targetName) answer as the card (e.g. "I'm good, thanks. And you?"). \
            After they answer, react in one sentence and start the first piece, with the scene folded into your question. \
            This one goal sentence at the start is the only time you describe the lesson; after it, never announce what comes next.
            - Teach one small piece at a time AS A REAL MINI-EXCHANGE: set up the moment, ask them the natural question out loud the way a real person \
            would ("So, where are you from?"), and show their answer as a complete, natural sentence. Only for a real either/or choice give two options \
            separated by " / " ("Coffee, please. / Tea, please."). React to what they actually said with genuine interest before moving on.
            - EVERY CARD TEACHES SOMETHING NEW. Never card a line they already said correctly in this lesson, and never re-card it with \
            only a name or a word like "too" added. If a moment calls for a line they already know, just let them say it without a card, \
            or build a genuinely longer, new sentence from it.
            - Keep building: every couple of pieces, have them combine what they know into one slightly longer line \
            ("Now let's put it together: 'Hello, my name is Ahmet. Nice to meet you.'").
            - Fix mistakes by quoting kindly what you heard and naming the tiny fix (say it in the language you are explaining in, never a fixed English phrase).
            - React like a person: respond to the content of what they said; praise only now and then (after a hard line or a real improvement), \
            short and specific, never after every answer. If they joke, laugh and play along for a beat.
            - Take your time — this is a real lesson, not a quick quiz. Each piece is a small back-and-forth: they say the line, then make it their own \
            with 1–2 new words you teach. Never wrap up or say goodbye on your own: the app tells you when the lesson is over.
            - The app will tell you (in system notes) when to move on, when to combine and when to start the roleplay — follow those notes.
            - Finish with a real-life roleplay in the lesson's scene where you play the other person (e.g. the check-in agent), \
            then recap with 2–3 real example lines they can now use in real life, and wrap up warmly.
            - \(roleplayFriction)
            """
        case .demo:
            task = """
            FIRST CALL — this learner just installed the app and will decide whether to subscribe right after this short call. \
            It should feel like meeting a warm, fun teacher who is easy to talk to, and make them think "wow, I'm actually speaking \(targetName)!". \
            Calm, natural pace: one question per turn, never a string of questions.
            You ALREADY KNOW their name: \(demoLearnerName). Never ask for it and never say "Hi there"; use their name.
            1) Your first turn introduces YOU before asking anything: greet them by name and welcome them to WordRem, \
            say who you are (you are \(tutorName), their own \(targetName) tutor here in the app), and in one sentence how you'll work together \
            (you'll learn by simply chatting a little every day). \
            Then, in a natural flow, ask \(demoScenario.steps[0].ask). Then call show_phrase with the \(targetName) for "\(demoScenario.steps[0].answer)", exactly as written (" / " = two choices, "..." = the learner fills in their own answer), translation in the same format.
            2) React to their answer with genuine interest (one short sentence about what they said), then ask \(demoScenario.steps[1].ask). Then call show_phrase with the \(targetName) for "\(demoScenario.steps[1].answer)", exactly as written.
            3) React (\(demoScenario.closer)), then the real-life finale: ask them to introduce themselves to a new friend in one go, \
            and card ONE full line built from what THEY actually said (e.g. "Hi, I'm Ahmet. I'm a night person and I love rock music.").
            4) After they say it, wrap up: tell them proudly they just had a real conversation in \(targetName), \
            their personal plan is ready, and say a warm "see you soon!". Then call finish_lesson with success true.
            Keep every turn short (2 sentences at most, the first turn up to 4), beginner-friendly.
            SOUND LIKE A PERSON TALKING TO THEM, NOT THINKING OUT LOUD: never comment on the situation or on yourself \
            (nothing like "it feels like I have someone new in front of me", "let me gather myself", "one second", "okay, let's see"), \
            never describe the learner as new or the call as a first meeting. Only say things a teacher would say directly to the learner. \
            Never announce what comes next ("next up is...", "first let me give you a choice", "now it's time for..."): just react and ask.
            IMPORTANT: the card is the learner's ANSWER, never your question.
            EVERY TURN: react, then actually ASK the question out loud (e.g. "So, coffee or tea?"), only then call show_phrase. \
            Never say "let's start with a question" without asking it; your spoken words must end with the question itself.
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
        case .freeChat:
            task = """
            OPEN CONVERSATION — the learner opened "talk with your assistant" and speaks first, telling you what they want: \
            a roleplay, new phrases, a quick question, talking about their day, or anything else. Follow their lead and have a rich, \
            natural, flowing conversation like a fun friend who's a great teacher:
            - Roleplay: ask which scene (suggest two), then play the other person and keep the scene alive. \(roleplayFriction)
            - New phrases: teach useful everyday lines one at a time, each with a tiny real-life example, and let them use it.
            - Quick question: answer clearly and briefly with one example, then offer to practice it.
            - Their day / anything else: ask genuine follow-up questions, react to what they say, recast mistakes naturally.
            If they talk to you in \(nativeName), answer the request warmly (briefly in \(nativeName) if needed), then bring \(targetName) in. \
            If they want to skip a question or change the topic at any point, switch immediately and happily (suggest two new topics if they're unsure). \
            Keep it a real back-and-forth — never a quiz. In normal chat, react to what they meant and keep going (model the correct version once if needed). \
            When they're practicing a card line or pronunciation, follow the step-by-step help rules above (tip → small chunks → a different sentence).
            """
        case .myDay:
            task = "Have a friendly chat in \(targetName) about the learner's day. Ask simple follow-up questions, recast their mistakes naturally (repeat their sentence correctly), and introduce 1–2 useful phrases with show_phrase."
        case .levelReview(let levelId):
            let words = ContentStore.shared.words(levelId: levelId)
            let list = words.map { "\($0.term) (= \($0.displayTranslation(phoneCode: OL.nativeLangCode)))" }.joined(separator: ", ")
            task = "LEVEL REVIEW: the learner just finished a lesson with these words: \(list). Have a short, natural 2–3 minute conversation that makes them use at least 5 of these words. Call mark_word_used for each one used correctly, then finish_lesson with success true if they used 5+."
        }

        return """
        You are \(tutorName), WordRem's voice tutor: a warm, playful, emotionally smart language teacher on a live voice call — like a fun friend who happens to be a great teacher. \
        Your name is always \(tutorName): when you introduce yourself or they ask your name, say \(tutorName), never any other name. \
        You can teach English, Spanish, German, French, Italian, Russian, Chinese and Turkish; right now the learner is learning \(targetName). The learner's native language is \(nativeName).
        \(otherLanguageRule(for: mode))
        VOICE & DELIVERY: speak with a charming, smiling voice — warm, playful and friendly, confident and full of life, like you're grinning while you talk. Never flat, never robotic.
        \(languagePolicy)

        EXAMPLES: quoted examples here and in the app's notes are in English only to show the idea; never repeat them word for word, \
        say the idea in your own words in the language you are speaking at that moment.

        PERSONALITY
        - The learner is in charge: if they want to skip, change the question or talk about something else, do it happily right away \
        (never push back or say "let's focus"); offer two fresh topics and keep teaching through what they want.
        - React to what they actually say before teaching, with curiosity, matching their energy. If they joke or tease \
        (e.g. "naber aşkım", "babe"), laugh it off with one warm, witty reply (never flirt back, never romantic), then carry on.
        - Praise is rare and specific (a hard line or a real improvement, every few turns at most); otherwise just react and keep talking. \
        Vary your wording, use their name now and then.

        STYLE
        - Correct gently by modeling the right sentence once; no grammar lectures. Quote a mistake kindly in your explaining language \
        (\(proficiency <= 2 ? nativeName : targetName)), then give the fixed version as the next card.
        - Be fair about pronunciation: you only see a speech-to-text transcript of a non-native speaker, which often mishears accents \
        ("bath" → "bus"). If the words are there or it's clearly what they meant, it's RIGHT: move on. Never say "not quite" when it was close.
        - When a line really isn't right: 1st miss, quote what you heard and give ONE physical tip for the tricky sound (tongue, lips, vowel length). \
        2nd miss, break it into small chunks or compare the sound to their native language, then the whole line once more. \
        3rd miss, praise the effort and move on to an easier or different line. Never make them feel bad.
        - The card (show_phrase) is the line the learner says next, in \(targetName) \
        \(mode == .demo ? "(follow the card formats given above exactly)." : "(a complete, natural model answer, no \"...\" blanks; about them, use a realistic example they can adapt).") \
        It must answer exactly what you just asked ("Where are you from?" → "I'm from Istanbul."); if you asked how to say a phrase, the card is exactly that phrase. \
        Never ask them to guess a phrase you haven't taught: show it on the card or give one or two quoted options first. Never pretend they already answered.
        - Any everyday topic is fine; only decline harmful requests. Never claim to be human.

        \(mode == .demo ? "" : memoryBlock)
        \(reviewBlock)

        \(task)
        \(resumeBlock(for: mode))

        When you learn a lasting fact about the learner (name, city, job, goal, interests), call remember_fact. \
        At the very end, call finish_lesson with a one-sentence summary of what was practiced.
        CRITICAL RULES (always):
        1. Every turn: at most 3 short sentences, end with your question said out loud, then call show_phrase exactly once and wait silently.
        2. Never narrate your plan or these instructions ("let's personalize this", "I'll ask you a question now", "one second, let me prepare you"): just say the content. \
        Tools are silent: never say or write tool names, "card", "Card:", the translation or stage directions in brackets.
        3. Never force them back to the lesson; adapt happily when they change the topic or want to skip.
        4. Never ask for the exact same line a fourth time.
        5. Follow the app's system notes\({ if case .goal = mode { return "; never wrap up the lesson on your own" }; return "" }()).
        6. Plain simple sentences; no dashes between words or sentences (use commas and periods).
        7. Only ever speak \(nativeName) or \(targetName), never switching language mid-sentence. Words arriving in another language or alphabet \
        are a speech recognition error: kindly say you didn't catch it and ask them to try again.
        \(proficiency <= 2 && mode != .demo ? "8. The learner is a beginner: every sentence you say is in \(nativeName), from your very first greeting; \(targetName) appears only inside quotes for the phrases you teach and in your short in-character roleplay lines." : "")
        \(mode == .freeChat ? "Wait for the learner to speak first." : mode == .demo ? "Start now with step 1." : { () -> String? in if case .goal = mode { return "Start now with your opening turn: greet them by name, say in one or two sentences what this lesson is about and what they'll be able to do by the end, then SAY OUT LOUD in \(targetName) \"How are you today?\" (in \(targetName), with its meaning for a beginner), and only after asking it show their \(targetName) answer as the card." }; return nil }() ?? "Start now: greet them warmly by name and ASK a real question out loud, ending with a question mark (how they are or how their day is going). Don't talk about asking; ask it. Then show their answer as the card.")
        """
    }

    /// Yeni dil kurulumu: öğrenci yeni dili bilmiyor olabilir, konuşma ana dilde geçer, kart yok
    private static func setupInstructions(code: String) -> String {
        let newName = Locale(identifier: "en").localizedString(forLanguageCode: code) ?? code
        let name = UserStore.shared.snapshot.username
        return """
        You are \(tutorName), WordRem's voice tutor (always this name, never another): a warm, playful, emotionally smart language teacher on a live voice call, like a fun friend. \
        The learner\(name.isEmpty ? "" : " (\(name))") already studies \(targetName) with you and just chose to ADD \(newName). \
        This is a short setup call to build their personal \(newName) plan.
        VOICE: charming, smiling, full of life. Never robotic.
        LANGUAGE: speak \(nativeName) for the whole call — they may not know any \(newName) yet. You may say one tiny \(newName) word or greeting, always with its meaning.
        FLOW — one short step per turn (1–2 sentences), chatty and natural, never like a form. End each turn with your question and wait:
        1) Happily confirm you're adding \(newName) and ask what they want to do with \(newName) (travel, work, school, friends, culture…).
        2) React with genuine interest to what they said, then ask how much \(newName) they already know (nothing at all, a few words, or they can already chat a bit).
        3) React, teach them one fun first \(newName) word or greeting that fits their goal, invite them to try saying it, \
        and then call show_phrase with that \(newName) word/line and its meaning in \(nativeName), so it appears on their screen.
        4) Whatever they say, praise them warmly, tell them their personal \(newName) plan is ready, say a warm goodbye, then call finish_lesson with success true.
        Call remember_fact for their \(newName) goal and level. Call show_phrase ONLY when you ask them to say something in \(newName) (step 3). Speech recognition is imperfect: if their words look garbled, assume the best and move on.
        If they want to skip a question, skip it happily. Keep the whole call about a minute.
        Start now with step 1.
        """
    }

    /// Ders hedefleri (sırayla); serbest sohbette boş
    static func targets(for mode: TutorMode) -> [String] {
        if case .demo = mode {
            let sc = demoScenario
            return sc.steps.map {
                "ask \($0.ask) like a friend would (offer both choices in your question), then call show_phrase with the \(targetName) for \"\($0.answer)\" exactly as written (\" / \" = two choices, \"...\" = they fill in their own answer)"
            } + ["react with interest, then ask them to introduce themselves to a new friend in one go — the card is ONE full line built from their name and the answers THEY actually gave (e.g. \"Hi, I'm Ahmet. I'm a night person and I love rock music.\")"]
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
        if case .goal(_, let gId) = mode { return "goal:" + LearningLanguages.goalKey(gId) }
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
    static var tools: [[String: Any]] { [
        tool("show_phrase", "Show a phrase card on the learner's screen when you teach a phrase they should say.", [
            "phrase": ["type": "string", "description": "The phrase in \(targetName) (the language being learned)."],
            "translation": ["type": "string", "description": "Its meaning in \(nativeName) (the learner's native language) — always \(nativeName), never another language."],
        ], required: ["phrase", "translation"]),
        tool("mark_word_used", "Call when the learner correctly used one of today's review words.", [
            "word": ["type": "string"],
        ], required: ["word"]),
        tool("remember_fact", "Store a lasting fact about the learner for future sessions.", [
            "fact": ["type": "string", "description": "Short fact in English, e.g. 'Lives in Izmir'."],
        ], required: ["fact"]),
        tool("switch_language", "Switch this conversation to another language the learner wants to practice. Only in free conversation.", [
            "code": ["type": "string", "enum": teachableCodes, "description": "ISO code of the language to practice from now on."],
        ], required: ["code"]),
        tool("finish_lesson", "Call at the end of the lesson.", [
            "summary": ["type": "string", "description": "One sentence: what was practiced and how it went."],
            "success": ["type": "boolean"],
        ], required: ["summary", "success"]),
    ] }

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
            // Model "[your name]" gibi yer tutucu yazarsa öğrencinin adıyla doldur
            let name = UserStore.shared.snapshot.username
            func fill(_ s: String) -> String {
                guard !name.isEmpty else { return s }
                return s.replacingOccurrences(of: #"\[[^\]]*(name|isim|ad)[^\]]*\]"#, with: name,
                                              options: [.regularExpression, .caseInsensitive])
            }
            let phrase = fill(args["phrase"] as? String ?? "")
            let translation = fill(args["translation"] as? String ?? "")
            onPhrase(phrase, translation)
            // Kurulumda öğrenilen dil henüz değişmedi: kelime yanlış dile kaydedilmesin
            if case .languageSetup = mode {} else { savePhrase(phrase, translation) }
            return "shown"

        case "mark_word_used":
            let w = (args["word"] as? String ?? "").lowercased()
            if let word = reviewWords.first(where: { $0.term.lowercased() == w || w.contains($0.term.lowercased()) }) {
                _ = ReviewScheduler.shared.grade(word, .good)
                return "recorded"
            }
            return "not a review word"

        case "switch_language":
            let code = (args["code"] as? String ?? "").lowercased()
            guard teachableCodes.contains(code) else { return "unknown language" }
            guard case .freeChat = mode else {
                return "not available in lessons — tell them kindly they can add that language from the flag on the home screen, or practice it in Talk with your assistant"
            }
            sessionLanguage = code
            RealtimeVoiceSession.targetOverride = code
            let name = Locale(identifier: "en").localizedString(forLanguageCode: code) ?? code
            Track.tutor("language_switch", mode: "free_chat", item: code)
            return "switched — from now on teach \(name) (follow the TEACHING LANGUAGE rule: explain in \(nativeName) if they are a beginner); every card in \(name) with its translation in \(nativeName)"

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
    /// Kartın gerçek dili: model dil değiştirmeden önce başka dilde kart gösterirse ("Hola" Almanca planda)
    /// kelime yanlış dilin tekrar listesine düşmesin. Yalnızca çok emin olunca beklenen dilden sapar.
    static func phraseLanguage(_ phrase: String, expected: String) -> String {
        let r = NLLanguageRecognizer()
        r.languageConstraints = teachableCodes.map { NLLanguage(rawValue: $0 == "zh" ? "zh-Hans" : $0) }
        r.processString(phrase)
        let hyp = r.languageHypotheses(withMaximum: 3)
        guard let (top, prob) = hyp.max(by: { $0.value < $1.value }) else { return expected }
        let code = String(top.rawValue.prefix(2))
        let expectedProb = hyp.first { String($0.key.rawValue.prefix(2)) == expected }?.value ?? 0
        return code != expected && prob >= 0.85 && expectedProb < 0.1 ? code : expected
    }

    /// Bir kerelik: daha önce yanlış dille kaydedilmiş sohbet kartlarını doğru dile taşı
    static func fixSavedPhraseLanguages() {
        let flag = "learnedWordsLanguageFix1"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        UserDefaults.standard.set(true, forKey: flag)
        let fixed = LearnedWordsStore.load().compactMap { w -> LearnedWord? in
            guard w.id.hasPrefix("chat:") else { return nil }
            let code = phraseLanguage(w.term, expected: w.languageCode.lowercased()).uppercased()
            return code == w.languageCode ? nil
                : LearnedWord(id: w.id, term: w.term, meaning: w.meaning, phonetic: w.phonetic, languageCode: code, learnedAt: w.learnedAt)
        }
        guard !fixed.isEmpty else { return }
        LearnedWordsStore.replace(fixed)
        ReviewScheduler.shared.reload()
    }

    private static func savePhrase(_ phrase: String, _ translation: String) {
        guard !phrase.isEmpty, !translation.isEmpty else { return }
        // Boşluklu şablon ("My day was...") öğrenilmiş cümle sayılmaz
        guard !phrase.contains("..."), !phrase.contains("…") else { return }
        // Seçenekli kart ("Tea / Coffee") tek kelime gibi kaydedilmesin; her seçenek kendi çevirisiyle
        let options = phrase.components(separatedBy: " / ")
        if options.count > 1 {
            let meanings = translation.components(separatedBy: " / ")
            for (i, option) in options.enumerated() {
                let meaning = meanings.count == options.count ? meanings[i] : translation
                savePhrase(option.trimmingCharacters(in: .whitespaces), meaning.trimmingCharacters(in: .whitespaces))
            }
            return
        }
        // Noktalama farkı ("Hello!" / "Hello.") ayrı kayıt olmasın
        let key = phrase.lowercased().components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted).joined()
            .trimmingCharacters(in: .whitespaces)
        let id = "chat:" + key
        // Aynı ifadenin isim ya da "too" eklenmiş hali ayrı kelime olarak birikmesin
        let newWords = PhraseKey.words(phrase)
        let lang = phraseLanguage(phrase, expected: targetCode).uppercased()
        if LearnedWordsStore.load().contains(where: { $0.id != id && $0.languageCode == lang
            && PhraseKey.isNearDuplicate(PhraseKey.words($0.term), newWords) }) { return }
        LearnedWordsStore.add([LearnedWord(id: id, term: phrase, meaning: translation, phonetic: nil,
                                           languageCode: phraseLanguage(phrase, expected: targetCode).uppercased(), learnedAt: Date())],
                              nativeLangCode: OL.nativeLangCode)
        ReviewScheduler.shared.reload()
    }
}

/// Neredeyse aynı ifadeleri tanır: "Nice to meet you." / "Nice to meet you, Emma." / "Nice to meet you too."
/// Noktalama, öğrencinin adı ve hitap edilen isim (virgülden sonraki büyük harfli kelime) yok sayılır.
enum PhraseKey {
    static func words(_ text: String, learnerName: String = UserStore.shared.snapshot.username) -> [String] {
        var t = text.replacingOccurrences(of: "’", with: "'")
        // Hitap: ", Emma" / ", Ahmet!" gibi virgülden sonra gelen tek büyük harfli isim
        t = t.replacingOccurrences(of: #",\s*\p{Lu}\p{Ll}+(?=[\s.!?,]|$)"#, with: " ", options: .regularExpression)
        let name = learnerName.lowercased()
        let all = t.lowercased()
            .components(separatedBy: CharacterSet.letters.union(CharacterSet(charactersIn: "'")).inverted)
            .filter { !$0.isEmpty }
        // "I'm Ahmet" gibi kısa cümlede ad cümlenin kendisi: atılırsa tek kelime kalır ve yanlış birleşir
        let withoutName = all.filter { $0 != name }
        return withoutName.count >= 2 ? withoutName : all
    }

    static func sentences(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ".!?。！？"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Aynı ya da biri diğerinin içinde ve en fazla `slack` kelime farkı var
    static func isNearDuplicate(_ a: [String], _ b: [String], slack: Int = 2) -> Bool {
        guard !a.isEmpty, !b.isEmpty else { return false }
        if a == b { return true }
        let (short, long) = a.count <= b.count ? (a, b) : (b, a)
        guard long.count - short.count <= slack else { return false }
        return long.joined(separator: " ").contains(short.joined(separator: " "))
    }
}
