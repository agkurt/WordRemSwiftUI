//
//  DailyLimitManager.swift
//  WordRemSwiftUI
//
//  Günlük 25 soru limitini yönetir.
//  Premium kullanıcılar sınırsız soru hakkına sahiptir.
//

import Foundation

final class DailyLimitManager {

    static let shared   = DailyLimitManager()
    static let dailyLimit = 25

    private let usedKey      = "dq_used"
    private let resetDateKey = "dq_resetDate"
    private let premiumKey   = "isPremium"

    private init() {}

    // MARK: - Premium

    // TODO: StoreKit entegrasyonu hazır olunca burası gerçek satın alma kontrolüne bağlanacak
    var isPremium: Bool {
        get { true }
        set { UserDefaults.standard.set(newValue, forKey: premiumKey) }
    }

    // MARK: - Questions Used

    /// Bugün kullanılan soru sayısı (süresi geçmişse sıfırlar)
    var questionsUsedToday: Int {
        refreshIfNeeded()
        return UserDefaults.standard.integer(forKey: usedKey)
    }

    var questionsRemaining: Int {
        max(0, Self.dailyLimit - questionsUsedToday)
    }

    var canAskQuestion: Bool {
        isPremium || questionsRemaining > 0
    }

    /// Soru cevaplandığında çağır — 1 kullanım hakkı düşer
    func recordQuestion() {
        guard !isPremium else { return }
        refreshIfNeeded()

        let current = UserDefaults.standard.integer(forKey: usedKey)

        // İlk soru ise reset tarihini 24 saat sonraya ayarla
        if current == 0 {
            let resetDate = Date().addingTimeInterval(24 * 3600)
            UserDefaults.standard.set(resetDate, forKey: resetDateKey)
        }

        UserDefaults.standard.set(current + 1, forKey: usedKey)
    }

    // MARK: - Reset Countdown

    /// Sıfırlanma tarihi
    var resetDate: Date {
        UserDefaults.standard.object(forKey: resetDateKey) as? Date
            ?? Date().addingTimeInterval(24 * 3600)
    }

    /// Sıfırlanmaya kalan saniye
    var secondsUntilReset: TimeInterval {
        max(0, resetDate.timeIntervalSinceNow)
    }

    /// "23:47:12" formatında kalan süre
    var countdownString: String {
        let total   = Int(secondsUntilReset)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Private

    private func refreshIfNeeded() {
        guard let reset = UserDefaults.standard.object(forKey: resetDateKey) as? Date else { return }
        if Date() >= reset {
            UserDefaults.standard.set(0, forKey: usedKey)
            UserDefaults.standard.removeObject(forKey: resetDateKey)
        }
    }
}
