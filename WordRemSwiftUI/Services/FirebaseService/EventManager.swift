//
//  EventManager.swift
//  WordRemSwiftUI
//

import Foundation
import FirebaseAnalytics

final class EventManager {
    static let shared = EventManager()
    
    private init() {}
    
    func logRegisterEvent() {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: "email"
        ])
        print("📊 [Analytics] sign_up event fired ✅")
    }
    
    // MARK: - Login Event
    func logLoginEvent(method: String = "email") {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
        print("📊 [Analytics] login event fired ✅ (Method: \(method))")
    }
    
    // MARK: - Logout Event
    func logLogoutEvent() {
        Analytics.logEvent("logout", parameters: nil)
        print("📊 [Analytics] logout event fired ✅")
    }

    // MARK: - Paywall Events
    func logPaywallEvent(_ name: String) {
        Analytics.logEvent("paywall_\(name)", parameters: nil)
        print("📊 [Analytics] paywall_\(name) ✅")
    }
}
