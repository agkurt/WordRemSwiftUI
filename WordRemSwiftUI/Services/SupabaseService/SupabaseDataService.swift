//
//  SupabaseDataService.swift
//  WordRemSwiftUI
//
//  Data access layer for the gamified module (Path, Quiz).
//  Fetches courses, levels, words, and writes quiz attempts / progress.
//

import Foundation
import Supabase

final class SupabaseDataService {

    static let shared = SupabaseDataService()
    private var db: SupabaseClient { SupabaseService.shared.client }
    private init() {}

    // MARK: - Languages
    func fetchLanguages() async throws -> [SBLanguage] {
        try await db
            .from("languages")
            .select()
            .eq("is_active", value: true)
            .execute()
            .value
    }

    // MARK: - Courses
    /// Kullanıcının öğreneceği dile göre kursları filtreler.
    /// - Parameter targetLangCode: "en", "de", "fr" gibi ISO kodu. nil ise tüm aktif kurslar döner.
    func fetchCourses(targetLangCode: String? = nil) async throws -> [SBCourse] {
        guard let code = targetLangCode?.uppercased() else {
            // No language preference → return all active courses
            return try await db
                .from("courses")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value
        }

        // Find the language ID for the requested code
        let languages = try await fetchLanguages()
        guard let lang = languages.first(where: { $0.code.uppercased() == code }) else {
            // Unknown language code → return empty so caller can show "no courses" state
            return []
        }

        // Return only courses whose target_lang_id matches — empty means no course for this language
        let filtered: [SBCourse] = try await db
            .from("courses")
            .select()
            .eq("is_active", value: true)
            .eq("target_lang_id", value: lang.id)
            .execute()
            .value

        return filtered
    }

    // MARK: - Kullanıcı Tercihlerini Kaydet (dil + seviye)
    /// Onboarding'de seçilen hedef dil ve seviyeyi Supabase'e yazar.
    /// Supabase migration gerekli:
    ///   ALTER TABLE users ADD COLUMN IF NOT EXISTS target_lang_id INTEGER REFERENCES languages(id);
    ///   ALTER TABLE users ADD COLUMN IF NOT EXISTS proficiency_level INTEGER DEFAULT 0;
    func saveUserPreferences(targetLangCode: String, proficiencyLevel: Int) async throws {
        guard let uid = SupabaseService.shared.currentUserId else { return }

        let languages = try await fetchLanguages()
        let targetLangId = languages.first(where: {
            $0.code.uppercased() == targetLangCode.uppercased()
        })?.id

        struct UserPrefsUpdate: Encodable {
            let target_lang_id: Int?
            let proficiency_level: Int
        }

        try await db
            .from("users")
            .update(UserPrefsUpdate(target_lang_id: targetLangId, proficiency_level: proficiencyLevel))
            .eq("id", value: uid.uuidString)
            .execute()
    }

    // MARK: - Levels for a course
    func fetchLevels(courseId: UUID) async throws -> [SBLevel] {
        try await db
            .from("levels")
            .select()
            .eq("course_id", value: courseId.uuidString)
            .order("order_index")
            .execute()
            .value
    }

    // MARK: - User progress for a course
    func fetchUserProgress(courseId: UUID) async throws -> [SBUserProgress] {
        guard let uid = SupabaseService.shared.currentUserId else { return [] }

        // Get all level IDs for this course, then fetch progress
        let levels: [SBLevel] = try await fetchLevels(courseId: courseId)
        let levelIds = levels.map { $0.id.uuidString }
        guard !levelIds.isEmpty else { return [] }

        return try await db
            .from("user_progress")
            .select()
            .eq("user_id", value: uid.uuidString)
            .in("level_id", values: levelIds)
            .execute()
            .value
    }

