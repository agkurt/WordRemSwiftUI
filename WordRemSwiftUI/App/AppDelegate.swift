//
//  AppDelegate.swift
//  WordRemSwiftUI
//
//  Sunucu/analitik SDK'sı yok. Yalnızca abonelikler (RevenueCat) ve yerel bildirimler.
//

import SwiftUI
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in SmartReminders.registerCategories() }
        InAppPurchaseManager.configure(apiKey: "appl_AIYIRTwVqPvcdVpfrGdzmqAYbox")
        #if DEBUG
        voiceLog.info("device id \(DeviceIdentity.id.prefix(8), privacy: .public)")
        #endif
        Track.configure()   // RevenueCat'ten sonra: user_id olarak onun kimliği kullanılır
        return true
    }

    // Uygulama açıkken gelen yerel bildirimleri de göster
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    // Bildirim düğmeleri (Hatırladım / Hatırlamadım) ve dokunma → ilgili ekran
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            await SmartReminders.handle(response)
            completionHandler()
        }
    }
}
