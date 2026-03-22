//
//  SessionTimeTracker.swift
//  WordRemSwiftUI
//
//  Kullanıcının uygulamada geçirdiği günlük süreyi takip eder.
//  Onboarding'de seçilen dailyGoalMinutes dolduğunda shouldShowBreakPrompt = true yapar.
//

import SwiftUI
import Combine

final class SessionTimeTracker: ObservableObject {

    static let shared = SessionTimeTracker()

    // MARK: - Published
    @Published var shouldShowBreakPrompt = false

    // MARK: - Private state
    private var sessionStart: Date?
    private var checkTimer: AnyCancellable?

    // MARK: - UserDefaults keys
    private let kAccumulatedSeconds = "stt_daily_accumulated_seconds"
    private let kAccumulatedDate    = "stt_daily_accumulated_date"
    private let kBreakShownDate     = "stt_break_shown_date"

    // MARK: - Init
    private init() {
        resetIfNewDay()
        startCheckTimer()
    }

    // MARK: - App lifecycle hooks (call from MainTabView or App)

    func appBecameActive() {
        resetIfNewDay()
        sessionStart = Date()
    }

    func appWentBackground() {
        flushCurrentSession()
    }

    // MARK: - Internal

    private func startCheckTimer() {
        // Her 30 saniyede bir hedefi kontrol et
        checkTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkGoal() }
    }

    private func checkGoal() {
        let goalMinutes = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        guard goalMinutes > 0 else { return }
        guard !hasShownBreakToday() else { return }

        let total = accumulatedSecondsToday() + liveSessionSeconds()
        let goalSeconds = Double(goalMinutes * 60)

        if total >= goalSeconds {
            markBreakShown()
            DispatchQueue.main.async { [weak self] in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    self?.shouldShowBreakPrompt = true
                }
            }
        }
    }

    /// Aktif session'ı UserDefaults'a yaz
    private func flushCurrentSession() {
        guard let start = sessionStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        let current = UserDefaults.standard.double(forKey: kAccumulatedSeconds)
        UserDefaults.standard.set(current + elapsed, forKey: kAccumulatedSeconds)
        sessionStart = nil
        checkGoal()
    }

    // MARK: - Helpers

    /// Bu anki session'ın saniyesi (henüz flush edilmemiş)
    private func liveSessionSeconds() -> Double {
        guard let start = sessionStart else { return 0 }
        return Date().timeIntervalSince(start)
    }

    /// Bugün için birikmiş saniyeler
    private func accumulatedSecondsToday() -> Double {
        UserDefaults.standard.double(forKey: kAccumulatedSeconds)
    }

    private func resetIfNewDay() {
        let stored = UserDefaults.standard.object(forKey: kAccumulatedDate) as? Date
        if stored == nil || !Calendar.current.isDateInToday(stored!) {
            UserDefaults.standard.set(0.0,   forKey: kAccumulatedSeconds)
            UserDefaults.standard.set(Date(), forKey: kAccumulatedDate)
            UserDefaults.standard.removeObject(forKey: kBreakShownDate)
        }
    }

    private func hasShownBreakToday() -> Bool {
        guard let shown = UserDefaults.standard.object(forKey: kBreakShownDate) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(shown)
    }

    private func markBreakShown() {
        UserDefaults.standard.set(Date(), forKey: kBreakShownDate)
    }

    // MARK: - Total minutes today (for display in popup)
    var minutesTodayForDisplay: Int {
        let total = accumulatedSecondsToday() + liveSessionSeconds()
        return max(1, Int(total / 60))
    }
}
