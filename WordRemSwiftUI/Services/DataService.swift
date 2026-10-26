//
//  DataService.swift
//  WordRemSwiftUI
//
//  Path / Quiz / Profil için veri katmanı. Eski SupabaseDataService ile aynı arayüz;
//  içerik ContentStore'dan (gömülü JSON), ilerleme UserStore'dan (cihaz + iCloud) gelir.
//  Sunucu yok → ağ hatası, oturum hatası ya da "proje durduruldu" sorunu yok.
//

import Foundation

final class DataService {

    static let shared = DataService()
    private let content = ContentStore.shared
    private let store = UserStore.shared
    private init() {}

    // MARK: - Languages / Courses
    func fetchLanguages() async throws -> [SBLanguage] {
        content.languages.filter(\.isActive)
    }

    /// Hedef dile göre kurslar. Kurslar ana dilden bağımsızdır (kelimelerde 8 dilde çeviri var).
    func fetchCourses(targetLangCode: String? = nil) async throws -> [SBCourse] {
        let active = content.courses.filter(\.isActive)
        guard let code = targetLangCode, let lang = content.language(code: code) else {
            return targetLangCode == nil ? active : []
        }
        return active.filter { $0.targetLangId == lang.id }
    }

    // MARK: - Preferences (onboarding) — UserDefaults'ta tutuluyor; burada sadece iz kaydı
    func saveUserPreferences(targetLangCode: String, nativeLangCode: String = "", proficiencyLevel: Int,
                             learningInterest: String = "", dailyGoalMinutes: Int = 10) async throws {
        store.update { $0.lastActivityAt = $0.lastActivityAt ?? Date() }
    }

    // MARK: - Levels + Progress
    func fetchLevels(courseId: UUID) async throws -> [SBLevel] {
        content.levels(courseId: courseId)
    }

    func fetchUserProgress(courseId: UUID) async throws -> [SBUserProgress] {
        let s = store.snapshot
        return content.levels(courseId: courseId).compactMap { level in
            s.progress[level.id.uuidString].map { progressModel(levelId: level.id, $0, userId: s.userId) }
        }
    }

    func fetchLevelsWithProgress(courseId: UUID) async throws -> [SBLevelWithProgress] {
        let s = store.snapshot
        return content.levels(courseId: courseId).map { level in
            SBLevelWithProgress(id: level.id, level: level,
                                progress: s.progress[level.id.uuidString].map { progressModel(levelId: level.id, $0, userId: s.userId) })
        }
    }

    func enrollInCourse(courseId: UUID) async throws {
        try await enrollWithProficiency(courseId: courseId, proficiencyLevel: 0)
    }

    /// Kursa ilk girişte sadece 1. seviye açılır (zaten açık/tamamlanmışsa dokunulmaz).
    func enrollWithProficiency(courseId: UUID, proficiencyLevel: Int) async throws {
        guard let first = content.levels(courseId: courseId).first else { return }
        store.update { s in
            if s.progress[first.id.uuidString] == nil {
                s.progress[first.id.uuidString] = LevelProgressRecord(status: .unlocked)
            }
        }
    }

    // MARK: - Words / Sentences
    func fetchWords(levelId: UUID, maxDifficulty: Int = 3) async throws -> [SBWord] {
        let all = content.words(levelId: levelId)
        let filtered = all.filter { $0.difficulty <= maxDifficulty }
        return filtered.isEmpty ? all : filtered
    }

    func fetchCourseId(forLevel levelId: UUID) async throws -> UUID? {
        content.level(id: levelId)?.courseId
    }

    func fetchSentences(courseId: UUID, maxDifficulty: Int = 3) async throws -> [SBSentence] {
        content.sentences(courseId: courseId).filter { $0.isActive && $0.difficulty <= maxDifficulty }
    }

    func fetchWords(byIds ids: [UUID]) async throws -> [SBWord] {
        content.words(ids: ids)
    }

