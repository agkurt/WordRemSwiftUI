//
//  AIQuizTopic.swift
//  WordRemSwiftUI
//
//  Grammar topics offered in the AI-generated quiz feature.
//  promptDescription(for:) returns language-specific descriptions.
//

import SwiftUI

enum AIQuizTopicCategory: String, CaseIterable {
    case tenses      = "Tenses"
    case structure   = "Sentence Structure"
    case vocabulary  = "Vocabulary"
}

enum AIQuizTopic: String, CaseIterable, Identifiable {
    // ── Tenses ──────────────────────────────────────
    case simplePresent      = "Simple Present"
    case presentContinuous  = "Present Continuous"
    case presentPerfect     = "Present Perfect"
    case simplePast         = "Simple Past"
    case pastContinuous     = "Past Continuous"
    case pastPerfect        = "Past Perfect"
    case simpleFuture       = "Simple Future (will)"
    case goingToFuture      = "Going To Future"

    // ── Sentence Structure ──────────────────────────
    case conditionals       = "Conditionals"
    case passiveVoice       = "Passive Voice"
    case modals             = "Modal Verbs"
    case comparatives       = "Comparatives & Superlatives"
    case articles           = "Articles & Determiners"
    case prepositions       = "Prepositions"
    case negation           = "Negation"
    case questions          = "Question Formation"

    // ── Vocabulary ──────────────────────────────────
    case dailyVocab         = "Daily Life Vocabulary"
    case numbersTime        = "Numbers & Time"
    case colorsShapes       = "Colors & Descriptions"
    case foodDrink          = "Food & Drink"
    case travelTransport    = "Travel & Transport"

    var id: String { rawValue }

    var category: AIQuizTopicCategory {
        switch self {
        case .simplePresent, .presentContinuous, .presentPerfect,
             .simplePast, .pastContinuous, .pastPerfect,
             .simpleFuture, .goingToFuture:
            return .tenses
        case .conditionals, .passiveVoice, .modals,
             .comparatives, .articles, .prepositions,
             .negation, .questions:
            return .structure
        case .dailyVocab, .numbersTime, .colorsShapes,
             .foodDrink, .travelTransport:
            return .vocabulary
        }
    }

    var icon: String {
        switch self {
        case .simplePresent:     return "clock"
        case .presentContinuous: return "clock.arrow.2.circlepath"
        case .presentPerfect:    return "checkmark.circle"
        case .simplePast:        return "arrow.counterclockwise"
        case .pastContinuous:    return "arrow.counterclockwise.circle"
        case .pastPerfect:       return "arrow.uturn.backward.circle"
        case .simpleFuture:      return "arrow.forward"
        case .goingToFuture:     return "map"
        case .conditionals:      return "questionmark.diamond"
        case .passiveVoice:      return "arrow.left.arrow.right"
        case .modals:            return "slider.horizontal.3"
        case .comparatives:      return "chart.bar"
        case .articles:          return "textformat.abc"
        case .prepositions:      return "arrow.up.left.and.arrow.down.right"
        case .negation:          return "xmark.circle"
        case .questions:         return "questionmark.circle"
        case .dailyVocab:        return "house"
        case .numbersTime:       return "number"
        case .colorsShapes:      return "paintpalette"
        case .foodDrink:         return "fork.knife"
        case .travelTransport:   return "airplane"
        }
    }

    // MARK: - Language-aware prompt descriptions
    func promptDescription(for langCode: String) -> String {
        switch langCode.lowercased() {
        case "de": return germanPrompt
        case "fr": return frenchPrompt
        case "es": return spanishPrompt
        case "it": return italianPrompt
        case "ru": return russianPrompt
        default:   return englishPrompt
        }
    }

    /// Legacy property for backward compat (defaults to English)
    var promptDescription: String { englishPrompt }

