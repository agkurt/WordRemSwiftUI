//
//  LeaderboardView.swift
//  WordRemSwiftUI
//
//  Gamified leaderboard — XP ranking with crown icons,
//  highlighted current user, and decorative elements.
//

import SwiftUI

struct LeaderboardView: View {

    @StateObject private var vm = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#fef3c7"), Color(hex: "#fff7ed"), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    leaderboardHeader

                    if vm.isLoading && vm.users.isEmpty {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(AppTheme.Colors.primaryOrange)
                        Spacer()
                    } else if let err = vm.errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text(err)
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button(AL.s(.leaderboardTryAgain)) {
                                Task { await vm.loadLeaderboard() }
                            }
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(AppTheme.Colors.primaryOrange, in: Capsule())
                        }
                        Spacer()
                    } else if vm.users.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("🏆")
                                .font(.system(size: 60))
                            Text(AL.s(.leaderboardNoPlayers))
                                .font(.custom("Poppins-SemiBold", size: 17))
                            Text(AL.s(.leaderboardNoPlayersHint))
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        // Top 3 podium
                        if vm.users.count >= 3 {
                            PodiumView(
                                first: vm.users[0],
                                second: vm.users[1],
                                third: vm.users[2],
                                currentUserId: vm.currentUserId
                            )
                            .padding(.top, 8)
                        }

                        // Rankings list
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 8) {
                                let startIndex = min(3, vm.users.count)
                                ForEach(Array(vm.users.dropFirst(startIndex).enumerated()),
                                        id: \.element.id) { index, user in
                                    RankRow(
                                        rank: startIndex + index + 1,
                                        user: user,
                                        isCurrentUser: user.id == vm.currentUserId
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await vm.loadLeaderboard()
                        }

                        // My Rank (Sticky Bottom) if not in Top 50
                        if let uid = vm.currentUserId, 
                           let specificRank = vm.specificUserRank, 
                           let specificUser = vm.currentUser,
                           !vm.users.contains(where: { $0.id == uid }) {
                            
                            VStack(spacing: 0) {
                                Divider()
                                    .background(AppTheme.Colors.primaryOrange.opacity(0.3))
                                RankRow(
                                    rank: specificRank,
                                    user: specificUser,
                                    isCurrentUser: true
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.shadow(color: .black.opacity(0.08), radius: 8, y: -4))
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await vm.loadLeaderboard()
                }
            }
        }
    }

    // MARK: - Header
    private var leaderboardHeader: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AL.s(.leaderboardTitle))
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                    Text(AL.s(.leaderboardSubtitle))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if let rank = vm.currentUserRank() {
                    HStack(spacing: 4) {
                        Image(systemName: "medal.fill")
                            .foregroundStyle(Color(hex: "#f59e0b"))
                        Text("#\(rank)")
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundStyle(Color(hex: "#1a1a2e"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#f59e0b").opacity(0.15), in: Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Top 3 Podium
// MARK: ═══════════════════════════════════════════════════════════

private struct PodiumView: View {
    let first: SBUser
    let second: SBUser
    let third: SBUser
    let currentUserId: UUID?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // #2 (Silver)
            PodiumSlot(
                user: second,
                rank: 2,
                height: 90,
                color: Color(hex: "#94a3b8"),
                crownColor: Color(hex: "#c0c0c0"),
                isCurrentUser: second.id == currentUserId
            )

            // #1 (Gold)
            PodiumSlot(
                user: first,
                rank: 1,
                height: 120,
                color: Color(hex: "#f59e0b"),
                crownColor: Color(hex: "#fbbf24"),
                isCurrentUser: first.id == currentUserId
            )

            // #3 (Bronze)
            PodiumSlot(
                user: third,
                rank: 3,
                height: 70,
                color: Color(hex: "#d97706"),
                crownColor: Color(hex: "#cd7f32"),
                isCurrentUser: third.id == currentUserId
            )
        }
        .padding(.horizontal, 24)
    }
}

private struct PodiumSlot: View {
    let user: SBUser
    let rank: Int
    let height: CGFloat
    let color: Color
    let crownColor: Color
    let isCurrentUser: Bool

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 6) {
            // Crown / medal
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(crownColor)
                    .shadow(color: crownColor.opacity(0.5), radius: 6, y: 2)
            }

            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: rank == 1 ? 64 : 52, height: rank == 1 ? 64 : 52)
                    .shadow(color: color.opacity(0.3), radius: 8, y: 4)

                Text(user.username.prefix(1).uppercased())
                    .font(.custom("Poppins-Bold", size: rank == 1 ? 24 : 20))
                    .foregroundStyle(.white)

                if isCurrentUser {
                    Circle()
                        .strokeBorder(AppTheme.Colors.primaryOrange, lineWidth: 3)
                        .frame(width: rank == 1 ? 70 : 58, height: rank == 1 ? 70 : 58)
                }
            }

            // Username
            Text(user.username)
                .font(.custom("Poppins-SemiBold", size: 12))
                .foregroundStyle(Color(hex: "#1a1a2e"))
                .lineLimit(1)

            // XP
            Text("\(user.totalXp) XP")
                .font(.custom("Poppins-Bold", size: 11))
                .foregroundStyle(color)

            // Podium bar
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: appeared ? height : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(rank) * 0.15), value: appeared)
                .overlay(
                    Text("#\(rank)")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundStyle(.white.opacity(0.8))
                )
        }
        .frame(maxWidth: .infinity)
        .onAppear { appeared = true }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Rank Row (4th place and beyond)
// MARK: ═══════════════════════════════════════════════════════════

private struct RankRow: View {
    let rank: Int
    let user: SBUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Rank number
            Text("\(rank)")
                .font(.custom("Poppins-Bold", size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .center)

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#e2e8f0"), Color(hex: "#cbd5e1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Text(user.username.prefix(1).uppercased())
                    .font(.custom("Poppins-SemiBold", size: 17))
                    .foregroundStyle(Color(hex: "#64748b"))
            }

            // Name + streak
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text(AL.f(.leaderboardDayStreak, user.streakDays))
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // XP
            Text("\(user.totalXp) XP")
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundStyle(AppTheme.Colors.primaryOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentUser ? AppTheme.Colors.primaryOrange.opacity(0.08) : Color.white)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrentUser ? AppTheme.Colors.primaryOrange.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    LeaderboardView()
}
