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
            "deviceId": DeviceIdentity.id, "engine": CascadeEngine.isOn ? "cascade" : "realtime",
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

    /// Üç parçalı ses adımları: "stt" (ham PCM), "chat" (akış), "tts" (akış PCM)
    func cascadeRequest(_ step: String, sessionId: String, body: Data, json: Bool = true) -> URLRequest? {
        guard let baseURL, var comps = URLComponents(url: baseURL.appendingPathComponent("v1/voice/cascade/\(step)"), resolvingAgainstBaseURL: false)
        else { return nil }
        comps.queryItems = [URLQueryItem(name: "session", value: sessionId), URLQueryItem(name: "appUserId", value: appUserId)]
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue(appKey, forHTTPHeaderField: "X-App-Key")
        req.setValue(json ? "application/json" : "application/octet-stream", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        return req
    }

    func cascadeData(for req: URLRequest) async throws -> (Data, URLResponse) { try await http.data(for: req) }
    func cascadeBytes(for req: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) { try await http.bytes(for: req) }

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
        if let fresh = FreshUser.id { return fresh }   // Debug test kullanıcısı: yeni ücretsiz deneme süresi
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

// MARK: - Üç parçalı ses (deneme)

/// Mikrofon iş parçacığından gelen ses (kilitli tampon)
final class CascadeAudio: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    func append(_ d: Data) { lock.lock(); data.append(d); lock.unlock() }
    func reset() { lock.lock(); data.removeAll(keepingCapacity: true); lock.unlock() }
    func take() -> Data { lock.lock(); defer { data = Data(); lock.unlock() }; return data }
}

/// Gerçek zamanlı ses modeli yerine: konuşmayı yazıya çevir → yazı modeli → cümle cümle seslendir.
/// RealtimeVoiceSession'ın gönderdiği olayları alır, aynı olayları geri üretir; ders akışı hiç değişmez.
@MainActor
final class CascadeEngine {
    /// Debug sürümünde varsayılan açık (Profil'den kapatılabilir); TestFlight/App Store'da kapalı
    nonisolated static var isOn: Bool {
        #if DEBUG
        !UserDefaults.standard.bool(forKey: "voiceCascadeOff")
        #else
        false
        #endif
    }

    let audio = CascadeAudio()
    private let sessionId: String
    private let sessionTools: [[String: Any]]
    private let deliver: ([String: Any]) -> Void
    private var messages: [[String: Any]] = []
    private var sttTask: Task<Void, Never>?
    private var responseTask: Task<Void, Never>?
    private var releasedAt: Date?
    private var closed = false

    init(sessionId: String, tools: [[String: Any]], deliver: @escaping ([String: Any]) -> Void) {
        self.sessionId = sessionId
        self.sessionTools = tools
        self.deliver = deliver
    }

    func start() { deliver(["type": "session.created"]) }

    func close() {
        closed = true
        sttTask?.cancel(); responseTask?.cancel()
    }

    func handle(_ e: [String: Any]) {
        guard !closed else { return }
        switch e["type"] as? String ?? "" {
        case "input_audio_buffer.clear": audio.reset()
        case "input_audio_buffer.commit": commit()
        case "conversation.item.create": add(e["item"] as? [String: Any] ?? [:])
        case "response.create": respond(e["response"] as? [String: Any] ?? [:])
        case "response.cancel": responseTask?.cancel(); responseTask = nil
        default: break
        }
    }

