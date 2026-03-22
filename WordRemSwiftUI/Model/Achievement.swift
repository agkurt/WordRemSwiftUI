//
//  Achievement.swift
//  WordRemSwiftUI
//
//  Defines all 20 achievements, their unlock conditions, visual style, and rarity.
//

import SwiftUI

// MARK: - Rarity
enum AchievementRarity: String {
    case common    = "common"
    case rare      = "rare"
    case epic      = "epic"
    case legendary = "legendary"

    var label: String {
        switch self {
        case .common:    return AL.s(.achievementRarityCommon)
        case .rare:      return AL.s(.achievementRarityRare)
        case .epic:      return AL.s(.achievementRarityEpic)
        case .legendary: return AL.s(.achievementRarityLegendary)
        }
    }

    var color: Color {
        switch self {
        case .common:    return Color(hex: "#64748b")
        case .rare:      return Color(hex: "#3b82f6")
        case .epic:      return Color(hex: "#8b5cf6")
        case .legendary: return Color(hex: "#f59e0b")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .common:    return [Color(hex: "#94a3b8"), Color(hex: "#64748b")]
        case .rare:      return [Color(hex: "#60a5fa"), Color(hex: "#3b82f6")]
        case .epic:      return [Color(hex: "#a78bfa"), Color(hex: "#7c3aed")]
        case .legendary: return [Color(hex: "#fcd34d"), Color(hex: "#f59e0b")]
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let color: Color
    let rarity: AchievementRarity
    var isUnlocked: Bool = false
    var unlockedAt: Date? = nil

    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
}

// MARK: - All Achievements
extension Achievement {

    /// Complete catalogue — order determines display order
    static func all() -> [Achievement] {[
        // ── Common ──────────────────────────────────────────────────────
        Achievement(
            id: "first_steps",
            icon: "checkmark.seal.fill",
            title: AL.s(.achFirstStepsTitle),
            description: AL.s(.achFirstStepsDesc),
            color: Color(hex: "#22c55e"),
            rarity: .common
        ),
        Achievement(
            id: "first_streak",
            icon: "flame.fill",
            title: AL.s(.achFirstStreakTitle),
            description: AL.s(.achFirstStreakDesc),
            color: Color(hex: "#f97316"),
            rarity: .common
        ),
        Achievement(
            id: "100_xp",
            icon: "bolt.fill",
            title: AL.s(.ach100XPTitle),
            description: AL.s(.ach100XPDesc),
            color: Color(hex: "#f59e0b"),
            rarity: .common
        ),
        Achievement(
            id: "5_levels",
            icon: "star.fill",
            title: AL.s(.ach5LevelsTitle),
            description: AL.s(.ach5LevelsDesc),
            color: Color(hex: "#facc15"),
            rarity: .common
        ),
        Achievement(
            id: "50_correct",
            icon: "checkmark.circle.fill",
            title: AL.s(.ach50CorrectTitle),
            description: AL.s(.ach50CorrectDesc),
            color: Color(hex: "#10b981"),
            rarity: .common
        ),
        // ── Rare ────────────────────────────────────────────────────────
        Achievement(
            id: "500_xp",
            icon: "crown.fill",
            title: AL.s(.ach500XPTitle),
            description: AL.s(.ach500XPDesc),
            color: Color(hex: "#8b5cf6"),
            rarity: .rare
        ),
        Achievement(
            id: "sharp_eye",
            icon: "scope",
            title: AL.s(.achSharpEyeTitle),
            description: AL.s(.achSharpEyeDesc),
            color: Color(hex: "#E8409C"),
            rarity: .rare
        ),
        Achievement(
            id: "10_levels",
            icon: "star.circle.fill",
            title: AL.s(.ach10LevelsTitle),
            description: AL.s(.ach10LevelsDesc),
            color: Color(hex: "#6366f1"),
            rarity: .rare
        ),
        Achievement(
            id: "7_streak",
            icon: "flame.circle.fill",
            title: AL.s(.ach7StreakTitle),
            description: AL.s(.ach7StreakDesc),
            color: Color(hex: "#ef4444"),
            rarity: .rare
        ),
        Achievement(
            id: "1000_xp",
            icon: "sparkles",
            title: AL.s(.ach1000XPTitle),
            description: AL.s(.ach1000XPDesc),
            color: Color(hex: "#3b82f6"),
            rarity: .rare
        ),
        Achievement(
            id: "100_correct",
            icon: "hands.clap.fill",
            title: AL.s(.ach100CorrectTitle),
            description: AL.s(.ach100CorrectDesc),
            color: Color(hex: "#14b8a6"),
            rarity: .rare
        ),
        // ── Epic ────────────────────────────────────────────────────────
        Achievement(
            id: "25_levels",
            icon: "medal.fill",
            title: AL.s(.ach25LevelsTitle),
            description: AL.s(.ach25LevelsDesc),
            color: Color(hex: "#f97316"),
            rarity: .epic
        ),
        Achievement(
            id: "30_streak",
            icon: "calendar.badge.checkmark",
            title: AL.s(.ach30StreakTitle),
            description: AL.s(.ach30StreakDesc),
            color: Color(hex: "#ec4899"),
            rarity: .epic
        ),
        Achievement(
            id: "perfectionist",
            icon: "target",
            title: AL.s(.achPerfectionistTitle),
            description: AL.s(.achPerfectionistDesc),
            color: Color(hex: "#a855f7"),
            rarity: .epic
        ),
        Achievement(
            id: "5000_xp",
            icon: "trophy.fill",
            title: AL.s(.ach5000XPTitle),
            description: AL.s(.ach5000XPDesc),
            color: Color(hex: "#eab308"),
            rarity: .epic
        ),
        Achievement(
            id: "500_correct",
            icon: "hands.sparkles.fill",
            title: AL.s(.ach500CorrectTitle),
            description: AL.s(.ach500CorrectDesc),
            color: Color(hex: "#7c3aed"),
            rarity: .epic
        ),
        // ── Legendary ───────────────────────────────────────────────────
        Achievement(
            id: "50_levels",
            icon: "map.fill",
            title: AL.s(.ach50LevelsTitle),
            description: AL.s(.ach50LevelsDesc),
            color: Color(hex: "#2563eb"),
            rarity: .legendary
        ),
        Achievement(
            id: "100_streak",
            icon: "flame.fill",
            title: AL.s(.ach100StreakTitle),
            description: AL.s(.ach100StreakDesc),
            color: Color(hex: "#dc2626"),
            rarity: .legendary
        ),
        Achievement(
            id: "10000_xp",
            icon: "star.of.life.fill",
            title: AL.s(.ach10000XPTitle),
            description: AL.s(.ach10000XPDesc),
            color: Color(hex: "#d97706"),
            rarity: .legendary
        ),
        Achievement(
            id: "word_god",
            icon: "book.fill",
            title: AL.s(.achWordGodTitle),
            description: AL.s(.achWordGodDesc),
            color: Color(hex: "#7c3aed"),
            rarity: .legendary
        ),
    ]}

    // MARK: - Unlock Condition Check
    /// Returns true if this achievement is unlocked based on the given stats.
    func isEarned(xp: Int, streak: Int, completedLevels: Int,
                  totalAttempts: Int, correctAnswers: Int, accuracy: Double) -> Bool {
        switch id {
        case "first_steps":   return totalAttempts >= 1
        case "first_streak":  return streak >= 1
        case "100_xp":        return xp >= 100
        case "5_levels":      return completedLevels >= 5
        case "50_correct":    return correctAnswers >= 50
        case "500_xp":        return xp >= 500
        case "sharp_eye":     return totalAttempts >= 20 && accuracy >= 90
        case "10_levels":     return completedLevels >= 10
        case "7_streak":      return streak >= 7
        case "1000_xp":       return xp >= 1000
        case "100_correct":   return correctAnswers >= 100
        case "25_levels":     return completedLevels >= 25
        case "30_streak":     return streak >= 30
        case "perfectionist": return totalAttempts >= 50 && accuracy >= 95
        case "5000_xp":       return xp >= 5000
        case "500_correct":   return correctAnswers >= 500
        case "50_levels":     return completedLevels >= 50
        case "100_streak":    return streak >= 100
        case "10000_xp":      return xp >= 10_000
        case "word_god":      return totalAttempts >= 1000
        default:              return false
        }
    }
}
