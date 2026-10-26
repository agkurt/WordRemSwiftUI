//
//  UserStore.swift
//  WordRemSwiftUI
//
//  Kullanıcının tüm ilerlemesi (XP, seri, seviye durumu, başarımlar, istatistikler)
//  cihazda bir JSON dosyasında tutulur ve iCloud anahtar-değer deposu
//  (NSUbiquitousKeyValueStore) ile aynı Apple hesabındaki cihazlar arasında senkronlanır.
//  Hesap / giriş yok: kimlik = cihazdaki kayıt + kullanıcının iCloud hesabı.
//

import Foundation

struct LevelProgressRecord: Codable, Equatable {
    var status: SBLevelStatus
    var bestScore: Int = 0
    var attempts: Int = 0
    var xpEarned: Int = 0
    var stars: Int = 0
    var completedAt: Date?
    var lastPlayedAt: Date?
}

struct UserState: Codable, Equatable {
    var userId: UUID = UUID()
    var username: String = ""
    var usernameChanges: Int = 0
    var createdAt: Date = Date()
    var totalXp: Int = 0
    var streakDays: Int = 0
    var lastActivityAt: Date?
    var progress: [String: LevelProgressRecord] = [:]   // levelId → kayıt
    var achievements: Set<String> = []
    var totalAnswers: Int = 0
    var correctAnswers: Int = 0
    var updatedAt: Date = Date()

    // Sesli öğretmen (eski kayıtlarda yok → opsiyonel)
    /// Tamamlanan senaryo hedefleri: goalId → tarih
    var voiceGoalsDone: [String: Date]?
    /// AI'ın hatırladığı kalıcı bilgiler ("Adı Ahmet", "İzmir'de yaşıyor", "Hedefi: iş görüşmesi")
    var tutorFacts: [String]?
    /// Son sohbetlerin 1–2 cümlelik özetleri (en yeni sonda, en fazla 10)
    var tutorSummaries: [String]?
    /// Sesli derste kaldığı yer: ders anahtarı → son konuşmalar (geri gelince oradan devam edilir)
    var voiceProgress: [String: VoiceProgress]?
    /// Toplam sesli pratik süresi (saniye)
    var voiceSeconds: Int?
    /// Çalışılan günler ("yyyy-MM-dd"): quiz, ders, sesli sohbet ya da tekrar — tek seri kaynağı
    var studyDays: [String]?
}

final class UserStore {

    static let shared = UserStore()

    /// Arayüzün yeniden okuması için yayınlanır (ör. iCloud'dan yeni veri gelince)
    static let didChangeNotification = Notification.Name("UserStoreDidChange")

    private let queue = DispatchQueue(label: "wordrem.userstore")
    private var state: UserState
    private let fileURL: URL
    private let cloud = NSUbiquitousKeyValueStore.default
    private let cloudKey = "userState.v1"

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("user_state.json")

