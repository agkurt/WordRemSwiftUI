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
    @Published var loginError: String?
    @Published var isAnonymous: Bool = true

    /// Login sonrası MainTabView'da gösterilecek popup türü.
    /// MainTabView bunu consume edip nil'e çeker.
    @Published var pendingWelcome: WelcomePopupType? = nil

    // Nonce for Apple Sign-In
    var currentNonce: String?

    override init() {
        super.init()
        // Reflect current session immediately
        userIsLoggedIn = SupabaseAuthService.shared.isSignedIn
        isAnonymous = SupabaseAuthService.shared.isCurrentUserAnonymous
        if userIsLoggedIn { authState = .signedIn }

        // Start listening for auth state changes
        Task { await listenToAuthChanges() }
    }

    // MARK: - Auth State Listener
    private func listenToAuthChanges() async {
        for await (event, session) in SupabaseAuthService.shared.authStateStream() {
            await MainActor.run {
                switch event {
                case .initialSession:
                    // Uygulama açılışında Keychain'den session restore edilirse navigate et.
                    // session nil ise (no stored session) — hiçbir şey yapma, userIsLoggedIn false kalır.
                    guard let session = session else { break }
                    self.userIsLoggedIn = true
                    self.authState = .signedIn
                    self.isAnonymous = session.user.isAnonymous
                    EventManager.shared.setAnalyticsUserID(session.user.id.uuidString)
                    if !session.user.isAnonymous {
                        Task { await self.checkAndRestoreOnboardingState(userId: session.user.id) }
                    }
                    if let token = UserDefaults.standard.string(forKey: "pendingFCMToken") {
                        Task {
                            try? await SupabaseAuthService.shared.updateFCMToken(token)
                            UserDefaults.standard.removeObject(forKey: "pendingFCMToken")
                        }
                    }

                case .signedIn:
                    // Navigation, explicit sign-in fonksiyonları tarafından yönetiliyor.
                    // Stream sadece isAnonymous + analytics günceller.
                    // signedOut → signedIn geçişleri (OAuth flow) burada userIsLoggedIn'i
                    // sıfırlamaz; explicit çağrılar zaten true yaptı.
                    self.isAnonymous = session?.user.isAnonymous ?? false
                    if let uid = session?.user.id.uuidString {
                        EventManager.shared.setAnalyticsUserID(uid)
                    }
                    if let token = UserDefaults.standard.string(forKey: "pendingFCMToken") {
                        Task {
                            try? await SupabaseAuthService.shared.updateFCMToken(token)
                            UserDefaults.standard.removeObject(forKey: "pendingFCMToken")
                        }
                    }

                case .signedOut:
                    // Sadece analytics temizle. userIsLoggedIn = false SADECE explicit
                    // signOut() çağrısından gelir. OAuth flow'ları sırasında da bu event
                    // tetiklenebilir; navigation'ı bozmamak için burada false yapma.
                    self.isAnonymous = true
                    EventManager.shared.setAnalyticsUserID(nil)

                default:
                    break
                }
            }
        }
    }

    // Returning user'da target_lang_id varsa onboarding'i atla
    private func checkAndRestoreOnboardingState(userId: UUID) async {
        do {
            struct LangCheck: Decodable { let target_lang_id: Int? }
            let result = try await SupabaseService.shared.client
                .from("users")
                .select("target_lang_id")
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
            let rows = try JSONDecoder().decode([LangCheck].self, from: result.data)
            if let first = rows.first, first.target_lang_id != nil {
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
            }
        } catch {
            print("⚠️ checkAndRestoreOnboardingState: \(error)")
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
                    self.isAnonymous = true
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
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

    // MARK: - Anonymous Sign-In
    func signInAnonymously() async throws {
        if SupabaseAuthService.shared.isSignedIn {
            await MainActor.run {
                self.userIsLoggedIn = true
                self.authState = .signedIn
                self.isAnonymous = SupabaseAuthService.shared.isCurrentUserAnonymous
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
            print("ℹ️ Session restored → navigating to app")
            return
        }
        try await SupabaseAuthService.shared.signInAnonymously()
        let randomNum = Int.random(in: 1000...9999)
        let guestName = "Guest-\(randomNum)"
        try await SupabaseAuthService.shared.ensureUserRow(username: guestName)
        let anonId = SupabaseAuthService.shared.currentUserId?.uuidString ?? ""
        await MainActor.run {
            self.pendingWelcome = self.resolveWelcomeType(userId: anonId, name: guestName)
            self.userIsLoggedIn = true
            self.authState = .signedIn
            self.isAnonymous = true
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        EventManager.shared.logLoginEvent(method: "anonymous")
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
                let resolvedName = name.isEmpty ? "Apple User" : name
                try await SupabaseAuthService.shared.ensureUserRow(username: resolvedName)
                let appleId = SupabaseAuthService.shared.currentUserId?.uuidString ?? ""
                await MainActor.run {
                    self.pendingWelcome = self.resolveWelcomeType(userId: appleId, name: resolvedName)
                    self.userIsLoggedIn = true
                    self.authState = .signedIn
                    self.isAnonymous = false
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
                EventManager.shared.logLoginEvent(method: "apple")
            } catch {
                await MainActor.run { self.loginError = error.localizedDescription }
                print("❌ Apple sign-in error: \(error)")
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Kullanıcı iptal ettiyse sessiz çık, gerçek hatalarda UI'ı bilgilendir
        let code = (error as? ASAuthorizationError)?.code
        guard code != .canceled else { return }
        loginError = error.localizedDescription
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

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] signResult, error in
            if let error {
                let code = (error as NSError).code
                // Kullanıcı iptal ettiyse (code -5) sessiz çık
                if code != -5 {
                    DispatchQueue.main.async { self?.loginError = error.localizedDescription }
                }
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
                    let name = user.profile?.name
                        ?? user.profile?.email.split(separator: "@").first.map(String.init)
                        ?? "Google User"
                    try await SupabaseAuthService.shared.ensureUserRow(username: name)
                    let googleId = SupabaseAuthService.shared.currentUserId?.uuidString ?? ""
                    await MainActor.run {
                        self?.pendingWelcome = self?.resolveWelcomeType(userId: googleId, name: name)
                        self?.userIsLoggedIn = true
                        self?.authState = .signedIn
                        self?.isAnonymous = false
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    }
                    EventManager.shared.logLoginEvent(method: "google")
                } catch {
                    await MainActor.run { self?.loginError = error.localizedDescription }
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
                await MainActor.run {
                    self.userIsLoggedIn = true
                    self.authState = .signedIn
                    self.isAnonymous = false
                }
                EventManager.shared.logLoginEvent(method: "google")
            } catch {
                await MainActor.run { self.loginError = error.localizedDescription }
                print("❌ Google sign-in error: \(error)")
            }
        }
    }

    // MARK: - Welcome Popup Helpers

    /// Kullanıcı ID'sine göre yeni/geri dönen kullanıcı tipini belirler.
    /// Her hesap için UserDefaults'ta ayrı key tutar.
    private func resolveWelcomeType(userId: String, name: String) -> WelcomePopupType {
        let key = "hasSeenWelcome_\(userId)"
        if UserDefaults.standard.bool(forKey: key) {
            return .returning(name: name)
        } else {
            UserDefaults.standard.set(true, forKey: key)
            return .newUser(name: name)
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
