//
//  LeaderboardView.swift
//  WordRemSwiftUI
//

import SwiftUI
import Lottie

struct LeaderboardView: View {

    @EnvironmentObject var langManager: LanguageManager
    @Binding var selectedTab: AppTab
    @StateObject private var vm = LeaderboardViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            Color(hex: "#f4f6f9").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header (PathHeaderView ile aynı stil) ─────────
                leaderboardHeader

                // Guest kullanıcıya login yönlendirme
                if authManager.isAnonymous {
                    Spacer()
                    guestPromptView
                    Spacer()
                } else if vm.isLoading && vm.users.isEmpty {
                    AppLoadingView()

                } else if let err = vm.errorMessage {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text(err)
                            .font(.custom("Feather-Bold", size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button(langManager.s(.leaderboardTryAgain)) {
                            Task { await vm.loadLeaderboard() }
                        }
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28).padding(.vertical, 12)
                        .background(AppTheme.Colors.primaryOrange, in: Capsule())
                    }
                    Spacer()

                } else if vm.users.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🏆").font(.system(size: 60))
                        Text(langManager.s(.leaderboardNoPlayers))
                            .font(.custom("Feather-Bold", size: 17))
                        Text(langManager.s(.leaderboardNoPlayersHint))
                            .font(.custom("Feather-Bold", size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // ── Top 3 Podium ───────────────────────
                            if vm.users.count >= 3 {
                                PodiumView(
                                    first:  vm.users[0],
                                    second: vm.users[1],
                                    third:  vm.users[2],
                                    currentUserId: vm.currentUserId
                                )
                                .padding(.top, 20)
                                .padding(.bottom, 8)
                            }

                            // ── Divider ────────────────────────────
                            HStack {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.clear, Color(hex: "#e2e8f0"), Color.clear],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                            // ── Rankings 4th–20th ─────────────────
                            LazyVStack(spacing: 8) {
                                let startIndex = min(3, vm.users.count)
                                ForEach(
                                    Array(vm.users.dropFirst(startIndex).prefix(20 - startIndex).enumerated()),
                                    id: \.element.id
                                ) { index, user in
                                    RankRow(
                                        rank: startIndex + index + 1,
                                        user: user,
                                        isCurrentUser: user.id == vm.currentUserId
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                    .refreshable { await vm.loadLeaderboard() }

                    // ── Sticky "Benim Sıram" ───────────────────────
                    if let uid = vm.currentUserId,
                       let specificRank = vm.specificUserRank,
                       let specificUser = vm.currentUser,
                       !vm.users.contains(where: { $0.id == uid }) {
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [Color.clear, Color(hex: "#e2e8f0")],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 1)
                            RankRow(rank: specificRank, user: specificUser, isCurrentUser: true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard !authManager.isAnonymous else { return }
            Task { await vm.loadLeaderboard() }
        }
    }

    // MARK: - Guest Prompt
    private var guestPromptView: some View {
        VStack(spacing: 20) {
            MascotAnimationView(width: 130, height: 130)

            VStack(spacing: 6) {
                Text(langManager.s(.leaderboardJoinTitle))
                    .font(.custom("Feather-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1a1a2e"))

                Text(langManager.s(.leaderboardJoinDesc))
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                selectedTab = .profile
            } label: {
                Text(langManager.s(.leaderboardSignIn))
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Header
    private var leaderboardHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(langManager.s(.leaderboardTitle))
                    .font(.custom("Feather-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(langManager.s(.leaderboardSubtitle))
                    .font(.custom("Feather-Bold", size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            // Kullanıcının kendi sırası
            if let rank = vm.currentUserRank() {
                HStack(spacing: 5) {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#f59e0b"))
                    Text("#\(rank)")
                        .font(.custom("Feather-Bold", size: 15))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "#f59e0b").opacity(0.13), in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            Color.clear
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Podium
// MARK: ═══════════════════════════════════════════════════════════

private struct PodiumView: View {
    let first: SBUser
    let second: SBUser
    let third: SBUser
    let currentUserId: UUID?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            PodiumSlot(user: second, rank: 2, barHeight: 90,
                       podiumColor: Color(hex: "#94a3b8"), crownColor: Color(hex: "#c0c0c0"),
                       isCurrentUser: second.id == currentUserId)

            PodiumSlot(user: first, rank: 1, barHeight: 120,
                       podiumColor: Color(hex: "#f59e0b"), crownColor: Color(hex: "#fbbf24"),
                       isCurrentUser: first.id == currentUserId)

            PodiumSlot(user: third, rank: 3, barHeight: 70,
                       podiumColor: Color(hex: "#cd7f32"), crownColor: Color(hex: "#d97706"),
                       isCurrentUser: third.id == currentUserId)
        }
        .padding(.horizontal, 16)
    }
}

private struct PodiumSlot: View {
    let user: SBUser
    let rank: Int
    let barHeight: CGFloat
    let podiumColor: Color
    let crownColor: Color
    let isCurrentUser: Bool

    @State private var appeared = false

    private var avatarSize: CGFloat { rank == 1 ? 68 : 54 }

    var body: some View {
        VStack(spacing: 6) {
            // Crown (1. yer)
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(crownColor)
                    .shadow(color: crownColor.opacity(0.6), radius: 6, y: 2)
                    .offset(y: 4)
            } else {
                Color.clear.frame(height: 18)
            }

            // Avatar
            ZStack {
                if isCurrentUser {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#FFAA44"), Color(hex: "#E8409C"), Color(hex: "#6B22E0")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: avatarSize + 8, height: avatarSize + 8)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [podiumColor, podiumColor.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                    .shadow(color: podiumColor.opacity(0.35), radius: 10, y: 5)

                Text(user.username.prefix(1).uppercased())
                    .font(.custom("Feather-Bold", size: rank == 1 ? 26 : 20))
                    .foregroundStyle(.white)
            }

            // Username
            Text(user.username)
                .font(.custom("Feather-Bold", size: 12))
                .foregroundStyle(Color(hex: "#1a1a2e"))
                .lineLimit(1)

            // XP
            Text("\(user.totalXp) XP")
                .font(.custom("Feather-Bold", size: 11))
                .foregroundStyle(podiumColor)

            // Podium bar
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [podiumColor, podiumColor.opacity(0.55)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                Text("#\(rank)")
                    .font(.custom("Feather-Bold", size: rank == 1 ? 22 : 18))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(height: appeared ? barHeight : 4)
            .animation(
                .spring(response: 0.65, dampingFraction: 0.72)
                    .delay(Double(4 - rank) * 0.12),
                value: appeared
            )
        }
        .frame(maxWidth: .infinity)
        .onAppear { appeared = true }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Rank Row
// MARK: ═══════════════════════════════════════════════════════════

private struct RankRow: View {
    @EnvironmentObject var langManager: LanguageManager
    let rank: Int
    let user: SBUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Sıra numarası
            Text("\(rank)")
                .font(.custom("Feather-Bold", size: 15))
                .foregroundStyle(rank <= 10 ? AppTheme.Colors.primaryOrange : .secondary)
                .frame(width: 32, alignment: .center)

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isCurrentUser
                                ? [Color(hex: "#FFAA44"), Color(hex: "#E8409C")]
                                : [Color(hex: "#e2e8f0"), Color(hex: "#cbd5e1")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(user.username.prefix(1).uppercased())
                    .font(.custom("Feather-Bold", size: 18))
                    .foregroundStyle(isCurrentUser ? .white : Color(hex: "#64748b"))
            }

            // İsim + streak
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text(langManager.f(.leaderboardDayStreak, user.streakDays))
                        .font(.custom("Feather-Bold", size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // XP badge
            Text("\(user.totalXp) XP")
                .font(.custom("Feather-Bold", size: 13))
                .foregroundStyle(isCurrentUser ? .white : AppTheme.Colors.primaryOrange)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isCurrentUser
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "#FFAA44"), Color(hex: "#E8409C")],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(AppTheme.Colors.primaryOrange.opacity(0.1)),
                    in: Capsule()
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrentUser
                      ? LinearGradient(
                          colors: [Color(hex: "#FFAA44").opacity(0.06), Color(hex: "#E8409C").opacity(0.06)],
                          startPoint: .leading, endPoint: .trailing)
                      : LinearGradient(colors: [Color.white], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCurrentUser
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "#FFAA44").opacity(0.4), Color(hex: "#E8409C").opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.clear),
                    lineWidth: 1.5
                )
        )
    }
}

#Preview {
    LeaderboardView(selectedTab: .constant(.leaderboard))
}
