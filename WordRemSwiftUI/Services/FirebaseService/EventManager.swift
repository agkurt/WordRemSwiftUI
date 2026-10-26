//
//  EventManager.swift
//  WordRemSwiftUI
//
//  Ürün analitiği (Firebase / GA4). Tasarım: docs/analytics/events.md
//  Az olay, çok parametre: her olay bir soruya cevap verir, `action` içinde ne olduğunu söyler.
//  Firebase'e yalnızca bu dosya dokunur.
//

import Foundation
import os
import FirebaseCore
import FirebaseAnalytics
import RevenueCat

enum Track {

    private static let log = Logger(subsystem: "com.twinflare.WordRemSwiftUI", category: "events")
    private static var enabled = false
    private static var lastUserRefresh = Date.distantPast

    // MARK: - Kurulum
    static func configure() {
        FirebaseApp.configure()
        #if DEBUG
        // Geliştirirken veriyi kirletme: yalnızca DebugView için -FIRDebugEnabled ile açılır
        enabled = ProcessInfo.processInfo.arguments.contains("-FIRDebugEnabled")
        #else
        enabled = true
        #endif
        Analytics.setAnalyticsCollectionEnabled(enabled)
        guard enabled else { return }
        refreshUser(force: true)
    }

    /// user_id + kullanıcı özellikleri (her olaya otomatik eklenir). Ucuz ama sık çağrılmasın.
    static func refreshUser(force: Bool = false) {
        guard enabled, force || Date().timeIntervalSince(lastUserRefresh) > 30 else { return }
        lastUserRefresh = Date()
        let appUserId = Purchases.isConfigured ? Purchases.shared.appUserID : UserStore.shared.userId.uuidString
        Analytics.setUserID(appUserId)
        if Purchases.isConfigured, let instance = Analytics.appInstanceID() {
            // RevenueCat satın almaları GA4 kullanıcısıyla eşleşsin
            Purchases.shared.attribution.setFirebaseAppInstanceID(instance)
        }
        let d = UserDefaults.standard
        let langs = LearningLanguages.added
        let lessons = langs.map { LearningLanguages.doneCount($0) }.reduce(0, +)
        let props: [String: String] = [
            "wr_user_id": String(appUserId.replacingOccurrences(of: "$RCAnonymousID:", with: "").prefix(36)),
            "native_lang": OL.nativeLangCode.lowercased(),
            "target_lang": LearningLanguages.current,
            "ui_lang": LanguageManager.shared.currentLanguageCode,
            "langs_count": "\(langs.count)",
            "level": "\(d.integer(forKey: "selectedProficiencyLevel"))",
            "tier": tier,
            "lessons_done": bucket(lessons, [0, 2, 5, 10, 25]),
            "onboarding_done": d.bool(forKey: "hasCompletedOnboarding") ? "yes" : "no",
            "paywall_views": bucket(d.integer(forKey: paywallViewsKey), [0, 1, 2, 5]),
        ]
        for (k, v) in props { Analytics.setUserProperty(v, forName: k) }
    }

    /// Sunucunun verdiği plan (free / trial / pro) en doğrusu; yoksa cihazdaki abonelik durumu
    static var tier: String {
        UserDefaults.standard.string(forKey: tierKey) ?? (InAppPurchaseManager.shared.isPremium ? "pro" : "free")
    }
    static func setTier(_ value: String) {
        UserDefaults.standard.set(value, forKey: tierKey)
        refreshUser(force: true)
    }
    private static let tierKey = "analytics.tier"
    private static let paywallViewsKey = "analytics.paywallViews"

    /// 0, 1-2, 3-5 … gibi aralık etiketleri (kullanıcı özelliği değerleri az çeşitte kalsın)
    private static func bucket(_ n: Int, _ edges: [Int]) -> String {
        var low = 0
        for edge in edges {
            if n <= edge { return low == edge ? "\(edge)" : "\(low)-\(edge)" }
            low = edge + 1
        }
        return "\(low)+"
    }

    // MARK: - Gönderim
    static func event(_ name: String, _ params: [String: Any?]) {
        var clean: [String: Any] = [:]
        for (k, v) in params {
            switch v {
            case let b as Bool: clean[k] = b ? 1 : 0
            case let i as Int: clean[k] = i
            case let x as Double: clean[k] = (x * 100).rounded() / 100
            case let dec as Decimal: clean[k] = NSDecimalNumber(decimal: dec).doubleValue
            case let s as String where !s.isEmpty: clean[k] = String(s.prefix(100))
            default: break
            }
        }
        log.info("\(name, privacy: .public) \(clean.description, privacy: .public)")
        guard enabled else { return }
        refreshUser()
        Analytics.logEvent(name, parameters: clean)
    }

