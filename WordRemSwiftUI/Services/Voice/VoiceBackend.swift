//
//  VoiceBackend.swift
//  WordRemSwiftUI
//
//  Sesli öğretmen sunucusu (server/voice-worker) istemcisi.
//  Adres ve uygulama anahtarı Info.plist'ten okunur: VoiceAPIBaseURL, VoiceAppKey.
//

import Foundation
import Security
import AVFoundation
import RevenueCat

final class VoiceBackend {

    static let shared = VoiceBackend()

    struct Grant: Decodable {
        let sessionId: String
        let clientSecret: String
        let model: String
        let allowedSeconds: Int
        let tier: String
    }

    struct Status: Decodable {
        let tier: String
        let remainingSeconds: Int
    }

    /// code: "paywall" (ücretsiz deneme bitti) · "limit_reached" (günlük/aylık sınır) · "not_configured" · "network"
    struct Failure: Error {
        let code: String
        let remainingSeconds: Int?
    }

    private var primaryURL: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "VoiceAPIBaseURL") as? String)
            .flatMap { $0.isEmpty || $0.contains("REPLACE") ? nil : URL(string: $0) }
    }
    /// Kendi alan adımıza ulaşılamazsa eski adres (aynı sunucu)
    private let fallbackURL = URL(string: "https://wordrem-voice.wordrem-ai.workers.dev")
    private var usingFallback = false
    private var baseURL: URL? { usingFallback ? fallbackURL : primaryURL }

    /// Ağ hatasında (sunucu cevabı değil) bir kez diğer adresi dener; çalışan adres sonraki isteklerde kullanılır
    private func send(_ make: (URL) throws -> URLRequest) async throws -> (Data, URLResponse) {
        guard let baseURL else { throw Failure(code: "not_configured", remainingSeconds: nil) }
        do {
            return try await http.data(for: make(baseURL))
        } catch let e as URLError where primaryURL != nil && fallbackURL != nil {
            voiceLog.info("backend unreachable (\(e.code.rawValue, privacy: .public)), trying other address")
            usingFallback.toggle()
            do { return try await http.data(for: make(self.baseURL!)) }
            catch { usingFallback.toggle(); throw error }
        }
    }
    private var appKey: String { Bundle.main.object(forInfoDictionaryKey: "VoiceAppKey") as? String ?? "" }

    var isConfigured: Bool { baseURL != nil }

    /// Önbelleksiz, her ağda (mobil veri, Düşük Veri Modu) çalışan oturum; eski bağlantı/HTTP3 durumu taşımaz
    private let http: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.allowsCellularAccess = true
        c.allowsExpensiveNetworkAccess = true
        c.allowsConstrainedNetworkAccess = true
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()
    private(set) var lastBodyBytes = 0

    /// Bağlantı hatasının ayrıntısı + küçük bir isteğin geçip geçmediği (ekranda gösterilir)
    func diagnose(_ error: Error) async -> String {
        let ns = error as NSError
        var s = "\(ns.domain.replacingOccurrences(of: "NSURLErrorDomain", with: "URL")) \(ns.code)"
        if let u = ns.userInfo[NSUnderlyingErrorKey] as? NSError { s += " / \(u.domain) \(u.code)" }
        s += " · \(lastBodyBytes / 1024)KB"
        if let baseURL {
            var r = URLRequest(url: baseURL.appendingPathComponent("privacy"))
            r.timeoutInterval = 8
            do {
                let (_, resp) = try await http.data(for: r)
                s += " · probe \((resp as? HTTPURLResponse)?.statusCode ?? 0)"
            } catch { s += " · probe \((error as NSError).code)" }
        }
        return s
    }

    private var appUserId: String { Purchases.isConfigured ? Purchases.shared.appUserID : UserStore.shared.userId.uuidString }

    /// Ses hızı hep doğal (yapay yavaşlatma sesi bulanıklaştırıyor); yavaşlık talimatla sağlanır
    private var speechSpeed: Double { 1.0 }

    /// quality: "high" → tam model (demo ve dersler), "standard" → mini (serbest sohbet)
    func createSession(instructions: String, tools: [[String: Any]], quality: String = "standard") async throws -> Grant {
        let payload = try JSONSerialization.data(withJSONObject: [
            "appUserId": appUserId, "instructions": instructions, "tools": tools, "speed": speechSpeed, "quality": quality, "metered": true,
            "deviceId": DeviceIdentity.id,
        ])
        lastBodyBytes = payload.count
        let (data, response) = try await send { base in
            var req = URLRequest(url: base.appendingPathComponent("v1/voice/session"))
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(self.appKey, forHTTPHeaderField: "X-App-Key")
            req.timeoutInterval = 15
            req.httpBody = payload
            return req
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 { return try JSONDecoder().decode(Grant.self, from: data) }
        let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        throw Failure(code: body["error"] as? String ?? "network", remainingSeconds: body["remainingSeconds"] as? Int)
    }

    /// Öğretmenin sesiyle kısa seslendirme (MP3) — onboarding karşılaması için
    func speech(_ text: String) async throws -> Data {
        let body = try JSONSerialization.data(withJSONObject: ["appUserId": appUserId, "text": text])
        let (data, response) = try await send { base in
            var req = URLRequest(url: base.appendingPathComponent("v1/voice/tts"))
            req.httpMethod = "POST"
            req.timeoutInterval = 15
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(self.appKey, forHTTPHeaderField: "X-App-Key")
            req.httpBody = body
            return req
        }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw Failure(code: "network", remainingSeconds: nil) }
        return data
    }

    /// Sayaçlı bağlantı: OpenAI anahtarı sunucuda kalır, süreyi sunucu sayar ve dolunca keser
    func meteredRequest(sessionId: String) -> URLRequest? {
        guard let baseURL, var comps = URLComponents(url: baseURL.appendingPathComponent("v1/voice/realtime"), resolvingAgainstBaseURL: false)
        else { return nil }
        comps.scheme = comps.scheme == "http" ? "ws" : "wss"
        comps.queryItems = [URLQueryItem(name: "session", value: sessionId), URLQueryItem(name: "appUserId", value: appUserId)]
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        return req
    }

    /// OpenAI'a sunucu üzerinden bağlanan WebSocket isteği (doğrudan bağlantı kurulamayan ağlar için)
    func relayRequest(model: String, secret: String) -> URLRequest? {
        guard let baseURL, var comps = URLComponents(url: baseURL.appendingPathComponent("v1/voice/realtime"), resolvingAgainstBaseURL: false)
        else { return nil }
        comps.scheme = comps.scheme == "http" ? "ws" : "wss"
        comps.queryItems = [URLQueryItem(name: "model", value: model)]
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        req.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        return req
    }

    func reportUsage(sessionId: String, seconds: Int) async {
        guard let baseURL else { return }
        var req = URLRequest(url: baseURL.appendingPathComponent("v1/voice/usage"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "appUserId": appUserId, "sessionId": sessionId, "seconds": seconds,
        ])
        _ = try? await http.data(for: req)
    }

    func status() async -> Status? {
        guard let baseURL,
              var comps = URLComponents(url: baseURL.appendingPathComponent("v1/voice/status"), resolvingAgainstBaseURL: false)
        else { return nil }
        comps.queryItems = [URLQueryItem(name: "appUserId", value: appUserId), URLQueryItem(name: "deviceId", value: DeviceIdentity.id)]
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        guard let (data, _) = try? await http.data(for: req) else { return nil }
        return try? JSONDecoder().decode(Status.self, from: data)
    }
}

/// Kartlardaki hoparlör: seçenekli kartı ("A / B") iki cümle olarak, "..." boşluğunu okumadan seslendirir.
/// Ses, uygulamanın geri kalanı gibi TTSManager üzerinden öğretmenin sesiyle çalar.
@MainActor
enum TutorVoice {
    static let shared = TutorVoice.self
    static func speak(_ text: String, langCode: String) {
        let line = text.replacingOccurrences(of: " / ", with: ". ").replacingOccurrences(of: "...", with: "…")
        TTSManager.shared.speak(line, langCode: langCode)
    }
}

/// Uygulama silinip yeniden kurulsa da aynı kalan cihaz kimliği (Keychain'de, yalnızca bu cihazda).
/// Sunucu ücretsiz deneme süresini buna bağlar: silip kurmak yeni ücretsiz süre açmaz.
enum DeviceIdentity {
    private static let service = "com.twinflare.WordRemSwiftUI.device"
    private static let account = "device-id"

    static let id: String = {
        if let existing = read() { return existing }
        let new = UUID().uuidString
        save(new)
        voiceLog.info("new device id \(new.prefix(8), privacy: .public)")
        return new
    }()

    private static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func save(_ value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
            // iCloud'a gitmez, başka cihaza taşınmaz
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}
