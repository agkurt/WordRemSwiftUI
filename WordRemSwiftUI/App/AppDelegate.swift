//
//  AppDelegate.swift
//  WordRemSwiftUI
//
//  Migrated: Firebase init removed; Supabase session is managed by AuthManager.
//  Firebase Messaging (FCM) is kept for push notifications but auth no longer
//  goes through Firebase.
//

import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate,
                   UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🚀 App launch starting")

        // Keep Firebase only for Cloud Messaging (push notifications)
        FirebaseApp.configure()

        // Push notification permission
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error { print("🔔 Notification auth error: \(error)") }
            print("🔔 Notification permission granted: \(granted)")
        }
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        return true
    }

    // MARK: - APNs → FCM token bridge
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // MARK: - FCM token received → save to Supabase
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("📲 FCM token: \(token)")

        Task {
            if SupabaseAuthService.shared.isSignedIn {
                try? await SupabaseAuthService.shared.updateFCMToken(token)
            } else {
                // User not signed in yet — cache it; AuthManager will flush on sign-in
                UserDefaults.standard.set(token, forKey: "pendingFCMToken")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 Notification tapped: \(userInfo)")
        completionHandler()
    }
}
