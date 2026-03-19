//
//  SupabaseModels.swift
//  WordRemSwiftUI
//
//  Codable structs that mirror the PostgreSQL schema.
//  These are ONLY used for the new Path/Gamification module.
//  Existing Firebase-based Card/WordInfo models are preserved unchanged.
//

import Foundation

// MARK: - Language
struct SBLanguage: Codable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let nativeName: String?
    let flagEmoji: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, code, name
        case nativeName = "native_name"
        case flagEmoji  = "flag_emoji"
        case isActive   = "is_active"
    }
}

// MARK: - Course
struct SBCourse: Codable, Identifiable {
    let id: UUID
    let nativeLangId: Int
    let targetLangId: Int
    let title: String
    let description: String?
    let totalXp: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case nativeLangId = "native_lang_id"
        case targetLangId = "target_lang_id"
        case totalXp      = "total_xp"
        case isActive     = "is_active"
    }
}

// MARK: - Course with embedded languages
struct SBCourseDetail: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let totalXp: Int
    let nativeLanguage: SBLanguage?
    let targetLanguage: SBLanguage?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case totalXp        = "total_xp"
        case nativeLanguage = "native_language"
        case targetLanguage = "target_language"
    }
}

// MARK: - Level
struct SBLevel: Codable, Identifiable {
    let id: UUID
    let courseId: UUID
    let orderIndex: Int
    let title: String
    let description: String?
    let xpReward: Int
    let requiredScore: Int
    let iconName: String?
    let isCheckpoint: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case courseId      = "course_id"
        case orderIndex    = "order_index"
        case xpReward      = "xp_reward"
        case requiredScore = "required_score"
        case iconName      = "icon_name"
        case isCheckpoint  = "is_checkpoint"
    }
}

// MARK: - User Progress
enum SBLevelStatus: String, Codable {
    case locked      = "locked"
    case unlocked    = "unlocked"
    case inProgress  = "in_progress"
    case completed   = "completed"
}

struct SBUserProgress: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let levelId: UUID
    let status: SBLevelStatus
    let bestScore: Int
    let attempts: Int
    let xpEarned: Int
    let stars: Int
    let completedAt: Date?
    let lastPlayedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status, attempts, stars
        case userId      = "user_id"
        case levelId     = "level_id"
        case bestScore   = "best_score"
        case xpEarned    = "xp_earned"
        case completedAt = "completed_at"
        case lastPlayedAt = "last_played_at"
    }
}

// MARK: - Level + Progress (JOIN result for PathMapView)
struct SBLevelWithProgress: Identifiable {
    let id: UUID
    let level: SBLevel
    let progress: SBUserProgress?

    var status: SBLevelStatus {
        progress?.status ?? .locked
    }

    var stars: Int {
        progress?.stars ?? 0
    }

    var bestScore: Int {
        progress?.bestScore ?? 0
    }
}

// MARK: - Word
struct SBWord: Codable, Identifiable {
    let id: UUID
    let sourceLangId: Int
    let targetLangId: Int
    let term: String
    let translation: String
    let phonetic: String?
    let description: String?
    let exampleSentence: String?
    let difficulty: Int
    /// Multi-language translations keyed by uppercase ISO code e.g. ["EN": "hello", "TR": "merhaba"]
    let translations: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, term, translation, phonetic, description, difficulty, translations
        case sourceLangId    = "source_lang_id"
        case targetLangId    = "target_lang_id"
        case exampleSentence = "example_sentence"
    }

    /// Returns the translation for the given phone language code.
    /// Falls back to English, then to the default `translation` field (Turkish).
    func displayTranslation(phoneCode: String) -> String {
        let code = phoneCode.uppercased()
        return translations?[code]
            ?? translations?["EN"]
            ?? translation
    }
}

// MARK: - User Profile
struct SBUser: Codable, Identifiable {
    let id: UUID
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let nativeLangId: Int?
    /// Hedef dil (öğrenilen dil) — Supabase: target_lang_id
    let targetLangId: Int?
    /// Onboarding'de seçilen seviye 0-4 — Supabase: proficiency_level
    let proficiencyLevel: Int?
    let totalXp: Int
    let streakDays: Int
    let lastActivityAt: Date?
    let fcmToken: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName    = "display_name"
        case avatarUrl      = "avatar_url"
        case nativeLangId   = "native_lang_id"
        case targetLangId   = "target_lang_id"
        case proficiencyLevel = "proficiency_level"
        case totalXp        = "total_xp"
        case streakDays     = "streak_days"
        case lastActivityAt = "last_activity_at"
        case fcmToken       = "fcm_token"
    }
}

// MARK: - Quiz Attempt (write model)
struct SBQuizAttemptInsert: Codable {
    let userId: UUID
    let levelId: UUID
    let wordId: UUID
    let quizMode: String
    let userAnswer: String?
    let correctAnswer: String
    let isCorrect: Bool
    let responseMs: Int?

    enum CodingKeys: String, CodingKey {
        case userId        = "user_id"
        case levelId       = "level_id"
        case wordId        = "word_id"
        case quizMode      = "quiz_mode"
        case userAnswer    = "user_answer"
        case correctAnswer = "correct_answer"
        case isCorrect     = "is_correct"
        case responseMs    = "response_ms"
    }
}

// MARK: - Sentence (full-sentence translation questions)
/// A complete sentence stored in the DB for sentenceBuilder quiz questions.
/// `target_text` = the sentence shown (target language), `native_text` = correct translation.
struct SBSentence: Codable, Identifiable {
    let id: UUID
    let courseId: UUID
    let levelId: UUID?
    let targetText: String      // sentence in target language (shown to user)
    let nativeText: String      // correct native-language translation
    let keyWord: String?        // the word in targetText to highlight and translate
    let keyWordNative: String?  // native-language translation of keyWord
    let difficulty: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, difficulty
        case courseId      = "course_id"
        case levelId       = "level_id"
        case targetText    = "target_text"
        case nativeText    = "native_text"
        case keyWord       = "key_word"
        case keyWordNative = "key_word_native"
        case isActive      = "is_active"
    }
}

// MARK: - complete_level RPC Payload
struct CompleteLevelPayload: Encodable {
    let p_user_id: String
    let p_level_id: String
    let p_score: Int
    let p_quiz_mode: String
}

// MARK: - complete_level RPC Response
struct CompleteLevelResponse: Decodable {
    let success: Bool
    let passed: Bool?
    let score: Int?
    let stars: Int?
    let xpEarned: Int?
    let nextLevelId: String?
    let alreadyCompleted: Bool?
    let required: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success, passed, score, stars, required, error
        case xpEarned        = "xp_earned"
        case nextLevelId     = "next_level_id"
        case alreadyCompleted = "already_completed"
    }
}
