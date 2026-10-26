//
//  VoiceBackend.swift
//  WordRemSwiftUI
//
//  Sesli öğretmen sunucusu (server/voice-worker) istemcisi.
//  Adres ve uygulama anahtarı Info.plist'ten okunur: VoiceAPIBaseURL, VoiceAppKey.
//

import Foundation
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

    private var baseURL: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "VoiceAPIBaseURL") as? String)
            .flatMap { $0.isEmpty || $0.contains("REPLACE") ? nil : URL(string: $0) }
    }
    private var appKey: String { Bundle.main.object(forInfoDictionaryKey: "VoiceAppKey") as? String ?? "" }

    var isConfigured: Bool { baseURL != nil }

    private var appUserId: String { Purchases.isConfigured ? Purchases.shared.appUserID : UserStore.shared.userId.uuidString }

    /// Ses hızı hep doğal (yapay yavaşlatma sesi bulanıklaştırıyor); yavaşlık talimatla sağlanır
    private var speechSpeed: Double { 1.0 }

    func createSession(instructions: String, tools: [[String: Any]]) async throws -> Grant {
        guard let baseURL else { throw Failure(code: "not_configured", remainingSeconds: nil) }
        var req = URLRequest(url: baseURL.appendingPathComponent("v1/voice/session"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        req.timeoutInterval = 15
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "appUserId": appUserId, "instructions": instructions, "tools": tools, "speed": speechSpeed,
        ])
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 { return try JSONDecoder().decode(Grant.self, from: data) }
        let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        throw Failure(code: body["error"] as? String ?? "network", remainingSeconds: body["remainingSeconds"] as? Int)
    }

    // MARK: - Zincirleme öğretmen (cihazda ses tanıma → metin modeli → aynı sesle seslendirme)

    /// Modelin bir turda döndürdüğü paket
    struct TutorReply: Decodable {
        let say: String
        let cardPhrase: String
        let cardTranslation: String
        let usedReviewWords: [String]
        let newFacts: [String]
        let lessonComplete: Bool
        let summary: String

        enum CodingKeys: String, CodingKey {
            case say, summary
            case cardPhrase = "card_phrase", cardTranslation = "card_translation"
            case usedReviewWords = "used_review_words", newFacts = "new_facts", lessonComplete = "lesson_complete"
        }
    }

    enum TurnEvent {
        case reply(TutorReply, remainingSeconds: Int)
        /// 24 kHz, 16-bit, mono PCM parçası
        case audio(Data)
    }

    /// Tek istekte önce cevap paketi, ardından akan ses: [4 bayt uzunluk][JSON][PCM…]
    func tutorTurn(instructions: String, history: [(ai: Bool, text: String)], userText: String?) -> AsyncThrowingStream<TurnEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached { [baseURL, appKey, appUserId] in
                do {
                    guard let baseURL,
                          var comps = URLComponents(url: baseURL.appendingPathComponent("v1/tutor/turn"), resolvingAgainstBaseURL: false)
                    else { throw Failure(code: "not_configured", remainingSeconds: nil) }
                    comps.queryItems = [URLQueryItem(name: "audio", value: "pcm")]
                    var req = URLRequest(url: comps.url!)
                    req.httpMethod = "POST"
                    req.timeoutInterval = 30
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
                    req.httpBody = try JSONSerialization.data(withJSONObject: [
                        "appUserId": appUserId,
                        "instructions": instructions,
                        "history": history.suffix(20).map { ["role": $0.ai ? "assistant" : "user", "content": $0.text] },
                        "userText": userText ?? "",
                    ] as [String: Any])

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    guard status == 200 else {
                        var body = Data()
                        for try await b in bytes { body.append(b) }
                        let obj = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
                        throw Failure(code: obj["error"] as? String ?? "network", remainingSeconds: obj["remainingSeconds"] as? Int)
                    }

                    var lengthBytes = Data(), header = Data(), chunk = Data()
                    var headerLength: Int?
                    for try await b in bytes {
                        guard let need = headerLength else {
                            lengthBytes.append(b)
                            if lengthBytes.count == 4 { headerLength = lengthBytes.reduce(0) { $0 << 8 | Int($1) } }
                            continue
                        }
                        if header.count < need {
                            header.append(b)
                            if header.count == need {
                                struct Meta: Decodable { let reply: TutorReply; let remainingSeconds: Int }
                                let meta = try JSONDecoder().decode(Meta.self, from: header)
                                continuation.yield(.reply(meta.reply, remainingSeconds: meta.remainingSeconds))
                            }
                            continue
                        }
                        chunk.append(b)
                        if chunk.count >= 9_600 {          // ~0.2 sn ses
                            continuation.yield(.audio(chunk))
                            chunk = Data()
                        }
                    }
                    if chunk.count >= 2 { continuation.yield(.audio(chunk.prefix(chunk.count & ~1))) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Öğretmenin sesiyle kısa seslendirme (MP3) — onboarding karşılaması için
    func speech(_ text: String) async throws -> Data {
        guard let baseURL else { throw Failure(code: "not_configured", remainingSeconds: nil) }
        var req = URLRequest(url: baseURL.appendingPathComponent("v1/voice/tts"))
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["appUserId": appUserId, "text": text])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw Failure(code: "network", remainingSeconds: nil) }
        return data
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
        _ = try? await URLSession.shared.data(for: req)
    }

    func status() async -> Status? {
        guard let baseURL,
              var comps = URLComponents(url: baseURL.appendingPathComponent("v1/voice/status"), resolvingAgainstBaseURL: false)
        else { return nil }
        comps.queryItems = [URLQueryItem(name: "appUserId", value: appUserId)]
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return try? JSONDecoder().decode(Status.self, from: data)
    }
}
