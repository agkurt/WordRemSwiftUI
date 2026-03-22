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

    // MARK: - Kullanıcı Tercihlerini Kaydet (tüm onboarding verileri)
    /// Onboarding'de seçilen tüm tercihleri Supabase'e yazar.
    /// Supabase migration gerekli:
    ///   ALTER TABLE users ADD COLUMN IF NOT EXISTS target_lang_id INTEGER REFERENCES languages(id);
    ///   ALTER TABLE users ADD COLUMN IF NOT EXISTS native_lang_id INTEGER REFERENCES languages(id);
    ///   ALTER TABLE users ADD COLUMN IF NOT EXISTS proficiency_level INTEGER DEFAULT 0;
    ///   ALTER TABLE users ADD COLUMN IF NOT EXISTS learning_interest TEXT;
    ///   ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_goal_minutes INTEGER DEFAULT 10;
    func saveUserPreferences(
        targetLangCode: String,
        nativeLangCode: String = "",
        proficiencyLevel: Int,
        learningInterest: String = "",
        dailyGoalMinutes: Int = 10
    ) async throws {
        guard let uid = SupabaseService.shared.currentUserId else { return }

        let languages = try await fetchLanguages()

        let targetLangId = languages.first(where: {
            $0.code.uppercased() == targetLangCode.uppercased()
        })?.id

        let nativeLangId: Int? = nativeLangCode.isEmpty ? nil : languages.first(where: {
            $0.code.uppercased() == nativeLangCode.uppercased()
        })?.id

        struct UserPrefsUpdate: Encodable {
            let target_lang_id: Int?
            let native_lang_id: Int?
            let proficiency_level: Int
            let learning_interest: String?
            let daily_goal_minutes: Int
        }

        try await db
            .from("users")
            .update(UserPrefsUpdate(
                target_lang_id: targetLangId,
                native_lang_id: nativeLangId,
                proficiency_level: proficiencyLevel,
                learning_interest: learningInterest.isEmpty ? nil : learningInterest,
                daily_goal_minutes: dailyGoalMinutes
            ))
            .eq("id", value: uid.uuidString)
            .execute()

        print("✅ saveUserPreferences: target=\(targetLangCode) native=\(nativeLangCode) level=\(proficiencyLevel) interest=\(learningInterest) goal=\(dailyGoalMinutes)min")
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

    /// Kursa ilk kayıtta her zaman Level 1'i açar.
    /// Proficiency seviyesi soru zorluğunu etkiler, başlangıç levelını değil.
    func enrollWithProficiency(courseId: UUID, proficiencyLevel: Int) async throws {
        guard let uid = SupabaseService.shared.currentUserId else {
            throw NSError(domain: "Auth", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "No active user session for enrollment"])
        }

        // Her zaman sadece ilk level açılır (order_index = 1)
        let levels: [SBLevel] = try await db
            .from("levels")
            .select()
            .eq("course_id", value: courseId.uuidString)
            .order("order_index")
            .limit(1)
            .execute()
            .value

        guard let firstLevel = levels.first else { return }

        struct ProgressInsert: Encodable {
            let user_id: String
            let level_id: String
            let status: String
            let best_score: Int
            let stars: Int
            let attempts: Int
        }

        try await db
            .from("user_progress")
            .upsert(
                ProgressInsert(
                    user_id:    uid.uuidString,
                    level_id:   firstLevel.id.uuidString,
                    status:     "unlocked",
                    best_score: 0,
                    stars:      0,
                    attempts:   0
                ),
                onConflict: "user_id,level_id"
            )
            .execute()
    }

    // MARK: - Words for a level
    /// maxDifficulty: proficiency seviyesinden türetilen kelime zorluk üst sınırı.
    ///   0/1 (beginner/elementary)  → 1  (yalnızca kolay kelimeler)
    ///   2   (intermediate)         → 2
    ///   3+  (upper/advanced)       → 3  (tüm kelimeler)
    func fetchWords(levelId: UUID, maxDifficulty: Int = 3) async throws -> [SBWord] {
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

        // İstemci tarafında difficulty filtresi (PostgREST nested filter yerine güvenli yaklaşım)
        let all = rows.map { $0.words }
        let filtered = all.filter { $0.difficulty <= maxDifficulty }
        // Filtreleme sonucu boş kalırsa tüm kelimeler döner (hata önleme)
        return filtered.isEmpty ? all : filtered
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
    /// maxDifficulty maps from the user's onboarding proficiency level:
    ///   0 (beginner)          → 1   A1/A2 only
    ///   1 (elementary)        → 1   A1/A2 only
    ///   2 (intermediate)      → 2   up to B1
    ///   3+ (upper/advanced)   → 3   all sentences
    func fetchSentences(courseId: UUID, maxDifficulty: Int = 3) async throws -> [SBSentence] {
        try await db
            .from("sentences")
            .select()
            .eq("course_id", value: courseId.uuidString)
            .eq("is_active", value: true)
            .lte("difficulty", value: maxDifficulty)
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

    // MARK: - Fallback: directly unlock next level (used when complete_level RPC fails)
    /// Marks `levelId` as completed and unlocks the following level in the same course.
    /// Safe to call even if the level is already completed/unlocked.
    func unlockNextLevelFallback(afterLevelId: UUID, score: Int) async {
        guard let uid = SupabaseService.shared.currentUserId else { return }

        do {
            // 1. Fetch current level metadata
            struct LevelMeta: Decodable {
                let courseId: UUID
                let orderIndex: Int
                enum CodingKeys: String, CodingKey {
                    case courseId    = "course_id"
                    case orderIndex  = "order_index"
                }
            }
            let metas: [LevelMeta] = try await db
                .from("levels")
                .select("course_id, order_index")
                .eq("id", value: afterLevelId.uuidString)
                .limit(1)
                .execute()
                .value
            guard let meta = metas.first else { return }

            // 2. Find next level
            struct LevelID: Decodable { let id: UUID }
            let nextLevels: [LevelID] = try await db
                .from("levels")
                .select("id")
                .eq("course_id", value: meta.courseId.uuidString)
                .eq("order_index", value: meta.orderIndex + 1)
                .limit(1)
                .execute()
                .value

            let stars: Int = score == 100 ? 3 : score >= 50 ? 2 : score >= 25 ? 1 : 0
            let now = ISO8601DateFormatter().string(from: Date())

            // 3. Mark current level as completed
            struct CompletedUpdate: Encodable {
                let status: String
                let best_score: Int
                let stars: Int
                let completed_at: String
                let updated_at: String
            }
            try await db
                .from("user_progress")
                .update(CompletedUpdate(
                    status: "completed",
                    best_score: score,
                    stars: stars,
                    completed_at: now,
                    updated_at: now
                ))
                .eq("user_id", value: uid.uuidString)
                .eq("level_id", value: afterLevelId.uuidString)
                .execute()

            // 4. Unlock next level (if exists and currently locked / missing)
            guard let nextLevel = nextLevels.first else { return }

            struct ProgressRow: Decodable { let status: String }
            let existing: [ProgressRow] = try await db
                .from("user_progress")
                .select("status")
                .eq("user_id", value: uid.uuidString)
                .eq("level_id", value: nextLevel.id.uuidString)
                .limit(1)
                .execute()
                .value

            let existingStatus = existing.first?.status ?? "locked"
            guard existingStatus == "locked" || existing.isEmpty else {
                print("ℹ️ Next level already \(existingStatus), skipping unlock")
                return
            }

            struct ProgressInsert: Encodable {
                let user_id: String; let level_id: String; let status: String
            }
            try await db
                .from("user_progress")
                .upsert(
                    ProgressInsert(user_id: uid.uuidString, level_id: nextLevel.id.uuidString, status: "unlocked"),
                    onConflict: "user_id,level_id"
                )
                .execute()

            print("✅ Fallback unlock: next level \(nextLevel.id) set to unlocked")
        } catch {
            print("⚠️ unlockNextLevelFallback error: \(error)")
        }
    }

    // MARK: - Award XP (mistakes & AI quiz)
    func awardXP(_ amount: Int) async {
        guard amount > 0, let uid = SupabaseService.shared.currentUserId else { return }
        struct Payload: Encodable { let p_user_id: String; let p_amount: Int }
        do {
            try await db
                .rpc("award_xp", params: Payload(p_user_id: uid.uuidString, p_amount: amount))
                .execute()
        } catch {
            print("⚠️ awardXP error: \(error)")
        }
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

    // MARK: - Daily login streak
    /// Call once per app launch when the user is authenticated.
    /// - Compares today with `last_activity_at` to decide: same day (skip),
    ///   consecutive day (increment), or gap (reset to 1).
    /// - Updates `streak_days` + `last_activity_at` in Supabase.
    /// - Returns the resulting streak so the caller can show the celebration screen.
    @discardableResult
    func updateDailyLoginStreak() async throws -> Int {
        guard let uid = SupabaseService.shared.currentUserId else { return 0 }
        guard let user = try await fetchUserProfile() else { return 0 }

        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Already counted today — nothing to update
        if let last = user.lastActivityAt, cal.startOfDay(for: last) == today {
            return user.streakDays
        }

        // Calculate new streak
        let newStreak: Int
        if let last = user.lastActivityAt {
            let lastDay   = cal.startOfDay(for: last)
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            newStreak = (lastDay == yesterday) ? user.streakDays + 1 : 1
        } else {
            newStreak = 1  // first ever login
        }

        // Persist (the DB trigger also updates streak_days, values agree)
        struct LoginUpdate: Encodable {
            let streak_days: Int
            let last_activity_at: Date
        }
        try await db
            .from("users")
            .update(LoginUpdate(streak_days: newStreak, last_activity_at: Date()))
            .eq("id", value: uid.uuidString)
            .execute()

        return newStreak
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
        // Step 1: Get the user's own XP
        struct XPRow: Decodable { let total_xp: Int }
        let xpRows: [XPRow] = try await db
            .from("users")
            .select("total_xp")
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let myXP = xpRows.first?.total_xp else { return 0 }

        // Step 2: Count users with strictly MORE XP → those ranked above us
        struct IdOnly: Decodable { let id: String }
        let above: [IdOnly] = try await db
            .from("users")
            .select("id")
            .gt("total_xp", value: myXP)
            .execute()
            .value

        return above.count + 1
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

    // MARK: - User Achievements (used by AchievementService)
    struct AchievementRow: Decodable { let achievement_id: String }

    func fetchAchievementIds() async throws -> [String] {
        guard let uid = SupabaseService.shared.currentUserId else { return [] }
        let rows: [AchievementRow] = try await db
            .from("user_achievements")
            .select("achievement_id")
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return rows.map { $0.achievement_id }
    }

    func saveAchievement(id: String) async throws {
        guard let uid = SupabaseService.shared.currentUserId else { return }
        struct Row: Encodable { let user_id: String; let achievement_id: String }
        try await db
            .from("user_achievements")
            .insert(Row(user_id: uid.uuidString, achievement_id: id))
            .execute()
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