    // MARK: - 1. Onboarding
    static func onboarding(_ action: String, step: String, index: Int, timeOnStep: Double? = nil,
                           native: String? = nil, target: String? = nil, hasName: Bool? = nil) {
        event("onboarding_step", ["action": action, "step": step, "step_index": index,
                                  "time_on_step_sec": timeOnStep.map { Int($0) },
                                  "native_lang": native, "target_lang": target, "has_name": hasName])
    }

    // MARK: - 2. Paywall
    /// Tek paywall açılışının ortak bilgisi; her paywall olayına eklenir
    final class PaywallVisit {
        let entryPoint: String
        let openedAt = Date()
        let viewIndex: Int
        var maxStep = 0
        var planSwitches = 0
        init(entryPoint: String) {
            self.entryPoint = entryPoint
            let d = UserDefaults.standard
            viewIndex = d.integer(forKey: Track.paywallViewsKey) + 1
            d.set(viewIndex, forKey: Track.paywallViewsKey)
        }
    }

    static let paywallSteps = ["value", "plans", "trial"]

    static func paywall(_ action: String, _ visit: PaywallVisit, step: Int, plan: SubscriptionPlan? = nil,
                        legalDoc: String? = nil, error: String? = nil) {
        visit.maxStep = max(visit.maxStep, step)
        event("paywall_action", [
            "action": action, "entry_point": visit.entryPoint,
            "paywall_step": paywallSteps[min(max(step, 0), paywallSteps.count - 1)], "max_step": visit.maxStep,
            "plan_id": plan?.id, "plan_period": plan.map(period), "price": plan?.product.price,
            "currency": plan?.product.currencyCode, "has_trial": plan.map { $0.trialDays != nil },
            "trial_days": plan?.trialDays, "time_on_paywall_sec": Int(Date().timeIntervalSince(visit.openedAt)),
            "plan_switches": visit.planSwitches, "view_index": visit.viewIndex,
            "legal_doc": legalDoc, "error_code": error,
        ])
    }

    /// GA4'ün önerilen satın alma olayı (gelir raporları); deneme başlangıcında değer 0
    static func purchase(_ plan: SubscriptionPlan, _ visit: PaywallVisit, transactionId: String?) {
        let hasTrial = plan.trialDays != nil
        event(AnalyticsEventPurchase, [
            AnalyticsParameterValue: hasTrial ? 0.0 : NSDecimalNumber(decimal: plan.product.price).doubleValue,
            AnalyticsParameterCurrency: plan.product.currencyCode,
            AnalyticsParameterTransactionID: transactionId,
            "plan_id": plan.id, "plan_period": period(plan), "has_trial": hasTrial, "entry_point": visit.entryPoint,
        ])
        setTier(hasTrial ? "trial" : "pro")
    }

    private static func period(_ plan: SubscriptionPlan) -> String {
        plan.isAnnual ? "annual" : plan.isMonthly ? "monthly" : "weekly"
    }

    // MARK: - 3. Ders
    static func lesson(_ action: String, _ params: [String: Any?]) {
        event("lesson_session", params.merging(["action": action]) { a, _ in a })
    }

    // MARK: - 4. Ders içi özellikler
    static func tutor(_ action: String, mode: String, item: String? = nil) {
        event("tutor_interaction", ["action": action, "mode": mode, "item": item])
    }

    // MARK: - 5. Kelime / quiz
    static func practice(_ action: String, type: String, wordCount: Int? = nil, correct: Int? = nil,
                         total: Int? = nil, duration: Double? = nil, entryPoint: String? = nil) {
        event("practice_session", [
            "action": action, "practice_type": type, "word_count": wordCount, "correct": correct, "total": total,
            "accuracy_pct": total.flatMap { $0 > 0 ? Int(Double(correct ?? 0) / Double($0) * 100) : nil },
            "duration_sec": duration.map { Int($0) }, "entry_point": entryPoint,
        ])
    }

    // MARK: - 6. Dil
    static func language(_ action: String, from: String? = nil, to: String? = nil, entryPoint: String? = nil) {
        event("language_action", ["action": action, "from_lang": from, "to_lang": to, "entry_point": entryPoint])
        if action == "switch" || action == "add_complete" || action == "ui_change" { refreshUser(force: true) }
    }

    // MARK: - 7. Ekran
    static func screen(_ name: String) {
        event(AnalyticsEventScreenView, [AnalyticsParameterScreenName: name, AnalyticsParameterScreenClass: name])
    }
}