    // MARK: - Levels + Progress merged (for PathMapView)
    func fetchLevelsWithProgress(courseId: UUID) async throws -> [SBLevelWithProgress] {
        let levels = try await fetchLevels(courseId: courseId)
        let progressList = try await fetchUserProgress(courseId: courseId)
        let progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.levelId, $0) })

        return levels.map { level in
            SBLevelWithProgress(id: level.id, level: level, progress: progressMap[level.id])
        }
    }

    // MARK: - Unlock first level for new enrollment
    func enrollInCourse(courseId: UUID) async throws {
        try await enrollWithProficiency(courseId: courseId, proficiencyLevel: 0)
    }

    /// Kursa ilk kayıtta her zaman 1 level açar. Sonraki levellar quiz tamamlandıkça açılır.
    func enrollWithProficiency(courseId: UUID, proficiencyLevel: Int) async throws {
        guard let uid = SupabaseService.shared.currentUserId else { return }

        let levelsToUnlock = 1

        let levels: [SBLevel] = try await db
            .from("levels")
            .select()
            .eq("course_id", value: courseId.uuidString)
            .order("order_index")
            .limit(levelsToUnlock)
            .execute()
            .value

        guard !levels.isEmpty else { return }

        struct ProgressInsert: Encodable {
            let user_id: String
            let level_id: String
            let status: String
        }

        for level in levels {
            try await db
                .from("user_progress")
                .upsert(
                    ProgressInsert(
                        user_id: uid.uuidString,
                        level_id: level.id.uuidString,
                        status: "unlocked"
                    ),
                    onConflict: "user_id,level_id"
                )
                .execute()
        }
    }

    // MARK: - Words for a level
    func fetchWords(levelId: UUID) async throws -> [SBWord] {
        // words joined through word_level_assignments
        struct WordWithOrder: Decodable {
            let display_order: Int
            let words: SBWord
        }

        let rows: [WordWithOrder] = try await db
            .from("word_level_assignments")
            .select("display_order, words(*)")
            .eq("level_id", value: levelId.uuidString)
            .order("display_order")
            .execute()
            .value

        return rows.map { $0.words }
    }

    // MARK: - Find course_id for a level (needed to fetch sentences)
    func fetchCourseId(forLevel levelId: UUID) async throws -> UUID? {
        let levels: [SBLevel] = try await db
            .from("levels")
            .select("id, course_id")
            .eq("id", value: levelId.uuidString)
            .limit(1)
            .execute()
            .value
        return levels.first?.courseId
    }

    // MARK: - Sentences for a course (sentenceBuilder questions)
    func fetchSentences(courseId: UUID) async throws -> [SBSentence] {
        try await db
            .from("sentences")
            .select()
            .eq("course_id", value: courseId.uuidString)
            .eq("is_active", value: true)
            .order("order_index")
            .execute()
            .value
    }

    // MARK: - Words by IDs (For Mistakes Practice)
    func fetchWords(byIds ids: [UUID]) async throws -> [SBWord] {
        guard !ids.isEmpty else { return [] }
        let idStrings = ids.map { $0.uuidString }
        return try await db
            .from("words")
            .select()
            .in("id", values: idStrings)
            .execute()
            .value
    }

    // MARK: - Complete level (calls PostgreSQL RPC)
    func completeLevel(
        levelId: UUID,
        score: Int,
        quizMode: String
    ) async throws -> CompleteLevelResponse {
        guard let uid = SupabaseService.shared.currentUserId else {
            throw URLError(.userAuthenticationRequired)
        }
        let payload = CompleteLevelPayload(
            p_user_id: uid.uuidString,
            p_level_id: levelId.uuidString,
            p_score: score,
            p_quiz_mode: quizMode
        )
        return try await db
            .rpc("complete_level", params: payload)
            .execute()
            .value
    }

    // MARK: - Save quiz attempts (batch insert)
    func saveQuizAttempts(_ attempts: [SBQuizAttemptInsert]) async throws {
        guard !attempts.isEmpty else { return }
        try await db
            .from("quiz_attempts")
            .insert(attempts)
            .execute()
    }

    // MARK: - Fetch user profile
    func fetchUserProfile() async throws -> SBUser? {
        guard let uid = SupabaseService.shared.currentUserId else { return nil }
        let users: [SBUser] = try await db
            .from("users")
            .select()
            .eq("id", value: uid.uuidString)
            .limit(1)
            .execute()
            .value
        return users.first
    }

    // MARK: - Leaderboard (top users by XP)
    func fetchLeaderboard(limit: Int = 50) async throws -> [SBUser] {
        try await db
            .from("users")
            .select()
            .order("total_xp", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Specific User Rank
    func fetchUserRank(userId: UUID) async throws -> Int {
        // Calling our newly generated RPC function get_user_rank
        struct RankPayload: Encodable { let p_user_id: String }
        let rank: Int = try await db.rpc(
            "get_user_rank",
            params: RankPayload(p_user_id: userId.uuidString)
        ).execute().value
        return rank
    }

    // MARK: - User Stats (completed levels, total quizzes, accuracy)
    func fetchUserStats() async throws -> UserStats {
        guard let uid = SupabaseService.shared.currentUserId else {
            return UserStats(completedLevels: 0, totalAttempts: 0, correctAnswers: 0)
        }

        // Count completed levels
        let progressList: [SBUserProgress] = try await db
            .from("user_progress")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("status", value: "completed")
            .execute()
            .value
        let completedLevels = progressList.count

        // Count quiz attempts and correct answers
        struct AttemptRow: Decodable {
            let is_correct: Bool
        }
        let attempts: [AttemptRow] = try await db
            .from("quiz_attempts")
            .select("is_correct")
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value

        return UserStats(
            completedLevels: completedLevels,
            totalAttempts: attempts.count,
            correctAnswers: attempts.filter { $0.is_correct }.count
        )
    }
}

// MARK: - User Stats Model
struct UserStats {
    let completedLevels: Int
    let totalAttempts: Int
    let correctAnswers: Int

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAttempts) * 100
    }
}
