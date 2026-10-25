//
//  GameCenterService.swift
//  WordRemSwiftUI
//
//  Sıralama tablosu Game Center üzerinden (ücretsiz, Apple'ın sunucusu).
//  App Store Connect'te "Toplam XP" adlı, ID'si `leaderboardID` olan
//  klasik (all-time, en yüksek skor) bir leaderboard oluşturulmalı.
//

import GameKit
import UIKit

@MainActor
final class GameCenterService: ObservableObject {

    static let shared = GameCenterService()
    static let leaderboardID = "wordrem.total_xp"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var playerName: String?

    private var didStart = false

    /// Uygulama açılışında bir kez çağrılır. Oturum yoksa Game Center kendi giriş ekranını gösterir.
    func authenticate() {
        guard !didStart else { return }
        didStart = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    Self.topViewController()?.present(viewController, animated: true)
                    return
                }
                if let error { print("ℹ️ Game Center: \(error.localizedDescription)") }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.playerName = self.isAuthenticated ? GKLocalPlayer.local.displayName : nil
                GKAccessPoint.shared.isActive = false
                if self.isAuthenticated { self.submitXP(UserStore.shared.snapshot.totalXp) }
            }
        }
    }

    /// Toplam XP'yi leaderboard'a gönderir (Game Center en yüksek değeri tutar).
    nonisolated func submitXP(_ xp: Int) {
        Task { @MainActor in
            guard GKLocalPlayer.local.isAuthenticated, xp > 0 else { return }
            do {
                try await GKLeaderboard.submitScore(xp, context: 0, player: GKLocalPlayer.local,
                                                    leaderboardIDs: [Self.leaderboardID])
            } catch {
                print("⚠️ Game Center submit: \(error.localizedDescription)")
            }
        }
    }

    struct Entry: Identifiable {
        let id: String
        let rank: Int
        let name: String
        let xp: Int
        let isLocal: Bool
    }

    /// İlk `limit` oyuncu + yerel oyuncunun sırası.
    func loadTop(limit: Int = 20) async throws -> (top: [Entry], me: Entry?) {
        let boards = try await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID])
        guard let board = boards.first else { return ([], nil) }
        let (local, entries, _) = try await board.loadEntries(for: .global, timeScope: .allTime,
                                                              range: NSRange(location: 1, length: limit))
        func map(_ e: GKLeaderboard.Entry) -> Entry {
            Entry(id: e.player.gamePlayerID, rank: e.rank, name: e.player.displayName,
                  xp: e.score, isLocal: e.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID)
        }
        return (entries.map(map), local.map(map))
    }

    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow?.rootViewController
        var top = root
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