        let local = (try? Data(contentsOf: fileURL)).flatMap { try? JSONDecoder.iso.decode(UserState.self, from: $0) }
        let remote = cloud.data(forKey: cloudKey).flatMap { try? JSONDecoder.iso.decode(UserState.self, from: $0) }
        switch (local, remote) {
        case let (l?, r?): state = UserStore.merge(l, r)
        case let (l?, nil): state = l
        case let (nil, r?): state = r          // yeni cihaz: iCloud'daki ilerleme geri gelir
        default:            state = UserState()
        }
        persist(pushToCloud: true)

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud, queue: nil
        ) { [weak self] _ in self?.pullFromCloud() }
        cloud.synchronize()
    }

    // MARK: - Read
    var snapshot: UserState { queue.sync { state } }
    var userId: UUID { snapshot.userId }

    // MARK: - Write
    func update(_ change: (inout UserState) -> Void) {
        queue.sync {
            change(&state)
            state.updatedAt = Date()
        }
        persist(pushToCloud: true)
    }

    /// Tüm ilerlemeyi siler (Profil → "İlerlemeyi sıfırla"). iCloud kopyası da silinir.
    func reset() {
        queue.sync { state = UserState() }
        cloud.removeObject(forKey: cloudKey)
        persist(pushToCloud: true)
    }

    // MARK: - Persistence & Sync
    private func persist(pushToCloud: Bool) {
        let current = snapshot
        guard let data = try? JSONEncoder.iso.encode(current) else { return }
        try? data.write(to: fileURL, options: .atomic)
        if pushToCloud { cloud.set(data, forKey: cloudKey) }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: UserStore.didChangeNotification, object: nil)
        }
    }

    private func pullFromCloud() {
        guard let data = cloud.data(forKey: cloudKey),
              let remote = try? JSONDecoder.iso.decode(UserState.self, from: data) else { return }
        queue.sync { state = UserStore.merge(state, remote) }
        persist(pushToCloud: false)
    }

    /// İki cihazın verisini kayıpsız birleştirir: ilerleme/başarım birleşimi, sayaçlarda en büyük değer.
    static func merge(_ a: UserState, _ b: UserState) -> UserState {
        var out = a.updatedAt >= b.updatedAt ? a : b
        let other = a.updatedAt >= b.updatedAt ? b : a
        out.userId = a.createdAt <= b.createdAt ? a.userId : b.userId
        out.createdAt = min(a.createdAt, b.createdAt)
        out.totalXp = max(a.totalXp, b.totalXp)
        out.totalAnswers = max(a.totalAnswers, b.totalAnswers)
        out.correctAnswers = max(a.correctAnswers, b.correctAnswers)
        out.achievements = a.achievements.union(b.achievements)
        out.usernameChanges = max(a.usernameChanges, b.usernameChanges)
        out.voiceGoalsDone = (a.voiceGoalsDone ?? [:]).merging(b.voiceGoalsDone ?? [:]) { min($0, $1) }
        out.voiceSeconds = max(a.voiceSeconds ?? 0, b.voiceSeconds ?? 0)
        out.studyDays = Array(Set((a.studyDays ?? []) + (b.studyDays ?? []))).sorted().suffix(400).map { $0 }
        out.tutorFacts = Array(Array(Set((a.tutorFacts ?? []) + (b.tutorFacts ?? []))).sorted().suffix(30))
        out.voiceProgress = (a.voiceProgress ?? [:]).merging(b.voiceProgress ?? [:]) { $0.updatedAt >= $1.updatedAt ? $0 : $1 }
        for (levelId, theirs) in other.progress {
            guard let mine = out.progress[levelId] else { out.progress[levelId] = theirs; continue }
            out.progress[levelId] = mine.status.rank >= theirs.status.rank
                ? mine.mergedBest(with: theirs) : theirs.mergedBest(with: mine)
        }
        return out
    }
}

private extension SBLevelStatus {
    var rank: Int {
        switch self { case .locked: 0; case .unlocked: 1; case .inProgress: 2; case .completed: 3 }
    }
}

private extension LevelProgressRecord {
    func mergedBest(with other: LevelProgressRecord) -> LevelProgressRecord {
        var r = self
        r.bestScore = max(bestScore, other.bestScore)
        r.stars = max(stars, other.stars)
        r.attempts = max(attempts, other.attempts)
        r.xpEarned = max(xpEarned, other.xpEarned)
        return r
    }
}

extension JSONEncoder {
    static let iso: JSONEncoder = { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }()
}
extension JSONDecoder {
    static let iso: JSONDecoder = { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }()
}

/// Sesli dersin kaydedilmiş hali (son ~10 konuşma satırı)
struct VoiceProgress: Codable, Equatable {
    struct Line: Codable, Equatable {
        let ai: Bool
        let text: String
    }
    var lines: [Line]
    var updatedAt: Date
    /// Tamamlanan ders hedefi sayısı
    var step: Int? = nil
}
