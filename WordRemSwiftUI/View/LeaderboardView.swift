//
//  LeaderboardView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct LeaderboardView: View {

    @EnvironmentObject var langManager: LanguageManager
    @Binding var selectedTab: AppTab
    @StateObject private var vm = LeaderboardViewModel()
    @ObservedObject private var gameCenter = GameCenterService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                leaderboardHeader

                // Guest kullanıcıya login yönlendirme
                if !gameCenter.isAuthenticated {
                    guestPromptView

                } else if vm.isLoading && vm.users.isEmpty {
                    ProgressView()
                        .tint(DS.Colors.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)

                } else if let err = vm.errorMessage {
                    errorView(err)

                } else if vm.users.isEmpty {
                    emptyView

                } else {
                    // ── Benim Sıram ───────────────────────────
                    if let rank = vm.currentUserRank(), let me = vm.currentUser {
                        BoardOwnRankCard(rank: rank, user: me)
                    }

                    // ── Sıralama (ilk 20) ─────────────────────
                    LazyVStack(spacing: 0) {
                        let top = Array(vm.users.prefix(20).enumerated())
                        ForEach(top, id: \.element.id) { index, user in
                            BoardRankRow(
                                rank: index + 1,
                                user: user,
                                isCurrentUser: user.id == vm.currentUserId
                            )
                            if index < top.count - 1 {
                                Rectangle().fill(DS.Colors.line).frame(height: 1)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        // Sheet içinde aşağı çekmek sayfayı kapatsın diye pull-to-refresh yok; kapatma butonu da var
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.paperSunken, in: Circle())
            }
            .padding(.top, 14)
            .padding(.trailing, 20)
            .accessibilityLabel(AL.s(.paywallOk))
        }
        .presentationDragIndicator(.visible)
        .paperBackground()
        .navigationBarHidden(true)
        .onAppear {
            guard gameCenter.isAuthenticated else { return }
            Task { await vm.loadLeaderboard() }
        }
        .onChange(of: gameCenter.isAuthenticated) { ok in
            if ok { Task { await vm.loadLeaderboard() } }
        }
    }

    // MARK: - Header
    private var leaderboardHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(langManager.s(.leaderboardTitle))
                .font(DS.Font.display(34, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
            Text(langManager.s(.leaderboardSubtitle))
                .font(DS.Font.ui(14))
                .foregroundStyle(DS.Colors.muted)
        }
    }

    // MARK: - Guest Prompt
    private var guestPromptView: some View {
        PaperCard(padding: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(langManager.s(.gcJoinTitle))
                    .font(DS.Font.display(24))
                    .foregroundStyle(DS.Colors.ink)
                Text(langManager.s(.gcJoinDesc))
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Button(langManager.s(.gcOpenSettings)) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.top, 6)
            }
        }
    }

    // MARK: - Error
    private func errorView(_ err: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(DS.Colors.muted)
            Text(err)
                .font(DS.Font.ui(15))
                .foregroundStyle(DS.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button(langManager.s(.leaderboardTryAgain)) {
                Task { await vm.loadLeaderboard() }
            }
            .buttonStyle(OutlineButtonStyle())
        }
        .padding(.top, 24)
    }

    // MARK: - Empty
    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(langManager.s(.leaderboardNoPlayers))
                .font(DS.Font.display(24))
                .foregroundStyle(DS.Colors.ink)
            Text(langManager.s(.leaderboardNoPlayersHint))
                .font(DS.Font.ui(15))
                .foregroundStyle(DS.Colors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 24)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Components
// MARK: ═══════════════════════════════════════════════════════════

/// İlk harf dairesi
private struct BoardInitials: View {
    let name: String
    var size: CGFloat = 40
    var body: some View {
        Text(name.prefix(1).uppercased())
            .font(DS.Font.display(size * 0.42))
            .foregroundStyle(DS.Colors.ink)
            .frame(width: size, height: size)
            .background(DS.Colors.paperSunken, in: Circle())
    }
}

/// Sıra numarası rengi: ilk 3 vurgulu, gerisi soluk
private func boardRankColor(_ rank: Int) -> Color {
    switch rank {
    case 1:    return DS.Colors.gold
    case 2, 3: return DS.Colors.inkSoft
    default:   return DS.Colors.muted
    }
}

private struct BoardOwnRankCard: View {
    @EnvironmentObject var langManager: LanguageManager
    let rank: Int
    let user: SBUser

    var body: some View {
        PaperCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("#\(rank)")
                        .font(DS.Font.display(34, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                }
                Rectangle().fill(DS.Colors.line).frame(width: 1, height: 40)
                BoardInitials(name: user.username, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username)
                        .font(DS.Font.ui(16, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text("\(user.totalXp) XP")
                    .font(DS.Font.ui(14, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .monospacedDigit()
            }
        }
    }
}

private struct BoardRankRow: View {
    @EnvironmentObject var langManager: LanguageManager
    let rank: Int
    let user: SBUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(DS.Font.display(20, weight: rank <= 3 ? .bold : .semibold))
                .foregroundStyle(boardRankColor(rank))
                .monospacedDigit()
                .frame(width: 30, alignment: .leading)

            BoardInitials(name: user.username, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(DS.Font.ui(16, weight: isCurrentUser ? .bold : .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text("\(user.totalXp) XP")
                .font(DS.Font.ui(14, weight: .medium))
                .foregroundStyle(DS.Colors.muted)
                .monospacedDigit()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, isCurrentUser ? 12 : 0)
        .background {
            if isCurrentUser {
                RoundedRectangle(cornerRadius: 12).fill(DS.Colors.paperSunken)
            }
        }
    }
}

#Preview {
    LeaderboardView(selectedTab: .constant(.leaderboard))
}
