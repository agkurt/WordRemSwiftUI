//
//  LeaderboardViewModel.swift
//  WordRemSwiftUI
//
//  Sıralama ekranı — veriler Game Center'dan gelir.
//

import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {

    @Published var users: [SBUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var specificUserRank: Int?
    @Published var currentUser: SBUser?
    @Published private(set) var currentUserId: UUID?

    var isAuthenticated: Bool { GameCenterService.shared.isAuthenticated }

    func loadLeaderboard() async {
        guard isAuthenticated else { return }
        isLoading = true
        errorMessage = nil
        do {
            let (top, me) = try await GameCenterService.shared.loadTop(limit: 20)
            users = top.map(Self.user)
            currentUser = me.map(Self.user)
            currentUserId = currentUser?.id
            specificUserRank = me?.rank
        } catch is CancellationError {
            // pull-to-refresh iptali — sessiz geç
        } catch {
            if users.isEmpty { errorMessage = error.localizedDescription }
            print("❌ Leaderboard error: \(error)")
        }
        isLoading = false
    }

    func currentUserRank() -> Int? { specificUserRank }

    /// Game Center kaydını mevcut satır görünümünün beklediği modele çevirir
    private static func user(_ e: GameCenterService.Entry) -> SBUser {
        SBUser(id: stableUUID(e.id), username: e.name, displayName: nil, avatarUrl: nil,
               nativeLangId: nil, targetLangId: nil, proficiencyLevel: nil, learningInterest: nil,
               dailyGoalMinutes: nil, totalXp: e.xp, streakDays: 0, lastActivityAt: nil,
               fcmToken: nil, usernameChanges: nil)
    }

    /// gamePlayerID → sabit UUID (aynı oyuncu her yüklemede aynı kimliği alır)
    private static func stableUUID(_ string: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (i, b) in string.utf8.enumerated() { bytes[i % 16] = bytes[i % 16] &* 31 &+ b }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
