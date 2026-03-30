//
//  ProfileView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var vm = ProfileScreenViewModel()
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var iap = InAppPurchaseManager.shared
    @State private var showPaywall = false
    @State private var showGuestLoginSheet = false
    @State private var showLoginScreen = false
    @State private var showUsernameSetup = false
    @State private var showAllAchievements = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#f4f6f9").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header (PathHeaderView ile aynı stil) ──────────
                profileHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if authManager.isAnonymous { guestLoginBanner }
                        heroCard
                        statsOverviewRow
                        streakCard
                        learningProgressCard
                        achievementsSection
                        signOutButton
                        deleteAccountButton
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await vm.loadProfile() }
        // Login sonrası profili yenile + Supabase'den username_changes kontrolü
        .onChange(of: authManager.isAnonymous) { isAnon in
            guard !isAnon else { return }
            Task {
                await vm.loadProfile()
                // username_changes == 0 → henüz hiç set edilmemiş, zorunlu popup
                if (vm.user?.usernameChanges ?? 0) == 0 {
                    showUsernameSetup = true
                }
            }
        }
        .fullScreenCover(isPresented: $showUsernameSetup) {
            UsernameSetupPopup(
                initialUsername: vm.username,
                isFirstSetup: (vm.user?.usernameChanges ?? 0) == 0,
                onDismiss: { showUsernameSetup = false },
                onSave: { newName in
                    Task {
                        await vm.updateUsername(newName)
                        showUsernameSetup = false
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(onContinue: { showPaywall = false })
        }
        .sheet(isPresented: $showGuestLoginSheet) {
            GuestLoginSheet(onEmailSelected: {
                showGuestLoginSheet = false
                // Kısa gecikme: sheet tamamen kapansın, sonra LoginScreen açılsın
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showLoginScreen = true
                }
            })
            .environmentObject(authManager)
        }
        .fullScreenCover(isPresented: $showLoginScreen) {
            LoginScreenView()
                .environmentObject(authManager)
        }
    }

    // MARK: - Guest Login Banner
    private var guestLoginBanner: some View {
        Button { showGuestLoginSheet = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#fff7ed"))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "#f97316"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(langManager.s(.profileSaveProgress))
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                    Text(langManager.s(.profileSaveProgressHint))
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#cbd5e1"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#fed7aa"), lineWidth: 1.5)
                    )
                    .shadow(color: Color(hex: "#f97316").opacity(0.08), radius: 8, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Header
    private var profileHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(vm.username)
                    .font(.custom("Feather-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(langManager.f(.profileLevelFormat, vm.userLevel))
                    .font(.custom("Feather-Bold", size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            // XP pill
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#f59e0b"))
                Text("\(vm.user?.totalXp ?? 0) XP")
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: "#f59e0b").opacity(0.13), in: Capsule())

            // Streak pill
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("\(vm.user?.streakDays ?? 0)")
                    .font(.custom("Feather-Bold", size: 14))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.orange.opacity(0.12), in: Capsule())
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

    // MARK: - Hero Card (avatar + isim + upgrade butonu)
    private var heroCard: some View {
        VStack(spacing: 0) {
            // Avatar + isim satırı
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#f1f5f9"))
                        .frame(width: 68, height: 68)
                    if let char = vm.selectedCharacter {
                        Image(char)
                            .resizable().scaledToFill()
                            .frame(width: 68, height: 68)
                            .clipShape(Circle())
                    } else {
                        Text(vm.initials)
                            .font(.custom("Feather-Bold", size: 26))
                            .foregroundStyle(Color(hex: "#64748b"))
                    }
                }
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(vm.username)
                            .font(.custom("Feather-Bold", size: 18))
                            .foregroundStyle(Color(hex: "#1a1a2e"))

                        if !authManager.isAnonymous, (vm.user?.usernameChanges ?? 0) == 1 {
                            Button { showUsernameSetup = true } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                                    .padding(6)
                                    .background(AppTheme.Colors.primaryOrange.opacity(0.1), in: Circle())
                            }
                        }
                    }

                    // Level + XP + Streak inline
                    HStack(spacing: 8) {
                        Label(langManager.f(.profileLevelFormat, vm.userLevel), systemImage: "star.fill")
                            .font(.custom("Feather-Bold", size: 11))
                            .foregroundStyle(Color(hex: "#f59e0b"))
                        Label("\(vm.user?.totalXp ?? 0) XP", systemImage: "bolt.fill")
                            .font(.custom("Feather-Bold", size: 11))
                            .foregroundStyle(Color(hex: "#64748b"))
                        Label("\(vm.user?.streakDays ?? 0)", systemImage: "flame.fill")
                            .font(.custom("Feather-Bold", size: 11))
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().padding(.horizontal, 16)

            if iap.isPremium {
                // Premium badge
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#8b5cf6"))
                    Text("WordRem Pro")
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(Color(hex: "#8b5cf6"))
                    Spacer()
                    Text("✓ Aktif")
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#8b5cf6"), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            } else {
                // Upgrade Pro butonu
                Button {
                    EventManager.shared.logPaywallEvent("upgrade_tapped_profile")
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(langManager.s(.profileUpgradePro))
                            .font(.custom("Feather-Bold", size: 14))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#3B5BDB"), in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color(hex: "#3B5BDB").opacity(0.28), radius: 8, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
    }

    // MARK: - Stats Overview Row
    private var statsOverviewRow: some View {
        HStack(spacing: 12) {
            StatOverviewTile(
                icon: "checkmark.seal.fill",
                color: Color(hex: "#6366f1"),
                value: "\(vm.stats.totalAttempts)",
                label: "Toplam Soru"
            )
            StatOverviewTile(
                icon: "target",
                color: Color(hex: "#E8409C"),
                value: String(format: "%.0f%%", vm.stats.accuracy),
                label: "Doğruluk"
            )
            StatOverviewTile(
                icon: "flag.checkered",
                color: Color(hex: "#10b981"),
                value: "\(vm.stats.completedLevels)",
                label: "Tamamlanan"
            )
        }
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seri")
                .font(.custom("Feather-Bold", size: 18))
                .foregroundStyle(Color(hex: "#1a1a2e"))

            VStack(spacing: 10) {
                // Günlük Seri
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#fff7ed"))
                            .frame(width: 38, height: 38)
                        Text("🔥").font(.system(size: 20))
                    }
                    Text("Günlük Seri")
                        .font(.custom("Feather-Bold", size: 15))
                        .foregroundStyle(Color(hex: "#ea580c"))
                    Spacer()
                    Text("\(vm.user?.streakDays ?? 0)")
                        .font(.custom("Feather-Bold", size: 20))
                        .foregroundStyle(Color(hex: "#ea580c"))
                        .frame(minWidth: 44, minHeight: 36)
                        .background(Color(hex: "#fff7ed"), in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(12)
                .background(Color(hex: "#fff7ed").opacity(0.5), in: RoundedRectangle(cornerRadius: 14))

                // En İyi Seri
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#f0fdf4"))
                            .frame(width: 38, height: 38)
                        Text("🏆").font(.system(size: 20))
                    }
                    Text("En İyi Seri")
                        .font(.custom("Feather-Bold", size: 15))
                        .foregroundStyle(Color(hex: "#16a34a"))
                    Spacer()
                    Text("\(vm.bestStreak)")
                        .font(.custom("Feather-Bold", size: 20))
                        .foregroundStyle(Color(hex: "#16a34a"))
                        .frame(minWidth: 44, minHeight: 36)
                        .background(Color(hex: "#f0fdf4"), in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(12)
                .background(Color(hex: "#f0fdf4").opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
            }

            // Haftalık Takvim
            weeklyCalendarView
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // MARK: - Weekly Calendar
    private var weeklyCalendarView: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let streak = vm.user?.streakDays ?? 0
        let lastActive: Date
        if let raw = vm.user?.lastActivityAt {
            lastActive = calendar.startOfDay(for: raw)
        } else {
            lastActive = today
        }

        // Bugünden 6 gün geriye: 7 günlük pencere
        let days = (0..<7).map { i -> Date in
            calendar.date(byAdding: .day, value: -6 + i, to: today)!
        }
        let trNames = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cts", "Paz"]

        return HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                let weekdayIdx = (calendar.component(.weekday, from: day) + 5) % 7 // Mon=0
                let daysSinceLastActive = calendar.dateComponents([.day], from: day, to: lastActive).day ?? 99
                let isActive = daysSinceLastActive >= 0 && daysSinceLastActive < streak
                let isToday = calendar.isDateInToday(day)

                VStack(spacing: 6) {
                    Text(trNames[weekdayIdx])
                        .font(.custom("Feather-Bold", size: 10))
                        .foregroundStyle(isToday ? AppTheme.Colors.primaryOrange : Color(hex: "#94a3b8"))

                    Circle()
                        .fill(isActive
                            ? (isToday ? AppTheme.Colors.primaryOrange : Color(hex: "#fb923c").opacity(0.75))
                            : Color(hex: "#e2e8f0")
                        )
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isActive {
                                Text("🔥").font(.system(size: 14))
                            }
                        }
                        .shadow(color: isActive ? AppTheme.Colors.primaryOrange.opacity(0.3) : .clear, radius: 4, y: 2)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Learning Progress Card
    private var learningProgressCard: some View {
        let xp = vm.user?.totalXp ?? 0
        let xpPerLevel = 50
        let currentLevel = max(1, xp / xpPerLevel + 1)
        let xpInLevel = xp % xpPerLevel
        let xpProgress = Double(xpInLevel) / Double(xpPerLevel)

        return VStack(alignment: .leading, spacing: 16) {
            Text("İlerleme")
                .font(.custom("Feather-Bold", size: 18))
                .foregroundStyle(Color(hex: "#1a1a2e"))

            // XP Level Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#f59e0b"))
                        Text("Seviye \(currentLevel)")
                            .font(.custom("Feather-Bold", size: 14))
                            .foregroundStyle(Color(hex: "#1a1a2e"))
                    }
                    Spacer()
                    Text("\(xp) XP")
                        .font(.custom("Feather-Bold", size: 13))
                        .foregroundStyle(Color(hex: "#64748b"))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#f1f5f9"))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#f59e0b"), Color(hex: "#f97316")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: max(10, geo.size.width * xpProgress), height: 10)
                            .shadow(color: Color(hex: "#f97316").opacity(0.4), radius: 4, y: 2)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(xpInLevel)/\(xpPerLevel) XP")
                        .font(.custom("Feather-Bold", size: 11))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                    Spacer()
                    Text("Sonraki seviye")
                        .font(.custom("Feather-Bold", size: 11))
                        .foregroundStyle(Color(hex: "#94a3b8"))
                }
            }
            .padding(16)
            .background(Color(hex: "#fffbeb").opacity(0.8), in: RoundedRectangle(cornerRadius: 14))

            // 3 mini stat kutucukları
            HStack(spacing: 10) {
                MiniProgressTile(
                    emoji: "⚡",
                    value: "\(xp)",
                    label: "Toplam XP",
                    bg: Color(hex: "#fef9c3")
                )
                MiniProgressTile(
                    emoji: "📚",
                    value: "\(vm.stats.completedLevels)",
                    label: "Seviye",
                    bg: Color(hex: "#dbeafe")
                )
                MiniProgressTile(
                    emoji: "🎯",
                    value: String(format: "%.0f%%", vm.stats.accuracy),
                    label: "Doğruluk",
                    bg: Color(hex: "#fce7f3")
                )
            }
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Text(langManager.s(.profileAchievements))
                    .font(.custom("Poppins-Bold", size: 17))
                    .foregroundStyle(Color(hex: "#1a1a2e"))

                Spacer()

                // Unlocked count badge
                let unlockedCount = achievementService.all.filter { $0.isUnlocked }.count
                Text("\(unlockedCount)/\(achievementService.all.count)")
                    .font(.custom("Poppins-SemiBold", size: 12))
                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.primaryOrange.opacity(0.12), in: Capsule())

                Button {
                    showAllAchievements = true
                } label: {
                    Text(langManager.s(.achievementViewMore))
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                }
            }

            // First 5 achievements (unlocked first, then locked)
            let sorted = achievementService.all.sorted {
                if $0.isUnlocked != $1.isUnlocked { return $0.isUnlocked }
                return false
            }
            let preview = Array(sorted.prefix(5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(preview) { ach in
                        AchievementBadge(
                            icon: ach.icon,
                            title: ach.title,
                            isUnlocked: ach.isUnlocked,
                            color: ach.color,
                            rarity: ach.rarity
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .sheet(isPresented: $showAllAchievements) {
            AllAchievementsSheet(achievements: achievementService.all)
        }
    }

    // MARK: - Sign Out
    private var signOutButton: some View {
        Button { authManager.signOut() } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                Text(langManager.s(.profileSignOut))
                    .font(.custom("Feather-Bold", size: 14))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.18), lineWidth: 1))
            )
        }
    }

    // MARK: - Delete Account
    private var deleteAccountButton: some View {
        Button { showDeleteConfirm = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                Text(langManager.s(.profileDeleteAccount))
                    .font(.custom("Feather-Bold", size: 14))
            }
            .foregroundStyle(Color(hex: "#94a3b8"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .alert(langManager.s(.profileDeleteTitle), isPresented: $showDeleteConfirm) {
            Button(langManager.s(.profileDeleteConfirm), role: .destructive) {
                authManager.deleteAccount()
            }
            Button(langManager.s(.profileDeleteCancel), role: .cancel) {}
        } message: {
            Text(langManager.s(.profileDeleteMessage))
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - ViewModel
// MARK: ═══════════════════════════════════════════════════════════

@MainActor
final class ProfileScreenViewModel: ObservableObject {
    @Published var user: SBUser?
    @Published var stats = UserStats(completedLevels: 0, totalAttempts: 0, correctAnswers: 0)
    @Published var isLoading = false
    @Published var showCharacterPicker = false

    /// Seçili karakter asset adı (UserDefaults'ta saklanır)
    @Published var selectedCharacter: String? {
        didSet {
            if let v = selectedCharacter { UserDefaults.standard.set(v, forKey: "selectedCharacter") }
            else { UserDefaults.standard.removeObject(forKey: "selectedCharacter") }
        }
    }

    init() {
        selectedCharacter = UserDefaults.standard.string(forKey: "selectedCharacter")
    }

    var username: String  { user?.username ?? AL.s(.profileGuest) }
    var initials: String  { String((user?.username ?? "?").prefix(1)).uppercased() }
    var userLevel: Int    { max(1, (user?.totalXp ?? 0) / 50 + 1) }

    /// En iyi seri: mevcut streak'ten büyükse UserDefaults'ta sakla
    var bestStreak: Int {
        let current = user?.streakDays ?? 0
        let stored  = UserDefaults.standard.integer(forKey: "bestStreak")
        if current > stored {
            UserDefaults.standard.set(current, forKey: "bestStreak")
            return current
        }
        return max(stored, current)
    }

    func loadProfile() async {
        isLoading = true
        do {
            user  = try await SupabaseDataService.shared.fetchUserProfile()
            stats = try await SupabaseDataService.shared.fetchUserStats()
            // Fetch already-saved achievements (no new unlock toast on profile open)
            await AchievementService.shared.fetchSaved()
        } catch {
            print("❌ Profile load error: \(error)")
        }
        isLoading = false
    }

    func updateUsername(_ newUsername: String) async {
        guard let uid = SupabaseService.shared.currentUserId else { return }
        let currentChanges = user?.usernameChanges ?? 0
        let uidStr = uid.uuidString

        // 1) Username güncelle (her zaman çalışır)
        do {
            struct UsernameOnly: Encodable { let username: String }
            try await SupabaseService.shared.client
                .from("users")
                .update(UsernameOnly(username: newUsername))
                .eq("id", value: uidStr)
                .execute()
            print("✅ Username updated: \(newUsername)")
        } catch {
            print("❌ updateUsername error: \(error)")
            return
        }

        // 2) username_changes sayacını artır — kolon yoksa sessizce geç
        do {
            struct ChangesOnly: Encodable { let username_changes: Int }
            try await SupabaseService.shared.client
                .from("users")
                .update(ChangesOnly(username_changes: currentChanges + 1))
                .eq("id", value: uidStr)
                .execute()
            print("✅ username_changes: \(currentChanges + 1)")
        } catch {
            print("⚠️ username_changes kolon yok (SQL çalıştırılmadı?): \(error)")
        }

        // Profili yenile
        user = try? await SupabaseDataService.shared.fetchUserProfile()
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Subviews
// MARK: ═══════════════════════════════════════════════════════════

// MARK: - StatOverviewTile
private struct StatOverviewTile: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.custom("Feather-Bold", size: 18))
                .foregroundStyle(Color(hex: "#1a1a2e"))
            Text(label)
                .font(.custom("Feather-Bold", size: 10))
                .foregroundStyle(Color(hex: "#94a3b8"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

// MARK: - MiniProgressTile
private struct MiniProgressTile: View {
    let emoji: String
    let value: String
    let label: String
    let bg: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 22))
            Text(value)
                .font(.custom("Feather-Bold", size: 16))
                .foregroundStyle(Color(hex: "#1a1a2e"))
            Text(label)
                .font(.custom("Feather-Bold", size: 10))
                .foregroundStyle(Color(hex: "#64748b"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bg, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct CompactStatTile: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(label)
                    .font(.custom("Feather-Bold", size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

private struct ProfileStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let bgColors: [Color]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(iconColor)
                Spacer()
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.custom("Feather-Bold", size: 22))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                    Text(title)
                        .font(.custom("Feather-Bold", size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: bgColors, startPoint: .topLeading, endPoint: .bottomTrailing))
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
                .font(.custom("Feather-Bold", size: 18))
                .foregroundStyle(Color(hex: "#1a1a2e"))
            Text(label)
                .font(.custom("Feather-Bold", size: 11))
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
    var rarity: AchievementRarity = .common

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer ring with rarity gradient when unlocked
                Circle()
                    .strokeBorder(
                        isUnlocked
                            ? LinearGradient(
                                colors: rarity.gradientColors,
                                startPoint: .topLeading, endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color(hex: "#e2e8f0"), Color(hex: "#e2e8f0")],
                                startPoint: .top, endPoint: .bottom
                              ),
                        lineWidth: isUnlocked ? 2.5 : 1.5
                    )
                    .frame(width: 62, height: 62)

                Circle()
                    .fill(isUnlocked ? color.opacity(0.12) : Color(hex: "#f1f5f9"))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isUnlocked ? color : Color(hex: "#cbd5e1"))
            }
            .shadow(color: isUnlocked ? color.opacity(0.25) : .clear, radius: 8, y: 3)

            Text(title)
                .font(.custom("Poppins-SemiBold", size: 10))
                .foregroundStyle(isUnlocked ? Color(hex: "#1a1a2e") : Color(hex: "#94a3b8"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 68)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isUnlocked)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - All Achievements Sheet
// MARK: ═══════════════════════════════════════════════════════════

struct AllAchievementsSheet: View {
    @EnvironmentObject var langManager: LanguageManager
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Group by rarity
    private var grouped: [(String, [Achievement])] {
        let order: [AchievementRarity] = [.common, .rare, .epic, .legendary]
        return order.compactMap { rarity in
            let items = achievements.filter { $0.rarity == rarity }
            guard !items.isEmpty else { return nil }
            return (rarity.label, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#f4f6f9").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(grouped, id: \.0) { groupName, items in
                            VStack(alignment: .leading, spacing: 14) {
                                // Section header
                                HStack(spacing: 8) {
                                    Text(groupName)
                                        .font(.custom("Poppins-Bold", size: 15))
                                        .foregroundStyle(Color(hex: "#1a1a2e"))

                                    let unlocked = items.filter { $0.isUnlocked }.count
                                    Text("\(unlocked)/\(items.count)")
                                        .font(.custom("Poppins-Regular", size: 12))
                                        .foregroundStyle(.secondary)
                                }

                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(items) { ach in
                                        AchievementGridCell(achievement: ach)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(langManager.s(.achievementAllTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: "#94a3b8"))
                    }
                }
            }
        }
    }
}

private struct AchievementGridCell: View {
    @EnvironmentObject var langManager: LanguageManager
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? achievement.color.opacity(0.13)
                          : Color(hex: "#f1f5f9"))
                    .frame(width: 64, height: 64)

                Circle()
                    .strokeBorder(
                        achievement.isUnlocked
                            ? LinearGradient(
                                colors: achievement.rarity.gradientColors,
                                startPoint: .topLeading, endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color(hex: "#e2e8f0"), Color(hex: "#e2e8f0")],
                                startPoint: .top, endPoint: .bottom
                              ),
                        lineWidth: achievement.isUnlocked ? 2.5 : 1.5
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: achievement.icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(achievement.isUnlocked
                                     ? achievement.color
                                     : Color(hex: "#cbd5e1"))
            }
            .shadow(color: achievement.isUnlocked ? achievement.color.opacity(0.3) : .clear,
                    radius: 8, y: 3)

            Text(achievement.title)
                .font(.custom("Poppins-SemiBold", size: 11))
                .foregroundStyle(achievement.isUnlocked
                                  ? Color(hex: "#1a1a2e")
                                  : Color(hex: "#94a3b8"))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if achievement.isUnlocked {
                Text(langManager.s(.achievementUnlockedBadge))
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundStyle(achievement.rarity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(achievement.rarity.color.opacity(0.1), in: Capsule())
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#cbd5e1"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.55)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Character Picker Sheet
// MARK: ═══════════════════════════════════════════════════════════

struct CharacterPickerSheet: View {
    @EnvironmentObject var langManager: LanguageManager
    @Binding var selected: String?
    @Environment(\.dismiss) private var dismiss

    /// Asset adlarını buraya ekle (kullanıcı dolduracak)
    private let characters: [String] = [
        // Örnek: "char_1", "char_2", "char_3"
        // Kendi karakterlerini xcassets'e ekleyip buraya yaz
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if characters.isEmpty {
                    // Placeholder — karakterler eklenince dolacak
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 56))
                            .foregroundStyle(Color(hex: "#E8409C").opacity(0.6))
                        Text("Karakterler yakında!")
                            .font(.custom("Feather-Bold", size: 18))
                            .foregroundStyle(Color(hex: "#1a1a2e"))
                        Text("xcassets'e karakter görselleri eklenecek")
                            .font(.custom("Feather-Bold", size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(characters, id: \.self) { name in
                                Button {
                                    selected = (selected == name) ? nil : name
                                    dismiss()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "#f1f5f9"))
                                            .frame(width: 90, height: 90)

                                        Image(name)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())

                                        if selected == name {
                                            Circle()
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [Color(hex: "#FFAA44"), Color(hex: "#E8409C")],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 3
                                                )
                                                .frame(width: 94, height: 94)

                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color(hex: "#E8409C"))
                                                .offset(x: 32, y: -32)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(langManager.s(.profileClose)) { dismiss() }
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(Color(hex: "#E8409C"))
                }
            }
            .background(Color(hex: "#f4f6f9").ignoresSafeArea())
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
    }
}


// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Guest Login Sheet
// MARK: ═══════════════════════════════════════════════════════════

struct GuestLoginSheet: View {
    @EnvironmentObject var langManager: LanguageManager
    var onEmailSelected: (() -> Void)? = nil

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#f97316"), Color(hex: "#E8409C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 8)

                        Text(langManager.s(.profileSaveProgress))
                            .font(.custom("Feather-Bold", size: 22))
                            .foregroundStyle(Color(hex: "#1a1a2e"))

                        Text(langManager.s(.profileSaveProgressDesc))
                            .font(.custom("Feather-Bold", size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)

                    // Buttons
                    VStack(spacing: 12) {
                        // Apple
                        GuestLoginButton(
                            icon: "apple.logo",
                            label: langManager.s(.profileLoginApple),
                            background: Color.black,
                            foreground: .white
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                authManager.handleAppleLogin()
                            }
                        }

                        // Google
                        GuestLoginButton(
                            icon: "g.circle.fill",
                            label: langManager.s(.profileLoginGoogle),
                            background: Color(hex: "#f1f5f9"),
                            foreground: Color(hex: "#1a1a2e")
                        ) {
                            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                  let vc = windowScene.windows.first?.rootViewController else { return }
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                authManager.handleGoogleSignIn(with: vc)
                            }
                        }

                        // E-posta
                        GuestLoginButton(
                            icon: "envelope.fill",
                            label: langManager.s(.profileLoginEmail),
                            background: Color(hex: "#f97316"),
                            foreground: .white
                        ) {
                            onEmailSelected?()
                        }
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.custom("Feather-Bold", size: 13))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(langManager.s(.profileClose)) { dismiss() }
                        .font(.custom("Feather-Bold", size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .background(Color(hex: "#f4f6f9").ignoresSafeArea())
        }
        .presentationDetents([.large])
        .presentationCornerRadius(28)
        .onChange(of: authManager.isAnonymous) { anonymous in
            if !anonymous { dismiss() }
        }
    }

}

private struct GuestLoginButton: View {
    let icon: String
    let label: String
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(.custom("Feather-Bold", size: 15))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Username Setup Popup (mandatory, kapatılamaz)
private struct UsernameSetupPopup: View {
    @EnvironmentObject var langManager: LanguageManager
    let initialUsername: String
    let isFirstSetup: Bool   // true → zorunlu (ilk login), false → profil butonu (1 kez hak)
    let onDismiss: () -> Void
    let onSave: (String) -> Void

    @State private var username: String = ""
    @State private var isSaving = false
    @FocusState private var focused: Bool

    private var isValid: Bool {
        username.trimmingCharacters(in: .whitespaces).count >= 3
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close butonu — sadece profil butonundan açılınca
                if !isFirstSetup {
                    HStack {
                        Spacer()
                        Button {
                            focused = false
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#64748b"))
                                .padding(10)
                                .background(Color(hex: "#f1f5f9"), in: Circle())
                        }
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                } else {
                    // İlk login → close yok, sadece top padding
                    Spacer().frame(height: 24)
                }

                MascotAnimationView(width: 110, height: 110)

                Text(isFirstSetup ? langManager.s(.profileSetUsername) : langManager.s(.profileChangeUsername))
                    .font(.custom("Feather-Bold", size: 20))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                    .padding(.top, 6)

                Text(isFirstSetup
                     ? langManager.s(.profileUsernameLeaderboard)
                     : langManager.s(.profileUsernameOneChange))
                    .font(.custom("Feather-Bold", size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                TextField(langManager.s(.profileUsernamePlaceholder), text: $username)
                    .font(.custom("Feather-Bold", size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color(hex: "#f4f6f9"), in: RoundedRectangle(cornerRadius: 14))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focused)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                Button {
                    guard isValid, !isSaving else { return }
                    isSaving = true
                    focused = false
                    onSave(username.trimmingCharacters(in: .whitespaces))
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text(langManager.s(.profileSave))
                                .font(.custom("Feather-Bold", size: 16))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: isValid
                                ? [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange]
                                : [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isValid || isSaving)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 28)
            // Keyboard popup'ı yukarı kaydırmasın
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            let generics = ["Apple User", "Google User", "Guest"]
            let cleaned = initialUsername.trimmingCharacters(in: .whitespaces)
            if !generics.contains(where: { cleaned.hasPrefix($0) }) && cleaned.count >= 3 {
                username = cleaned
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
