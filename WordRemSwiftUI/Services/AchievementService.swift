//
//  AchievementService.swift
//  WordRemSwiftUI
//
//  Singleton service that checks, saves, and broadcasts achievement unlocks.
//  - Fetches already-unlocked IDs from Supabase `user_achievements` table.
//  - Compares against all 20 Achievement definitions.
//  - Saves newly earned achievements and queues them for popup display.
//

import SwiftUI

@MainActor
final class AchievementService: ObservableObject {

    static let shared = AchievementService()
    private init() {}

    // MARK: - Published State
    /// Queue of achievements earned this session — shown one at a time as popups.
    @Published var pendingUnlocks: [Achievement] = []
    /// All achievement IDs already saved in Supabase for this user.
    @Published var unlockedIds: Set<String> = []
    /// Full list with up-to-date unlock state (used for ProfileView display).
    @Published var all: [Achievement] = Achievement.all()

    // MARK: - Supabase table row model
    private struct UserAchievementRow: Decodable {
        let achievement_id: String
        let unlocked_at: Date?
    }
    private struct InsertRow: Encodable {
        let user_id: String
        let achievement_id: String
    }


    // MARK: - Fetch saved achievements (yerel + iCloud)
    func fetchSaved() async {
        let ids = Set((try? await DataService.shared.fetchAchievementIds()) ?? [])
        unlockedIds = ids
        all = Achievement.all().map { ach in
            var copy = ach
            copy.isUnlocked = ids.contains(ach.id)
            return copy
        }
    }

    // MARK: - Check & Unlock
    /// Call this after quiz completion or profile load.
    /// Compares current stats against all achievement conditions,
    /// saves new unlocks to Supabase, and queues popup notifications.
    func checkAndUnlock(user: SBUser, stats: UserStats) async {

        // Refresh saved IDs first (cheap query)
        await fetchSaved()

        let xp             = user.totalXp ?? 0
        let streak         = user.streakDays ?? 0
        let completedLvls  = stats.completedLevels
        let totalAttempts  = stats.totalAttempts
        let correctAnswers = stats.correctAnswers
        let accuracy       = stats.accuracy

        var newUnlocks: [Achievement] = []

        for ach in Achievement.all() {
            // Already unlocked — skip
            guard !unlockedIds.contains(ach.id) else { continue }

            // Check condition
            guard ach.isEarned(
                xp: xp, streak: streak,
                completedLevels: completedLvls,
                totalAttempts: totalAttempts,
                correctAnswers: correctAnswers,
                accuracy: accuracy
            ) else { continue }

            try? await DataService.shared.saveAchievement(id: ach.id)

            var unlocked = ach
            unlocked.isUnlocked = true
            unlocked.unlockedAt = Date()
            newUnlocks.append(unlocked)
            unlockedIds.insert(ach.id)
        }

        // Refresh full list with new states
        all = Achievement.all().map { ach in
            var copy = ach
            copy.isUnlocked = unlockedIds.contains(ach.id)
            return copy
        }

        // Queue new unlocks for popup — append so multiple can show sequentially
        if !newUnlocks.isEmpty {
            pendingUnlocks.append(contentsOf: newUnlocks)
        }
    }

    // MARK: - Dismiss current popup
    func dismissCurrentUnlock() {
        guard !pendingUnlocks.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            pendingUnlocks.removeFirst()
        }
    }
}
