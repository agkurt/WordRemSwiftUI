//
//  StreakManager.swift
//  WordRemSwiftUI
//
//  Shows the streak celebration screen once per calendar day.
//  Streak is computed server-side (Supabase) via updateDailyLoginStreak().
//

import SwiftUI

@MainActor
final class StreakManager: ObservableObject {

    static let shared = StreakManager()

    // MARK: - Published
    @Published var shouldShowStreak = false
    @Published var currentStreak   = 0

    // MARK: - Private
    /// Tracks the last calendar day the celebration was shown (local only).
    private let lastShownKey = "streakScreenLastShownDate"
    private init() {}

    // MARK: - Main entry point
    /// Call from MainTabView.task after the user is authenticated.
    /// Updates the server-side streak and shows the celebration if this is
    /// the first app open of the day.
    func handleAppLaunch() async {
        do {
            let streak = try await SupabaseDataService.shared.updateDailyLoginStreak()
            currentStreak = streak

            guard streak >= 1 else { return }

            // Only show once per calendar day
            let today = Calendar.current.startOfDay(for: Date())
            if let lastShown = UserDefaults.standard.object(forKey: lastShownKey) as? Date {
                let lastDay = Calendar.current.startOfDay(for: lastShown)
                guard lastDay < today else { return }
            }

            // Brief delay so the main UI renders first
            try? await Task.sleep(nanoseconds: 800_000_000)
            shouldShowStreak = true

        } catch {
            print("⚠️ StreakManager.handleAppLaunch error: \(error)")
        }
    }

    /// Call when the user taps "Continue" on the celebration screen.
    func markShown() {
        UserDefaults.standard.set(Date(), forKey: lastShownKey)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            shouldShowStreak = false
        }
    }
}