    // MARK: - English
    private var englishPrompt: String {
        switch self {
        case .simplePresent:
            return "Simple Present Tense — habitual actions, facts, third-person -s endings (he/she/it)"
        case .presentContinuous:
            return "Present Continuous — actions happening now, be + verb-ing, NOT stative verbs"
        case .presentPerfect:
            return "Present Perfect — have/has + past participle, life experience, recent past with just/already/yet"
        case .simplePast:
            return "Simple Past — completed actions, regular (-ed) and irregular verbs, did questions & negation"
        case .pastContinuous:
            return "Past Continuous — ongoing past actions, was/were + verb-ing, interrupted actions"
        case .pastPerfect:
            return "Past Perfect — had + past participle, action before another past action"
        case .simpleFuture:
            return "Future with will — predictions, spontaneous decisions, promises, offers"
        case .goingToFuture:
            return "Going To Future — planned intentions, evidence-based predictions, am/is/are going to"
        case .conditionals:
            return "Conditionals — zero (general truth), first (real future), second (unreal present), third (unreal past)"
        case .passiveVoice:
            return "Passive Voice — be + past participle, active-to-passive, by-agent"
        case .modals:
            return "Modal Verbs — can/could, may/might, must/have to, should, would — meaning and usage"
        case .comparatives:
            return "Comparatives and Superlatives — adjective forms (bigger, the biggest, more beautiful)"
        case .articles:
            return "Articles — definite (the), indefinite (a/an), zero article — rules and exceptions"
        case .prepositions:
            return "Prepositions — time (in/on/at), place (in/on/at/under), direction (to/from/into)"
        case .negation:
            return "Negation — do/does/did + not, contractions (don't/doesn't/didn't/isn't/aren't)"
        case .questions:
            return "Question Formation — yes/no questions with auxiliaries, wh-questions (what/where/when/why/how)"
        case .dailyVocab:
            return "Daily Life Vocabulary — home, family, shopping, body, weather, daily routines"
        case .numbersTime:
            return "Numbers, dates, time expressions — ordinals, telling time, days/months/years"
        case .colorsShapes:
            return "Colors, shapes, and physical descriptions — adjective usage and agreement"
        case .foodDrink:
            return "Food & Drink vocabulary — ordering, cooking, ingredients, restaurants"
        case .travelTransport:
            return "Travel & Transport — directions, transport types, booking, travel vocabulary"
        }
    }

    // MARK: - German
    private var germanPrompt: String {
        switch self {
        case .simplePresent:
            return "Präsens (German Simple Present) — verb conjugation for all persons (ich, du, er/sie/es, wir, ihr, sie/Sie), irregular stems (fahren, laufen)"
        case .presentContinuous:
            return "German has no continuous tense — focus on Präsens for ongoing actions + adverbs like 'gerade', 'jetzt', 'im Moment'"
        case .presentPerfect:
            return "Perfekt (German Present Perfect) — haben/sein + Partizip II, when to use sein vs haben, irregular Partizip II forms"
        case .simplePast:
            return "Präteritum (German Simple Past) — strong/weak verb conjugation, common irregular verbs (war, hatte, ging, kam)"
        case .pastContinuous:
            return "German Präteritum for ongoing past — als vs wenn, simultaneous actions with während"
        case .pastPerfect:
            return "Plusquamperfekt (German Past Perfect) — hatte/war + Partizip II, sequence of past events"
        case .simpleFuture:
            return "Futur I (German Future) — werden + Infinitiv, predictions and intentions"
        case .goingToFuture:
            return "German future with Präsens + time adverb — 'Ich fahre morgen nach Berlin' — common way to express planned future"
        case .conditionals:
            return "Konjunktiv II (German Conditionals) — würde + Infinitiv, wäre, hätte — unreal/hypothetical situations"
        case .passiveVoice:
            return "Passiv (German Passive Voice) — werden + Partizip II (Vorgangspassiv) vs. sein + Partizip II (Zustandspassiv)"
        case .modals:
            return "Modalverben (German Modals) — können, müssen, dürfen, sollen, wollen, mögen/möchten — conjugation and meaning"
        case .comparatives:
            return "Komparativ & Superlativ (German Comparison) — adjective endings in all three genders, irregular forms (gut → besser → am besten)"
        case .articles:
            return "Deutsche Artikel — der/die/das (definite), ein/eine/ein (indefinite) — nominative/accusative/dative cases and gender rules"
        case .prepositions:
            return "Deutsche Präpositionen — Akkusativ (durch, für, gegen, ohne, um), Dativ (aus, bei, mit, nach, seit, von, zu), Wechselpräpositionen"
        case .negation:
            return "Negation auf Deutsch — nicht vs. kein/keine, position of 'nicht' in sentence, negated articles"
        case .questions:
            return "Fragesätze auf Deutsch — W-Fragen (wer, was, wo, wann, warum, wie), Ja/Nein-Fragen with verb-first word order"
        case .dailyVocab:
            return "Alltäglicher Wortschatz — Zuhause, Familie, Einkaufen, Körper, Wetter, Tagesablauf"
        case .numbersTime:
            return "Zahlen & Uhrzeit auf Deutsch — cardinal/ordinal numbers, telling time (Es ist Viertel nach drei), dates"
        case .colorsShapes:
            return "Farben & Formen auf Deutsch — color/shape vocabulary with adjective agreement (der rote Ball)"
        case .foodDrink:
            return "Essen & Trinken auf Deutsch — Mahlzeiten, Zutaten, Bestellen im Restaurant, food vocabulary"
        case .travelTransport:
            return "Reisen & Verkehr auf Deutsch — directions, transport (Zug, Bus, Flugzeug), booking, travel phrases"
        }
    }

