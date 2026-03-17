//
//  AuthManager.swift
//  WordRemSwiftUI
//
//  Migrated to Supabase Auth. Still publishes the same userIsLoggedIn /
//  authState surface so all existing SwiftUI views continue to work
//  without changes.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import GoogleSignIn

class AuthManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {

    @Published var authState = AuthState.signedOut
    @Published var userIsLoggedIn = false

    // Nonce for Apple Sign-In
    var currentNonce: String?

    override init() {
        super.init()
        // Reflect current session immediately
        userIsLoggedIn = SupabaseAuthService.shared.isSignedIn
        if userIsLoggedIn { authState = .signedIn }

        // Start listening for auth state changes
        Task { await listenToAuthChanges() }
    }

    // MARK: - Auth State Listener
    private func listenToAuthChanges() async {
        for await (event, session) in SupabaseAuthService.shared.authStateStream() {
            await MainActor.run {
                switch event {
                case .signedIn:
                    self.userIsLoggedIn = true
                    self.authState = .signedIn
                    // Flush pending FCM token
                    if let token = UserDefaults.standard.string(forKey: "pendingFCMToken") {
                        Task {
                            try? await SupabaseAuthService.shared.updateFCMToken(token)
                            UserDefaults.standard.removeObject(forKey: "pendingFCMToken")
                        }
                    }
                case .signedOut:
                    self.userIsLoggedIn = false
                    self.authState = .signedOut
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        let uid = SupabaseAuthService.shared.currentUserId?.uuidString
        Task {
            do {
                try await SupabaseAuthService.shared.signOut()
                await MainActor.run {
                    self.userIsLoggedIn = false
                    self.authState = .signedOut
                }
                EventManager.shared.logLogoutEvent()
                if let uid = uid {
                    await NotificationService.shared.scheduleLogoutNotification(uid: uid)
                }
            } catch {
                print("❌ Sign-out error: \(error)")
            }
        }
    }

    // MARK: - Anonymous Sign-In (forwarded to LoginScreenViewModel)
    func signInAnonymously() async throws {
        let tempEmail = "anon_\(UUID().uuidString)@wordrem.local"
        let tempPassword = UUID().uuidString
        try await SupabaseAuthService.shared.registerUser(
            username: "Guest", email: tempEmail, password: tempPassword
        )
    }

    // MARK: - Apple Sign-In (ASAuthorizationControllerDelegate)
    func handleAppleLogin() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = appleCredential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else { return }

        Task {
            do {
                try await SupabaseAuthService.shared.signInWithApple(
                    idToken: idToken, nonce: nonce
                )
                let name = [
                    appleCredential.fullName?.givenName,
                    appleCredential.fullName?.familyName
                ].compactMap { $0 }.joined(separator: " ")
                try await SupabaseAuthService.shared.ensureUserRow(
                    username: name.isEmpty ? "Apple User" : name
                )
                EventManager.shared.logLoginEvent(method: "apple")
            } catch {
                print("❌ Apple sign-in error: \(error)")
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple sign-in error: \(error)")
    }

    // MARK: - Google Sign-In (call from UIViewController)
    func handleGoogleSignIn(with viewController: UIViewController) {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String
                ?? (Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
                    .flatMap { NSDictionary(contentsOfFile: $0)?["CLIENT_ID"] as? String})
        else {
            print("❌ Google client ID not found")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signResult, error in
            if let error {
                print("❌ Google sign-in error: \(error)")
                return
            }
            guard let user = signResult?.user, let idToken = user.idToken else { return }

            Task {
                do {
                    try await SupabaseAuthService.shared.signInWithGoogle(
                        idToken: idToken.tokenString,
                        accessToken: user.accessToken.tokenString
                    )
                    let name = user.profile?.name ?? "Google User"
                    try await SupabaseAuthService.shared.ensureUserRow(username: name)
                    EventManager.shared.logLoginEvent(method: "google")
                } catch {
                    print("❌ Supabase Google sign-in error: \(error)")
                }
            }
        }
    }

    func handleGoogleSignIn(idToken: String, accessToken: String) {
        Task {
            do {
                try await SupabaseAuthService.shared.signInWithGoogle(
                    idToken: idToken, accessToken: accessToken
                )
                try await SupabaseAuthService.shared.ensureUserRow(username: "Google User")
                EventManager.shared.logLoginEvent(method: "google")
            } catch {
                print("❌ Google sign-in error: \(error)")
            }
        }
    }

    // MARK: - Crypto helpers
    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var r: UInt8 = 0
                SecRandomCopyBytes(kSecRandomDefault, 1, &r)
                return r
            }
            randoms.forEach { r in
                guard remaining > 0 else { return }
                if r < charset.count { result.append(charset[Int(r)]); remaining -= 1 }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
