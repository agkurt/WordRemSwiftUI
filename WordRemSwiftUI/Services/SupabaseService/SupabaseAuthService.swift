//
//  SupabaseAuthService.swift
//  WordRemSwiftUI
//
//  Auth layer — wraps Supabase Auth calls.
//  Replaces the Firebase-based methods in FirebaseService and AuthManager.
//

import Foundation
import Supabase

final class SupabaseAuthService {

    static let shared = SupabaseAuthService()
    private var client: SupabaseClient { SupabaseService.shared.client }

    private init() {}

    // MARK: - Register
    func registerUser(username: String, email: String, password: String) async throws {
        _ = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["username": .string(username)]
        )
        // After sign-up Supabase triggers a confirmation e-mail by default.
        // If e-mail confirmation is disabled in the dashboard, the user is
        // immediately signed in at this point.
    }

    // MARK: - Login (email + password)
    func loginUser(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    // MARK: - Sign Out
    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Apple Sign-In
    /// Call this after receiving the identity token from ASAuthorizationAppleIDCredential.
    func signInWithApple(idToken: String, nonce: String) async throws {
        _ = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    // MARK: - Google Sign-In
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        _ = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }

    // MARK: - Anonymous Sign-In (native Supabase — no email sent)
    func signInAnonymously() async throws {
        _ = try await client.auth.signInAnonymously()
    }


    var isSignedIn: Bool {
        client.auth.currentSession != nil
    }

    var currentUserId: UUID? {
        client.auth.currentSession?.user.id
    }

    var isCurrentUserAnonymous: Bool {
        client.auth.currentSession?.user.isAnonymous ?? true
    }

    // MARK: - Ensure user row in public.users
    /// Called once right after successful sign-in / sign-up.
    /// ignoreDuplicates: true → mevcut kullanıcının username'ini asla ezmez,
    /// sadece DB'de satır yoksa yeni satır ekler.
    func ensureUserRow(username: String) async throws {
        guard let uid = currentUserId else { return }

        struct UserInsert: Encodable {
            let id: UUID
            let username: String
        }
        try await SupabaseService.shared.client
            .from("users")
            .upsert(UserInsert(id: uid, username: username),
                    onConflict: "id",
                    ignoreDuplicates: true)
            .execute()
    }

    // MARK: - Update FCM token
    func updateFCMToken(_ token: String) async throws {
        guard let uid = currentUserId else { return }
        struct TokenUpdate: Encodable { let fcm_token: String }
        try await SupabaseService.shared.client
            .from("users")
            .update(TokenUpdate(fcm_token: token))
            .eq("id", value: uid.uuidString)
            .execute()
    }

    // MARK: - Auth State Changes
    /// Returns an AsyncStream that emits (event, session?) on every change.
    func authStateStream() -> AsyncStream<(AuthChangeEvent, Session?)> {
        AsyncStream { continuation in
            Task {
                for await (event, session) in await client.auth.authStateChanges {
                    continuation.yield((event, session))
                }
            }
        }
    }
}