    // MARK: - French
    private var frenchPrompt: String {
        switch self {
        case .simplePresent:
            return "Présent de l'indicatif (French Simple Present) — conjugation of -er/-ir/-re verbs for all persons, irregular verbs (être, avoir, aller, faire)"
        case .presentContinuous:
            return "French ongoing actions with Présent — 'être en train de + infinitif' for actions in progress, time adverbs (maintenant, actuellement)"
        case .presentPerfect:
            return "Passé composé (French Perfect) — avoir/être + participe passé, agreement rules with être verbs and preceding direct objects"
        case .simplePast:
            return "Passé composé vs Imparfait — completed actions (passé composé) vs background/habitual past (imparfait)"
        case .pastContinuous:
            return "Imparfait (French Imperfect) — ongoing/habitual past actions, was doing, used to — conjugation and usage"
        case .pastPerfect:
            return "Plus-que-parfait (French Pluperfect) — avait/était + participe passé, action before another past action"
        case .simpleFuture:
            return "Futur simple (French Future) — verb + -ai/-as/-a/-ons/-ez/-ont endings, irregular stems (aur-, ser-, ir-)"
        case .goingToFuture:
            return "Futur proche (French Near Future) — aller + infinitif — planned/imminent future actions"
        case .conditionals:
            return "Conditionnel présent (French Conditional) — polite requests, hypothetical situations, si + imparfait + conditionnel"
        case .passiveVoice:
            return "Passif (French Passive) — être + participe passé with agent (par), tense agreement in passive constructions"
        case .modals:
            return "Verbes modaux en français — pouvoir (can), devoir (must), vouloir (want), savoir (know how) — conjugation and nuances"
        case .comparatives:
            return "Comparatifs et superlatifs — plus/moins/aussi + adjectif + que, le plus/le moins, irregular (bon → meilleur, bien → mieux)"
        case .articles:
            return "Les articles français — définis (le/la/les), indéfinis (un/une/des), partitifs (du/de la/des) — rules and contractions (au, du)"
        case .prepositions:
            return "Les prépositions françaises — à/de/en/dans/sur/sous/pour/avec — location, time, and direction uses"
        case .negation:
            return "La négation en français — ne...pas, ne...jamais, ne...rien, ne...personne, ne...plus — placement around verb"
        case .questions:
            return "Les questions en français — inversion, est-ce que, intonation — question words (qui, que/quoi, où, quand, pourquoi, comment, combien)"
        case .dailyVocab:
            return "Vocabulaire quotidien français — maison, famille, courses, corps, météo, routine journalière"
        case .numbersTime:
            return "Les chiffres et l'heure en français — cardinal/ordinal numbers, telling time (Il est trois heures et demie), dates"
        case .colorsShapes:
            return "Les couleurs et les formes en français — color/shape vocabulary with gender agreement (une robe rouge)"
        case .foodDrink:
            return "La nourriture et les boissons en français — repas, ingrédients, commander au restaurant"
        case .travelTransport:
            return "Les voyages et transports en français — directions, moyens de transport, réservations, phrases de voyage"
        }
    }