    // MARK: - Complete level (eski complete_level RPC'nin aynısı)
    func completeLevel(levelId: UUID, score: Int, quizMode: String) async throws -> CompleteLevelResponse {
        guard let level = content.level(id: levelId) else {
            return CompleteLevelResponse(success: false, passed: nil, score: nil, stars: nil, xpEarned: nil,
                                         nextLevelId: nil, alreadyCompleted: nil, required: nil, error: "level_not_found")
        }
        let key = levelId.uuidString
        let now = Date()

        guard score >= level.requiredScore else {
            store.update { s in
                var rec = s.progress[key] ?? LevelProgressRecord(status: .inProgress)
                if rec.status != .completed { rec.status = .inProgress }
                rec.attempts += 1
                rec.lastPlayedAt = now
                s.progress[key] = rec
                s.lastActivityAt = now
            }
            return CompleteLevelResponse(success: false, passed: false, score: score, stars: nil, xpEarned: nil,
                                         nextLevelId: nil, alreadyCompleted: nil, required: level.requiredScore, error: nil)
        }

        let stars = score >= 95 ? 3 : (score >= 80 ? 2 : 1)
        let next = content.levels(courseId: level.courseId).first { $0.orderIndex == level.orderIndex + 1 }
        var xpAwarded = 0
        var alreadyDone = false

        store.update { s in
            var rec = s.progress[key] ?? LevelProgressRecord(status: .inProgress)
            alreadyDone = rec.status == .completed
            if !alreadyDone { xpAwarded = level.xpReward }
            else if stars > rec.stars { xpAwarded = (stars - rec.stars) * 3 }

            rec.status = .completed
            rec.bestScore = max(rec.bestScore, score)
            rec.stars = max(rec.stars, stars)
            rec.attempts += 1
            rec.xpEarned += xpAwarded
            rec.completedAt = rec.completedAt ?? now
            rec.lastPlayedAt = now
            s.progress[key] = rec
            s.totalXp += xpAwarded
            s.lastActivityAt = now

            if let next, s.progress[next.id.uuidString] == nil || s.progress[next.id.uuidString]?.status == .locked {
                s.progress[next.id.uuidString] = LevelProgressRecord(status: .unlocked)
            }
        }
        GameCenterService.shared.submitXP(store.snapshot.totalXp)

        return CompleteLevelResponse(success: true, passed: true, score: score, stars: stars, xpEarned: xpAwarded,
                                     nextLevelId: next?.id.uuidString, alreadyCompleted: alreadyDone,
                                     required: level.requiredScore, error: nil)
    }

    /// Eskiden RPC başarısız olursa kullanılırdı; artık yerel işlem asla başarısız olmuyor.
    func unlockNextLevelFallback(afterLevelId: UUID, score: Int) async {
        _ = try? await completeLevel(levelId: afterLevelId, score: score, quizMode: "fallback")
    }

    // MARK: - XP / Answers
    func awardXP(_ amount: Int) async {
        guard amount > 0 else { return }
        store.update { s in
            s.totalXp += min(amount, 500)
            s.lastActivityAt = Date()
        }
        GameCenterService.shared.submitXP(store.snapshot.totalXp)
    }

    func saveQuizAttempts(_ attempts: [SBQuizAttemptInsert]) async throws {
        guard !attempts.isEmpty else { return }
        store.update { s in
            s.totalAnswers += attempts.count
            s.correctAnswers += attempts.filter(\.isCorrect).count
        }
    }

    // MARK: - Profile
    func fetchUserProfile() async throws -> SBUser? {
        let s = store.snapshot
        let defaults = UserDefaults.standard
        let target = defaults.string(forKey: "selectedTargetLanguageCode").flatMap { content.language(code: $0)?.id }
        let native = content.language(code: OL.nativeLangCode)?.id
        return SBUser(
            id: s.userId,
            username: s.username.isEmpty ? AL.s(.profileGuest) : s.username,
            displayName: nil, avatarUrl: nil,
            nativeLangId: native, targetLangId: target,
            proficiencyLevel: defaults.integer(forKey: "selectedProficiencyLevel"),
            learningInterest: defaults.string(forKey: "learningInterest"),
            dailyGoalMinutes: defaults.integer(forKey: "dailyGoalMinutes"),
            totalXp: s.totalXp, streakDays: currentStreak(s),
            lastActivityAt: s.lastActivityAt, fcmToken: nil,
            usernameChanges: s.usernameChanges
        )
    }

    func updateUsername(_ name: String) {
        store.update { s in
            s.username = name
            s.usernameChanges += 1
        }
    }

    /// Uygulama açılışında çağrılır. Seri artık açılışla değil çalışmayla (quiz, ders, sesli, tekrar) ilerler;
    /// burada yalnızca widget/bildirim/diğer cihazdan gelen günler birleştirilir.
    @discardableResult
    func updateDailyLoginStreak() async throws -> Int {
        StudyStreak.sync()
        return StudyStreak.current
    }

    private func currentStreak(_ s: UserState) -> Int {
        ReviewCore.streak(activeDays: ReviewCore.loadActiveDays().union(s.studyDays ?? []))
    }

    // MARK: - Stats
    func fetchUserStats() async throws -> UserStats {
        let s = store.snapshot
        return UserStats(completedLevels: s.progress.values.filter { $0.status == .completed }.count,
                         totalAttempts: s.totalAnswers,
                         correctAnswers: s.correctAnswers)
    }

    // MARK: - Achievements
    func fetchAchievementIds() async throws -> [String] { Array(store.snapshot.achievements) }

    func saveAchievement(id: String) async throws {
        store.update { $0.achievements.insert(id) }
    }

    // MARK: - Helpers
    private func progressModel(levelId: UUID, _ r: LevelProgressRecord, userId: UUID) -> SBUserProgress {
        SBUserProgress(id: levelId, userId: userId, levelId: levelId, status: r.status,
                       bestScore: r.bestScore, attempts: r.attempts, xpEarned: r.xpEarned, stars: r.stars,
                       completedAt: r.completedAt, lastPlayedAt: r.lastPlayedAt)
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