    // MARK: Konuşmayı yazıya çevir
    private func commit() {
        let pcm = audio.take()
        releasedAt = Date()
        let started = Date()
        sttTask = Task { [weak self] in
            guard let self else { return }
            var transcript = ""
            if pcm.count >= 4800, let req = VoiceBackend.shared.cascadeRequest("stt", sessionId: self.sessionId, body: pcm, json: false) {
                do {
                    let (data, resp) = try await VoiceBackend.shared.cascadeData(for: req)
                    let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    if status == 200 {
                        transcript = ((try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["transcript"] as? String) ?? ""
                    } else {
                        voiceLog.error("cascade stt \(status, privacy: .public): \(String(data: data.prefix(300), encoding: .utf8) ?? "", privacy: .public)")
                    }
                } catch { voiceLog.error("cascade stt failed: \(error.localizedDescription, privacy: .public)") }
            }
            guard !Task.isCancelled, !self.closed else { return }
            voiceLog.info("cascade timing stt=\(Int(Date().timeIntervalSince(started) * 1000), privacy: .public)ms (\(pcm.count / 48, privacy: .public)ms audio)")
            let t = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { self.messages.append(["role": "user", "content": t]) }
            self.deliver(["type": "conversation.item.input_audio_transcription.completed", "transcript": t])
        }
    }

    private func add(_ item: [String: Any]) {
        switch item["type"] as? String {
        case "message":
            let role = item["role"] as? String ?? "user"
            let text = (item["content"] as? [[String: Any]] ?? []).compactMap { $0["text"] as? String }.joined(separator: "\n")
            guard !text.isEmpty else { return }
            messages.append(["role": role == "assistant" ? "assistant" : role == "system" ? "system" : "user", "content": text])
        case "function_call_output":
            messages.append(["role": "tool", "tool_call_id": item["call_id"] as? String ?? "", "content": item["output"] as? String ?? "ok"])
        default: break
        }
    }

    /// Yazı modeli her araç çağrısının cevabını hemen arkasında ister: eksikse "ok" eklenir, sahipsiz cevap atılır
    private func sanitized() -> [[String: Any]] {
        var out: [[String: Any]] = []
        var used = Set<Int>()
        for (i, m) in messages.enumerated() where !used.contains(i) {
            if m["role"] as? String == "tool" { continue }
            out.append(m)
            guard let calls = m["tool_calls"] as? [[String: Any]] else { continue }
            for call in calls {
                let id = call["id"] as? String ?? ""
                if let j = messages.indices.first(where: { $0 > i && !used.contains($0) && messages[$0]["role"] as? String == "tool" && messages[$0]["tool_call_id"] as? String == id }) {
                    used.insert(j); out.append(messages[j])
                } else {
                    out.append(["role": "tool", "tool_call_id": id, "content": "ok"])
                }
            }
        }
        return out
    }

    // MARK: Cevap: yazı modeli akışı + cümle cümle seslendirme
    private func respond(_ opts: [String: Any]) {
        responseTask?.cancel()
        responseTask = Task { [weak self] in await self?.run(opts) }
    }

    private func run(_ opts: [String: Any]) async {
        await sttTask?.value
        guard !Task.isCancelled, !closed else { return }
        let started = Date()
        let textOnly = (opts["output_modalities"] as? [String]) == ["text"]
        let realtimeTools = opts["tools"] as? [[String: Any]] ?? sessionTools
        let tools: [[String: Any]] = realtimeTools.map { t in
            ["type": "function", "function": ["name": t["name"] ?? "", "description": t["description"] ?? "", "parameters": t["parameters"] ?? [:]]]
        }
        var body: [String: Any] = ["messages": sanitized(), "tools": tools, "tool_choice": opts["tool_choice"] ?? "auto"]
        if let instr = opts["instructions"] as? String { body["instructions"] = instr }
        guard let payload = try? JSONSerialization.data(withJSONObject: body),
              let req = VoiceBackend.shared.cascadeRequest("chat", sessionId: sessionId, body: payload) else { return }

        deliver(["type": "response.created"])
        var text = ""
        var pending = ""
        var calls: [Int: (id: String, name: String, args: String)] = [:]
        var firstText: Date?
        var spokeAny = false
        let speech = SpeechQueue(sessionId: sessionId, deliver: deliver, enabled: !textOnly)
        do {
            let (bytes, resp) = try await VoiceBackend.shared.cascadeBytes(for: req)
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if status != 200 {
                var err = Data()
                for try await b in bytes { err.append(b); if err.count > 600 { break } }
                voiceLog.error("cascade chat \(status, privacy: .public): \(String(data: err, encoding: .utf8) ?? "", privacy: .public)")
            } else {
                for try await line in bytes.lines {
                    if Task.isCancelled { speech.cancel(); return }
                    guard line.hasPrefix("data: "), line != "data: [DONE]",
                          let obj = try? JSONSerialization.jsonObject(with: Data(line.dropFirst(6).utf8)) as? [String: Any],
                          let delta = ((obj["choices"] as? [[String: Any]])?.first)?["delta"] as? [String: Any] else { continue }
                    if let d = delta["content"] as? String, !d.isEmpty {
                        let clean = d.replacingOccurrences(of: "*", with: "").replacingOccurrences(of: "#", with: "")
                        if firstText == nil {
                            firstText = Date()
                            voiceLog.info("cascade timing llm_first=\(Int(Date().timeIntervalSince(started) * 1000), privacy: .public)ms")
                        }
                        text += clean; pending += clean
                        deliver(["type": "response.output_audio_transcript.delta", "delta": clean])
                        // Bitmiş cümleyi hemen seslendirmeye gönder (ilk ses için tüm cevabı bekleme);
                        // ilk parça virgülde de kesilir ki ses daha erken başlasın
                        while let r = pending.range(of: spokeAny ? #"[.!?…](["”»')]*)\s"# : #"[.!?…,;:](["”»')]*)\s"#, options: .regularExpression),
                              pending.distance(from: pending.startIndex, to: r.upperBound) >= (spokeAny ? 8 : 12) {
                            speech.add(String(pending[..<r.upperBound]))
                            pending = String(pending[r.upperBound...])
                            spokeAny = true
                        }
                    }
                    for tc in delta["tool_calls"] as? [[String: Any]] ?? [] {
                        let i = tc["index"] as? Int ?? 0
                        var c = calls[i] ?? ("", "", "")
                        if let id = tc["id"] as? String { c.id = id }
                        if let f = tc["function"] as? [String: Any] {
                            if let n = f["name"] as? String { c.name += n }
                            if let a = f["arguments"] as? String { c.args += a }
                        }
                        calls[i] = c
                    }
                }
            }
        } catch {
            if Task.isCancelled { speech.cancel(); return }
            voiceLog.error("cascade chat failed: \(error.localizedDescription, privacy: .public)")
        }
        guard !Task.isCancelled, !closed else { speech.cancel(); return }
        if !pending.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { speech.add(pending) }
        speech.finish()

        let ordered = calls.keys.sorted().compactMap { calls[$0] }
        var assistant: [String: Any] = ["role": "assistant", "content": text.isEmpty ? NSNull() : text]
        if !ordered.isEmpty {
            assistant["tool_calls"] = ordered.map { ["id": $0.id, "type": "function", "function": ["name": $0.name, "arguments": $0.args]] }
        }
        if !text.isEmpty || !ordered.isEmpty { messages.append(assistant) }
        for c in ordered {
            deliver(["type": "response.function_call_arguments.done", "name": c.name, "call_id": c.id, "arguments": c.args])
        }
        await speech.done()
        guard !Task.isCancelled, !closed else { return }
        if let first = speech.firstAudioAt {
            let total = releasedAt.map { Int(first.timeIntervalSince($0) * 1000) } ?? -1
            voiceLog.info("cascade timing first_audio=\(Int(first.timeIntervalSince(started) * 1000), privacy: .public)ms after request, release→voice=\(total, privacy: .public)ms")
        }
        releasedAt = nil
        if !textOnly { deliver(["type": "response.output_audio.done"]) }
        deliver(["type": "response.done", "response": ["status": "completed"]])
    }
}

/// Cümleleri sırayla seslendirir; ses geldikçe parça parça (0,1 sn) oynatıcıya verilir
@MainActor
final class SpeechQueue {
    private let sessionId: String
    private let deliver: ([String: Any]) -> Void
    private let enabled: Bool
    private var continuation: AsyncStream<String>.Continuation?
    private var worker: Task<Void, Never>?
    private(set) var firstAudioAt: Date?

    init(sessionId: String, deliver: @escaping ([String: Any]) -> Void, enabled: Bool) {
        self.sessionId = sessionId
        self.deliver = deliver
        self.enabled = enabled
        let (stream, cont) = AsyncStream<String>.makeStream()
        continuation = cont
        worker = Task { [weak self] in
            for await sentence in stream {
                guard let self, !Task.isCancelled else { return }
                await self.speak(sentence)
            }
        }
    }

    func add(_ sentence: String) {
        let s = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard enabled, !s.isEmpty else { return }
        continuation?.yield(s)
    }
    func finish() { continuation?.finish() }
    func cancel() { continuation?.finish(); worker?.cancel() }
    func done() async { await worker?.value }

    private func speak(_ sentence: String) async {
        guard let body = try? JSONSerialization.data(withJSONObject: ["text": sentence]),
              let req = VoiceBackend.shared.cascadeRequest("tts", sessionId: sessionId, body: body) else { return }
        do {
            let (bytes, resp) = try await VoiceBackend.shared.cascadeBytes(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
                voiceLog.error("cascade tts \((resp as? HTTPURLResponse)?.statusCode ?? 0, privacy: .public)")
                return
            }
            var chunk = Data()
            chunk.reserveCapacity(9600)
            for try await b in bytes {
                if Task.isCancelled { return }
                chunk.append(b)
                if chunk.count >= 4800 {
                    if firstAudioAt == nil { firstAudioAt = Date() }
                    deliver(["type": "response.output_audio.delta", "delta": chunk.base64EncodedString()])
                    chunk.removeAll(keepingCapacity: true)
                }
            }
            if chunk.count >= 2 {
                if chunk.count % 2 == 1 { chunk.removeLast() }
                if firstAudioAt == nil { firstAudioAt = Date() }
                deliver(["type": "response.output_audio.delta", "delta": chunk.base64EncodedString()])
            }
        } catch {
            if !Task.isCancelled { voiceLog.error("cascade tts failed: \(error.localizedDescription, privacy: .public)") }
        }
    }
}