    // MARK: - Spanish
    private var spanishPrompt: String {
        switch self {
        case .simplePresent:
            return "Presente de indicativo (Spanish Simple Present) — -ar/-er/-ir verb conjugation for all persons, irregular stem-changing verbs (poder, querer, tener)"
        case .presentContinuous:
            return "Presente continuo (Spanish) — estar + gerundio (-ando/-iendo), difference from English continuous usage"
        case .presentPerfect:
            return "Pretérito perfecto compuesto — haber + participio, recent past with ya/todavía/alguna vez, difference from pretérito indefinido"
        case .simplePast:
            return "Pretérito indefinido (Spanish Simple Past) — regular and irregular verbs (fui, tuve, hice, vine), completed past actions"
        case .pastContinuous:
            return "Pretérito imperfecto (Spanish Imperfect) — habitual/ongoing past (era, tenía, iba) vs indefinido for completed actions"
        case .pastPerfect:
            return "Pretérito pluscuamperfecto — había + participio, action prior to another past action"
        case .simpleFuture:
            return "Futuro simple (Spanish Future) — infinitivo + -é/-ás/-á/-emos/-éis/-án endings, irregular stems (tendr-, podr-, vendr-)"
        case .goingToFuture:
            return "Futuro próximo — ir a + infinitivo, planned/imminent future actions"
        case .conditionals:
            return "Condicional simple (Spanish Conditional) — would + action, hypothetical situations, si + imperfecto subjuntivo + condicional"
        case .passiveVoice:
            return "Voz pasiva (Spanish Passive) — ser + participio + por, also reflexive passive (se + verb)"
        case .modals:
            return "Verbos modales en español — poder (can/be able), deber (should/must), querer (want), tener que (have to) — usage and conjugation"
        case .comparatives:
            return "Comparativos y superlativos — más/menos + adjetivo + que, tan + adjetivo + como, el más/el menos, irregular (bueno → mejor)"
        case .articles:
            return "Los artículos en español — definidos (el/la/los/las), indefinidos (un/una/unos/unas) — gender/number agreement and special cases"
        case .prepositions:
            return "Las preposiciones en español — a/de/en/con/por/para/sin/sobre/entre — key differences between por vs para"
        case .negation:
            return "La negación en español — no + verbo, double negation (no...nada, no...nadie, no...nunca) — Spanish requires double negative"
        case .questions:
            return "Las preguntas en español — question words (qué, quién, dónde, cuándo, por qué, cómo, cuánto) — inverted question marks"
        case .dailyVocab:
            return "Vocabulario cotidiano en español — casa, familia, compras, cuerpo, tiempo/clima, rutina diaria"
        case .numbersTime:
            return "Los números y la hora en español — cardinal/ordinal numbers, telling time (Son las tres y media), dates and calendar"
        case .colorsShapes:
            return "Los colores y las formas en español — vocabulary with gender agreement (la camisa roja, el coche azul)"
        case .foodDrink:
            return "La comida y las bebidas en español — comidas del día, ingredientes, pedir en un restaurante"
        case .travelTransport:
            return "Los viajes y el transporte en español — directions, medios de transporte, reservas, frases de viaje"
        }
    }

    // MARK: - Italian
    private var italianPrompt: String {
        switch self {
        case .simplePresent:
            return "Presente indicativo (Italian Simple Present) — -are/-ere/-ire verb conjugation, irregular verbs (essere, avere, andare, fare)"
        case .presentContinuous:
            return "Presente progressivo (Italian) — stare + gerundio (-ando/-endo), actions happening right now"
        case .presentPerfect:
            return "Passato prossimo (Italian Perfect) — avere/essere + participio passato, agreement with essere verbs"
        case .simplePast:
            return "Passato remoto (Italian Simple Past) — for completed past actions, irregular forms (fui, ebbi, feci), regional usage vs passato prossimo"
        case .pastContinuous:
            return "Imperfetto (Italian Imperfect) — habitual/ongoing past, descriptions in the past, stavo + gerundio for past continuous"
        case .pastPerfect:
            return "Trapassato prossimo (Italian Pluperfect) — avevo/ero + participio passato, prior past action"
        case .simpleFuture:
            return "Futuro semplice (Italian Future) — -erò/-erai/-erà/-eremo/-erete/-eranno endings, irregular stems"
        case .goingToFuture:
            return "Futuro immediato in italiano — stare per + infinito, andare a + infinito, presente + time expression for near future"
        case .conditionals:
            return "Condizionale presente (Italian Conditional) — -ei/-esti/-ebbe/-emmo/-este/-ebbero endings, hypothetical and polite requests"
        case .passiveVoice:
            return "Forma passiva (Italian Passive) — essere + participio passato + da, also venire + participio for dynamic passive"
        case .modals:
            return "Verbi modali in italiano — potere (can), dovere (must), volere (want), sapere (know how) — conjugation and usage"
        case .comparatives:
            return "Comparativi e superlativi — più/meno + aggettivo + di/che, il più/il meno, irregular (buono → migliore → il migliore)"
        case .articles:
            return "Gli articoli italiani — determinativi (il/lo/la/i/gli/le), indeterminativi (un/uno/una) — rules before consonants/vowels/s+consonant/z"
        case .prepositions:
            return "Le preposizioni italiane — di/a/da/in/con/su/per/tra/fra — articulated prepositions (del, al, dal, nel, sul)"
        case .negation:
            return "La negazione in italiano — non + verbo, double negation (non...mai, non...niente, non...nessuno)"
        case .questions:
            return "Le domande in italiano — question words (chi, cosa/che, dove, quando, perché, come, quanto) — intonation-based questions"
        case .dailyVocab:
            return "Vocabolario quotidiano italiano — casa, famiglia, negozi, corpo, meteo, routine giornaliera"
        case .numbersTime:
            return "I numeri e l'ora in italiano — cardinal/ordinal numbers, telling time (Sono le tre e mezza), dates"
        case .colorsShapes:
            return "I colori e le forme in italiano — vocabulary with gender/number agreement (la macchina rossa, i fiori rossi)"
        case .foodDrink:
            return "Cibo e bevande in italiano — pasti, ingredienti, ordinare al ristorante, cucina italiana"
        case .travelTransport:
            return "Viaggi e trasporti in italiano — directions, mezzi di trasporto, prenotazioni, frasi di viaggio"
        }
    }

