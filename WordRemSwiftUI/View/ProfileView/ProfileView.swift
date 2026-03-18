//
//  ProfileView.swift
//  WordRemSwiftUI
//
//  Gamified profile screen — avatar, stats, XP, streak,
//  accuracy, completed levels, and sign-out.
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var vm = ProfileScreenViewModel()
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#ede9fe"), Color(hex: "#f5f3ff"), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Avatar + Username
                    avatarSection

                    // XP & Streak Cards
                    xpStreakRow

                    // Stats Grid
                    statsGrid

                    // Achievements Section
                    achievementsSection

                    // Upgrade Pro
                    upgradeButton

                    // Sign Out
                    signOutButton

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.loadProfile()
        }
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#8b5cf6"), Color(hex: "#a78bfa"), Color(hex: "#c4b5fd")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)

                // Avatar circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8b5cf6"), Color(hex: "#7c3aed")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: Color(hex: "#8b5cf6").opacity(0.3), radius: 12, y: 6)

                Text(vm.initials)
                    .font(.custom("Poppins-Bold", size: 36))
                    .foregroundStyle(.white)
            }

            Text(vm.username)
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundStyle(Color(hex: "#1a1a2e"))

            if let displayName = vm.user?.displayName, !displayName.isEmpty {
                Text(displayName)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(.secondary)
            }

            // Level badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#f59e0b"))
                Text("Level \(vm.userLevel)")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(hex: "#f59e0b").opacity(0.12), in: Capsule())
        }
    }

    // MARK: - XP & Streak Row
    private var xpStreakRow: some View {
        HStack(spacing: 14) {
            // XP Card
            ProfileStatCard(
                icon: "bolt.fill",
                iconColor: Color(hex: "#f59e0b"),
                title: "Total XP",
                value: "\(vm.user?.totalXp ?? 0)",
                bgGradient: [Color(hex: "#fef3c7"), Color(hex: "#fde68a")]
            )

            // Streak Card
            ProfileStatCard(
                icon: "flame.fill",
                iconColor: .orange,
                title: "Streak",
                value: "\(vm.user?.streakDays ?? 0) days",
                bgGradient: [Color(hex: "#fed7aa"), Color(hex: "#fdba74")]
            )
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.custom("Poppins-SemiBold", size: 17))
                .foregroundStyle(Color(hex: "#1a1a2e"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MiniStatCard(
                    icon: "checkmark.circle.fill",
                    label: "Completed",
                    value: "\(vm.stats.completedLevels)",
                    color: .green
                )
                MiniStatCard(
                    icon: "questionmark.circle.fill",
                    label: "Quizzes",
                    value: "\(vm.stats.totalAttempts)",
                    color: .blue
                )
                MiniStatCard(
                    icon: "target",
                    label: "Accuracy",
                    value: String(format: "%.0f%%", vm.stats.accuracy),
                    color: .purple
                )
                MiniStatCard(
                    icon: "star.fill",
                    label: "Level",
                    value: "\(vm.userLevel)",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.custom("Poppins-SemiBold", size: 17))
                .foregroundStyle(Color(hex: "#1a1a2e"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(
                        icon: "flame.fill",
                        title: "First Streak",
                        isUnlocked: (vm.user?.streakDays ?? 0) >= 1,
                        color: .orange
                    )
                    AchievementBadge(
                        icon: "star.fill",
                        title: "5 Levels",
                        isUnlocked: vm.stats.completedLevels >= 5,
                        color: .yellow
                    )
                    AchievementBadge(
                        icon: "bolt.fill",
                        title: "100 XP",
                        isUnlocked: (vm.user?.totalXp ?? 0) >= 100,
                        color: Color(hex: "#f59e0b")
                    )
                    AchievementBadge(
                        icon: "target",
                        title: "Sharp Eye",
                        isUnlocked: vm.stats.accuracy >= 90,
                        color: .green
                    )
                    AchievementBadge(
                        icon: "crown.fill",
                        title: "500 XP",
                        isUnlocked: (vm.user?.totalXp ?? 0) >= 500,
                        color: .purple
                    )
                }
            }
        }
    }

    // MARK: - Upgrade Pro
    private var upgradeButton: some View {
        Button {
            EventManager.shared.logPaywallEvent("upgrade_tapped_profile")
            showPaywall = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Upgrade Pro")
                    .font(.custom("Poppins-Bold", size: 15))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#8b5cf6"), Color(hex: "#7c3aed")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "#8b5cf6").opacity(0.4), radius: 10, y: 5)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(onContinue: { showPaywall = false })
        }
    }

    // MARK: - Sign Out
    private var signOutButton: some View {
        Button {
            authManager.signOut()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Sign Out")
                    .font(.custom("Poppins-SemiBold", size: 15))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 8)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Profile ViewModel
// MARK: ═══════════════════════════════════════════════════════════

@MainActor
final class ProfileScreenViewModel: ObservableObject {
    @Published var user: SBUser?
    @Published var stats = UserStats(completedLevels: 0, totalAttempts: 0, correctAnswers: 0)
    @Published var isLoading = false

    var username: String { user?.username ?? "Guest" }

    var initials: String {
        let name = user?.username ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    var userLevel: Int {
        let xp = user?.totalXp ?? 0
        return max(1, xp / 50 + 1) // Every 50 XP = 1 level
    }

    func loadProfile() async {
        isLoading = true
        do {
            user = try await SupabaseDataService.shared.fetchUserProfile()
            stats = try await SupabaseDataService.shared.fetchUserStats()
        } catch {
            print("❌ Profile load error: \(error)")
        }
        isLoading = false
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Subviews
// MARK: ═══════════════════════════════════════════════════════════

private struct ProfileStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let bgGradient: [Color]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(iconColor)
                Spacer()
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                    Text(title)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: bgGradient,
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

private struct MiniStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundStyle(Color(hex: "#1a1a2e"))
            Text(label)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }
}

private struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked
                        ? color.opacity(0.15)
                        : Color(hex: "#e2e8f0"))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isUnlocked ? color : .gray.opacity(0.4))
            }

            Text(title)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundStyle(isUnlocked ? Color(hex: "#1a1a2e") : .secondary)
                .lineLimit(1)
        }
        .frame(width: 70)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
