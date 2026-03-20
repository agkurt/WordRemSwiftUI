//
//  AIQuizTopic.swift
//  WordRemSwiftUI
//
//  Grammar topics offered in the AI-generated quiz feature.
//

import SwiftUI

enum AIQuizTopicCategory: String, CaseIterable {
    case tenses      = "Tenses"
    case structure   = "Sentence Structure"
    case vocabulary  = "Vocabulary"
}

enum AIQuizTopic: String, CaseIterable, Identifiable {
    // ── Tenses ──────────────────────────────────────
    case simplePresent      = "Simple Present Tense"
    case presentContinuous  = "Present Continuous Tense"
    case presentPerfect     = "Present Perfect Tense"
    case simplePast         = "Simple Past Tense"
    case pastContinuous     = "Past Continuous Tense"
    case pastPerfect        = "Past Perfect Tense"
    case simpleFuture       = "Simple Future Tense (will)"
    case goingToFuture      = "Future with Going To"
    case futurePerfect      = "Future Perfect Tense"

    // ── Sentence Structure ──────────────────────────
    case conditionals       = "Conditionals (If Clauses)"
    case passiveVoice       = "Passive Voice"
    case modals             = "Modal Verbs (can, must, should)"
    case comparatives       = "Comparatives & Superlatives"
    case articles           = "Articles (a, an, the)"
    case prepositions       = "Prepositions"

    // ── Vocabulary ──────────────────────────────────
    case dailyVocab         = "Daily Life Vocabulary"
    case businessVocab      = "Business English"
    case phrasal            = "Phrasal Verbs"
    case idioms             = "Common Idioms"

    var id: String { rawValue }

    var category: AIQuizTopicCategory {
        switch self {
        case .simplePresent, .presentContinuous, .presentPerfect,
             .simplePast, .pastContinuous, .pastPerfect,
             .simpleFuture, .goingToFuture, .futurePerfect:
            return .tenses
        case .conditionals, .passiveVoice, .modals,
             .comparatives, .articles, .prepositions:
            return .structure
        case .dailyVocab, .businessVocab, .phrasal, .idioms:
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
        case .futurePerfect:     return "arrow.forward.circle.fill"
        case .conditionals:      return "questionmark.diamond"
        case .passiveVoice:      return "arrow.left.arrow.right"
        case .modals:            return "slider.horizontal.3"
        case .comparatives:      return "chart.bar"
        case .articles:          return "textformat.abc"
        case .prepositions:      return "arrow.up.left.and.arrow.down.right"
        case .dailyVocab:        return "house"
        case .businessVocab:     return "briefcase"
        case .phrasal:           return "link"
        case .idioms:            return "quote.bubble"
        }
    }

    /// Description sent to GPT as the quiz topic
    var promptDescription: String {
        switch self {
        case .simplePresent:
            return "Simple Present Tense — habitual actions, facts, third-person -s endings"
        case .presentContinuous:
            return "Present Continuous Tense — actions happening now, be + verb-ing"
        case .presentPerfect:
            return "Present Perfect Tense — have/has + past participle, life experience, recent past"
        case .simplePast:
            return "Simple Past Tense — completed actions, irregular verbs, did questions"
        case .pastContinuous:
            return "Past Continuous Tense — ongoing past actions, was/were + verb-ing"
        case .pastPerfect:
            return "Past Perfect Tense — had + past participle, earlier past event"
        case .simpleFuture:
            return "Simple Future Tense with will — predictions, decisions, promises"
        case .goingToFuture:
            return "Future with Going To — planned intentions, evidence-based predictions"
        case .futurePerfect:
            return "Future Perfect Tense — will have + past participle, completed future actions"
        case .conditionals:
            return "Conditional sentences — zero, first, second, and third conditionals (if clauses)"
        case .passiveVoice:
            return "Passive Voice — be + past participle, active-to-passive transformations"
        case .modals:
            return "Modal Verbs — can, could, may, might, must, should, would — meaning and usage"
        case .comparatives:
            return "Comparatives and Superlatives — adjective comparison (bigger, the biggest)"
        case .articles:
            return "Articles — definite (the) and indefinite (a/an) usage rules"
        case .prepositions:
            return "Prepositions of time, place, and direction — in, on, at, by, with, etc."
        case .dailyVocab:
            return "Daily Life Vocabulary — common words for home, food, shopping, transport"
        case .businessVocab:
            return "Business English Vocabulary — meetings, emails, negotiations, office language"
        case .phrasal:
            return "Phrasal Verbs — common verb + particle combinations and their meanings"
        case .idioms:
            return "Common English Idioms — frequently used idiomatic expressions"
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