    // MARK: - Russian
    private var russianPrompt: String {
        switch self {
        case .simplePresent:
            return "Russian Present Tense — first/second conjugation verbs, all persons (я/ты/он/мы/вы/они), irregular verbs (быть, идти, жить)"
        case .presentContinuous:
            return "Russian has no continuous tense — focus on present tense with imperfective verbs + adverbs (сейчас, в данный момент)"
        case .presentPerfect:
            return "Russian Past Tense (perfective aspect) — past tense of perfective verbs for completed actions, gender agreement"
        case .simplePast:
            return "Russian Past Tense — verb + gender suffix (-л/-ла/-ло/-ли), imperfective vs perfective aspect for past actions"
        case .pastContinuous:
            return "Russian Past Imperfective — imperfective past for repeated/ongoing past actions, difference from perfective past"
        case .pastPerfect:
            return "Russian aspect in the past — perfective past for completed actions in sequence, past active participles"
        case .simpleFuture:
            return "Russian Future Tense — буду + imperfective infinitive (compound future) vs perfective present form for simple future"
        case .goingToFuture:
            return "Russian future intentions — собираться + infinitive, хотеть + infinitive, present tense with future time adverbs"
        case .conditionals:
            return "Russian Conditional — бы + past tense, если бы + past + бы conditional, subjunctive mood"
        case .passiveVoice:
            return "Russian Passive — short-form participles (-н/-т), reflexive passive with -ся, instrumental agent"
        case .modals:
            return "Russian Modal Words — мочь/смочь (can), должен (must/should), нужно/надо (need to), можно/нельзя (allowed/not allowed)"
        case .comparatives:
            return "Russian Comparatives and Superlatives — synthetic comparative (-ее/-е/-ше), analytic (более/менее), superlative (самый)"
        case .articles:
            return "Russian has no articles — focus on Russian cases: Nominative, Accusative, Genitive, Dative, Instrumental, Prepositional"
        case .prepositions:
            return "Russian Prepositions and Cases — в/на + Prepositional (location) vs Accusative (direction), из/от/с + Genitive, с/без + Genitive"
        case .negation:
            return "Russian Negation — не + verb, double negation (никто не, ничего не, никогда не), нет + Genitive"
        case .questions:
            return "Russian Questions — question words (кто, что, где, куда, откуда, когда, почему, как, сколько), intonation for yes/no questions, ли particle"
        case .dailyVocab:
            return "Russian daily vocabulary — дом, семья, магазин, тело, погода, распорядок дня"
        case .numbersTime:
            return "Russian Numbers and Time — cardinal numbers with case agreement, telling time (в три часа, в половине четвёртого), dates"
        case .colorsShapes:
            return "Russian Colors and Shapes — color/shape vocabulary with full adjective declension agreement (красная машина, красный дом)"
        case .foodDrink:
            return "Russian Food and Drink — еда, напитки, заказ в ресторане, cooking vocabulary"
        case .travelTransport:
            return "Russian Travel and Transport — directions, транспорт, покупка билетов, travel phrases"
        }
    }

    var gradientColors: [Color] {
        switch category {
        case .tenses:
            return [Color(hex: "#f97316"), Color(hex: "#ec4899")]
        case .structure:
            return [Color(hex: "#6366f1"), Color(hex: "#8b5cf6")]
        case .vocabulary:
            return [Color(hex: "#10b981"), Color(hex: "#3b82f6")]
        }
    }
}
