//
//  NotificationService.swift
//  WordRemSwiftUI
//
//  Sends FCM token to our custom backend after successful logout.
//  The backend queues a 15-second delayed "we miss you" push notification.
//

import Foundation
import FirebaseMessaging

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    // ── Change this to your backend URL when deployed ──────────────────────
    // For local testing: http://localhost:3000/api/register
    /// The backend endpoint that handles delayed push notifications
    /// Replace with your actual deployed backend URL
    private let backendRegisterURL = "https://us-central1-wordrem-ce662.cloudfunctions.net/triggerLogoutNotification"
    // ───────────────────────────────────────────────────────────────────────

    /// Called after successful logout.
    /// Fetches the current FCM token and POSTs it to the backend.
    func scheduleLogoutNotification(uid: String) async {
        do {
            let token = try await fetchFCMToken()
            try await postToBackend(fcmToken: token, uid: uid)
            print("✅ Logout notification scheduled for uid: \(uid)")
        } catch {
            print("⚠️ Could not schedule registration notification: \(error)")
            // Non-fatal — app continues normally
        }
    }

    // MARK: - Fetch FCM Token

    private func fetchFCMToken() async throws -> String {
        // If we already have a token cached in Messaging, return it
        if let token = Messaging.messaging().fcmToken {
            return token
        }
        // Otherwise wait for token via continuation
        return try await withCheckedThrowingContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "NotificationService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "FCM token unavailable"]
                    ))
                }
            }
        }
    }

    // MARK: - POST to Backend

    private func postToBackend(fcmToken: String, uid: String) async throws {
        guard let url = URL(string: backendRegisterURL) else {
            throw NSError(domain: "NotificationService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid backend URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let payload: [String: String] = ["fcmToken": fcmToken, "uid": uid]
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NotificationService", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "NotificationService", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Backend error: \(body)"])
        }
    }
}
