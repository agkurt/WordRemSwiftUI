//
//  LeaderboardViewModel.swift
//  WordRemSwiftUI
//
//  ViewModel for the Leaderboard screen.
//

import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {

    @Published var users: [SBUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var specificUserRank: Int?
    @Published var currentUser: SBUser?

    var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil
        do {
            users = try await SupabaseDataService.shared.fetchLeaderboard(limit: 50)
            
            // Try to find the user in the top 50
            if let uid = currentUserId, let index = users.firstIndex(where: { $0.id == uid }) {
                specificUserRank = index + 1
                currentUser = users[index]
            } else if let uid = currentUserId {
                // Not in top 50 (or list is empty), fetch specific rank and profile
                specificUserRank = try? await SupabaseDataService.shared.fetchUserRank(userId: uid)
                currentUser = try? await SupabaseDataService.shared.fetchUserProfile()
            }
            
        } catch is CancellationError {
            // Sessizce yut, pull-to-refresh gibi iptallerde hata çıkarma
        } catch {
            if users.isEmpty {
                errorMessage = error.localizedDescription
            }
            print("❌ Leaderboard error: \(error)")
        }
        isLoading = false
    }

    func currentUserRank() -> Int? {
        return specificUserRank
    }
}
