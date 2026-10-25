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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                profileHeader
                if authManager.isAnonymous { guestLoginBanner }
                heroCard
                statsOverviewRow
                streakCard
                learningProgressCard
                achievementsSection
                VStack(spacing: 14) {
                    signOutButton
                    deleteAccountButton
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 48)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .paperBackground()
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
            LoginScreenView(showsCloseButton: true)
                .environmentObject(authManager)
                .environmentObject(langManager)
        }
        // Guest → Apple/Google girişi: loading + hata geri bildirimi
        .overlay {
            if authManager.isAuthenticating || authManager.isDeleting {
                DS.Colors.ink.opacity(0.3).ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .tint(DS.Colors.ink)
                            .frame(width: 64, height: 64)
                            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
                    )
            }
        }
        .alert(langManager.s(.loginFailedTitle), isPresented: Binding(
            get: { authManager.loginError != nil && !showLoginScreen && !showGuestLoginSheet },
            set: { if !$0 { authManager.loginError = nil } }
        )) {
            Button(langManager.s(.paywallOk), role: .cancel) { authManager.loginError = nil }
        } message: {
            Text(authManager.loginError ?? "")
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        Text(langManager.s(.tabProfile))
            .font(DS.Font.display(34, weight: .bold))
            .foregroundStyle(DS.Colors.ink)
    }

    // MARK: - Guest Login Banner
    private var guestLoginBanner: some View {
        PaperCard(padding: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(langManager.s(.profileSaveProgress))
                    .font(DS.Font.display(22))
                    .foregroundStyle(DS.Colors.ink)
                Text(langManager.s(.profileSaveProgressHint))
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button(langManager.s(.leaderboardSignIn)) { showGuestLoginSheet = true }
                    .buttonStyle(InkButtonStyle())
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Hero (kimlik + Pro durumu)
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                Text(vm.initials)
                    .font(DS.Font.display(24))
                    .foregroundStyle(DS.Colors.ink)
                    .frame(width: 56, height: 56)
                    .background(DS.Colors.paperSunken, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    if iap.isPremium {
                        Eyebrow(text: "WordRem Pro", color: DS.Colors.slate)
                    }
                    HStack(spacing: 8) {
                        Text(vm.username)
                            .font(DS.Font.display(24))
                            .foregroundStyle(DS.Colors.ink)
                            .lineLimit(1)

                        if !authManager.isAnonymous, (vm.user?.usernameChanges ?? 0) == 1 {
                            Button { showUsernameSetup = true } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(DS.Colors.inkSoft)
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
                            }
                        }
                    }
                    Text("\(langManager.f(.profileLevelFormat, vm.userLevel)) · \(vm.user?.totalXp ?? 0) XP")
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                }
                Spacer(minLength: 0)
            }

            if !iap.isPremium {
                // Upgrade Pro butonu
                Button {
                    EventManager.shared.logPaywallEvent("upgrade_tapped_profile")
                    showPaywall = true
                } label: {
                    Label(langManager.s(.profileUpgradePro), systemImage: "crown")
                }
                .buttonStyle(OutlineButtonStyle(tint: DS.Colors.slate))
            }
        }
    }

    // MARK: - Stats Overview Row
    private var statsOverviewRow: some View {
        HStack(spacing: 0) {
            ProfileStat(value: "\(vm.stats.totalAttempts)", label: AL.s(.profTotalQuestions))
            ProfileHairline()
            ProfileStat(value: String(format: "%.0f%%", vm.stats.accuracy), label: AL.s(.hcAccuracy))
            ProfileHairline()
            ProfileStat(value: "\(vm.stats.completedLevels)", label: AL.s(.profCompleted))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 20) {
                Text(AL.s(.profStreak))
                    .font(DS.Font.display(20))
                    .foregroundStyle(DS.Colors.ink)

                HStack(spacing: 0) {
                    ProfileStat(value: "\(vm.user?.streakDays ?? 0)",
                                label: AL.s(.hcDailyStreak),
                                tint: (vm.user?.streakDays ?? 0) > 0 ? DS.Colors.gold : DS.Colors.ink)
                    ProfileHairline()
                    ProfileStat(value: "\(vm.bestStreak)", label: AL.s(.hcBestStreak))
                }

                Rectangle().fill(DS.Colors.line).frame(height: 1)

                // Haftalık Takvim
                weeklyCalendarView
            }
        }
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
        // Pzt..Paz sırası — seçili dile göre kısa gün adları
        var dayFormatter = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: langManager.currentLanguageCode)
        let symbols = dayFormatter.shortWeekdaySymbols          // Sun=0
        let dayNames = Array(symbols[1...]) + [symbols[0]]      // Mon=0

        return HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                let weekdayIdx = (calendar.component(.weekday, from: day) + 5) % 7 // Mon=0
                let daysSinceLastActive = calendar.dateComponents([.day], from: day, to: lastActive).day ?? 99
                let isActive = daysSinceLastActive >= 0 && daysSinceLastActive < streak
                let isToday = calendar.isDateInToday(day)

                VStack(spacing: 8) {
                    Text(dayNames[weekdayIdx])
                        .font(DS.Font.ui(11, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? DS.Colors.ink : DS.Colors.muted)

                    ZStack {
                        Circle()
                            .fill(isActive ? DS.Colors.ink : Color.clear)
                        Circle()
                            .stroke(isToday ? DS.Colors.gold : (isActive ? DS.Colors.ink : DS.Colors.line),
                                    lineWidth: isToday ? 2 : 1)
                        if isActive {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DS.Colors.paperRaised)
                        }
                    }
                    .frame(width: 30, height: 30)
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

        return PaperCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(AL.s(.hcProgress))
                    .font(DS.Font.display(20))
                    .foregroundStyle(DS.Colors.ink)

                // XP Level Progress
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(AL.f(.profLevelN, currentLevel))
                            .font(DS.Font.ui(15, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                        Spacer()
                        Text("\(xp) XP")
                            .font(DS.Font.ui(13, weight: .medium))
                            .foregroundStyle(DS.Colors.muted)
                            .monospacedDigit()
                    }

                    ProfileProgressBar(progress: xpProgress)

                    HStack {
                        Text("\(xpInLevel)/\(xpPerLevel) XP")
                        Spacer()
                        Text(AL.s(.profNextLevel))
                    }
                    .font(DS.Font.ui(12))
                    .foregroundStyle(DS.Colors.muted)
                }

                Rectangle().fill(DS.Colors.line).frame(height: 1)

                HStack(spacing: 0) {
                    ProfileStat(value: "\(xp)", label: AL.s(.profTotalXP), size: 22)
                    ProfileHairline(height: 32)
                    ProfileStat(value: "\(vm.stats.completedLevels)", label: AL.s(.profLevels), size: 22)
                    ProfileHairline(height: 32)
                    ProfileStat(value: String(format: "%.0f%%", vm.stats.accuracy),
                                label: AL.s(.hcAccuracy), size: 22)
                }
            }
        }
    }

    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .firstTextBaseline) {
                Text(langManager.s(.profileAchievements))
                    .font(DS.Font.display(20))
                    .foregroundStyle(DS.Colors.ink)

                let unlockedCount = achievementService.all.filter { $0.isUnlocked }.count
                Text("\(unlockedCount)/\(achievementService.all.count)")
                    .font(DS.Font.ui(13, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
                    .monospacedDigit()

                Spacer()

                Button {
                    showAllAchievements = true
                } label: {
                    Text(langManager.s(.achievementViewMore))
                        .font(DS.Font.ui(14, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                }
            }

            // İlk 8 rozet (önce açılanlar, sonra kilitliler)
            let sorted = achievementService.all.sorted {
                if $0.isUnlocked != $1.isUnlocked { return $0.isUnlocked }
                return false
            }
            let preview = Array(sorted.prefix(8))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                      alignment: .center, spacing: 18) {
                ForEach(preview) { ach in
                    ProfileAchievementCell(icon: ach.icon, title: ach.title, isUnlocked: ach.isUnlocked)
                }
            }
        }
        .sheet(isPresented: $showAllAchievements) {
            AllAchievementsSheet(achievements: achievementService.all)
        }
    }

    // MARK: - Sign Out
    private var signOutButton: some View {
        Button { authManager.signOut() } label: {
            Label(langManager.s(.profileSignOut), systemImage: "rectangle.portrait.and.arrow.right")
        }
        .buttonStyle(OutlineButtonStyle())
    }

    // MARK: - Delete Account
    private var deleteAccountButton: some View {
        Button { showDeleteConfirm = true } label: {
            Text(langManager.s(.profileDeleteAccount))
                .font(DS.Font.ui(13, weight: .medium))
                .foregroundStyle(DS.Colors.danger)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .alert(langManager.s(.profileDeleteTitle), isPresented: $showDeleteConfirm) {
            Button(langManager.s(.profileDeleteConfirm), role: .destructive) {
                authManager.deleteAccount()
            }
            Button(langManager.s(.profileDeleteCancel), role: .cancel) {}
        } message: {
            Text(langManager.s(.profileDeleteMessage))
        }
        .alert(langManager.s(.profileDeleteTitle), isPresented: Binding(
            get: { authManager.deleteError != nil },
            set: { if !$0 { authManager.deleteError = nil } }
        )) {
            Button(langManager.s(.paywallOk), role: .cancel) { authManager.deleteError = nil }
        } message: {
            Text(langManager.s(.profileDeleteFailed))
        }
        .disabled(authManager.isDeleting)
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

/// Serif sayı + soluk etiket (TodayView istatistik satırı)
private struct ProfileStat: View {
    let value: String
    let label: String
    var tint: Color = DS.Colors.ink
    var size: CGFloat = 28

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DS.Font.display(size, weight: .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(DS.Font.ui(12, weight: .medium))
                .foregroundStyle(DS.Colors.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Dikey ince ayraç
private struct ProfileHairline: View {
    var height: CGFloat = 40
    var body: some View {
        Rectangle().fill(DS.Colors.line).frame(width: 1, height: height)
    }
}

/// 4pt ince ilerleme çubuğu
private struct ProfileProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.Colors.line)
                Capsule()
                    .fill(DS.Colors.ink)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 4)
    }
}

/// Dolu SF Symbol yerine çizgisel varyantı (varsa)
private func profileOutlineSymbol(_ name: String) -> String {
    guard name.hasSuffix(".fill") else { return name }
    let outline = name.replacingOccurrences(of: ".fill", with: "")
    return UIImage(systemName: outline) != nil ? outline : name
}

/// Rozet: çizgisel ikon (açık → mürekkep, kilitli → soluk + kilit)
private struct ProfileAchievementCell: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    var circle: CGFloat = 52

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: profileOutlineSymbol(icon))
                    .font(.system(size: circle * 0.38, weight: .regular))
                    .foregroundStyle(isUnlocked ? DS.Colors.ink : DS.Colors.muted.opacity(0.7))
                    .frame(width: circle, height: circle)
                    .background(isUnlocked ? DS.Colors.paperRaised : Color.clear, in: Circle())
                    .overlay(Circle().stroke(isUnlocked ? DS.Colors.ink.opacity(0.85) : DS.Colors.line,
                                             lineWidth: 1))

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(DS.Colors.muted)
                        .frame(width: 18, height: 18)
                        .background(DS.Colors.paper, in: Circle())
                        .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
                        .offset(x: 2, y: 2)
                }
            }

            Text(title)
                .font(DS.Font.ui(11, weight: .medium))
                .foregroundStyle(isUnlocked ? DS.Colors.inkSoft : DS.Colors.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    Text(langManager.s(.achievementAllTitle))
                        .font(DS.Font.display(30, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)

                    ForEach(grouped, id: \.0) { groupName, items in
                        VStack(alignment: .leading, spacing: 16) {
                            // Section header
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Eyebrow(text: groupName, color: DS.Colors.muted)
                                let unlocked = items.filter { $0.isUnlocked }.count
                                Text("\(unlocked)/\(items.count)")
                                    .font(DS.Font.ui(12, weight: .medium))
                                    .foregroundStyle(DS.Colors.muted)
                                    .monospacedDigit()
                            }

                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(items) { ach in
                                    AchievementGridCell(achievement: ach)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
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
        VStack(spacing: 6) {
            ProfileAchievementCell(icon: achievement.icon,
                                   title: achievement.title,
                                   isUnlocked: achievement.isUnlocked,
                                   circle: 60)
            if achievement.isUnlocked {
                Text(langManager.s(.achievementUnlockedBadge))
                    .font(DS.Font.ui(10, weight: .medium))
                    .foregroundStyle(DS.Colors.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
                    VStack(spacing: 8) {
                        Text("Karakterler yakında!")
                            .font(DS.Font.display(22))
                            .foregroundStyle(DS.Colors.ink)
                        Text("xcassets'e karakter görselleri eklenecek")
                            .font(DS.Font.ui(14))
                            .foregroundStyle(DS.Colors.muted)
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
                                    Image(name)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 88, height: 88)
                                        .clipShape(Circle())
                                        .background(DS.Colors.paperSunken, in: Circle())
                                        .overlay(
                                            Circle().stroke(selected == name ? DS.Colors.ink : DS.Colors.line,
                                                            lineWidth: selected == name ? 2 : 1)
                                        )
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
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
            }
            .paperBackground()
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
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(langManager.s(.profileSaveProgress))
                            .font(DS.Font.display(30, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(langManager.s(.profileSaveProgressDesc))
                            .font(DS.Font.ui(16))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    // Buttons
                    VStack(spacing: 12) {
                        // Apple
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                authManager.handleAppleLogin()
                            }
                        } label: {
                            Label(langManager.s(.profileLoginApple), systemImage: "apple.logo")
                        }
                        .buttonStyle(InkButtonStyle())

                        // Google
                        Button {
                            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                  let vc = windowScene.windows.first?.rootViewController else { return }
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                authManager.handleGoogleSignIn(with: vc)
                            }
                        } label: {
                            Label(langManager.s(.profileLoginGoogle), systemImage: "g.circle")
                        }
                        .buttonStyle(OutlineButtonStyle())

                        // E-posta
                        Button {
                            onEmailSelected?()
                        } label: {
                            Label(langManager.s(.profileLoginEmail), systemImage: "envelope")
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(DS.Font.ui(13, weight: .medium))
                            .foregroundStyle(DS.Colors.danger)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(langManager.s(.profileClose)) { dismiss() }
                        .font(DS.Font.ui(15, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
            }
            .paperBackground()
        }
        .presentationDetents([.large])
        .presentationCornerRadius(28)
        .onChange(of: authManager.isAnonymous) { anonymous in
            if !anonymous { dismiss() }
        }
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
            DS.Colors.ink.opacity(0.4)
                .ignoresSafeArea()

            PaperCard(padding: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    // Close butonu — her zaman (ilk kurulumda da atlanabilir; Apple 4.8 / 5.1.1)
                    HStack(alignment: .top) {
                        Text(isFirstSetup ? langManager.s(.profileSetUsername) : langManager.s(.profileChangeUsername))
                            .font(DS.Font.display(24))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 12)
                        Button {
                            focused = false
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(DS.Colors.inkSoft)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
                        }
                        .accessibilityLabel(langManager.s(.usernameSkip))
                    }

                    Text(isFirstSetup
                         ? langManager.s(.profileUsernameLeaderboard)
                         : langManager.s(.profileUsernameOneChange))
                        .font(DS.Font.ui(14))
                        .foregroundStyle(DS.Colors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    TextField(langManager.s(.profileUsernamePlaceholder), text: $username)
                        .font(DS.Font.ui(16, weight: .medium))
                        .foregroundStyle(DS.Colors.ink)
                        .tint(DS.Colors.accent)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.button)
                                .stroke(focused ? DS.Colors.inkSoft : DS.Colors.line, lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focused)
                        .padding(.top, 20)

                    Button {
                        guard isValid, !isSaving else { return }
                        isSaving = true
                        focused = false
                        onSave(username.trimmingCharacters(in: .whitespaces))
                    } label: {
                        if isSaving {
                            ProgressView().tint(DS.Colors.paperRaised)
                        } else {
                            Text(langManager.s(.profileSave))
                        }
                    }
                    .buttonStyle(InkButtonStyle())
                    .opacity(isValid ? 1 : 0.4)
                    .disabled(!isValid || isSaving)
                    .padding(.top, 16)
                }
            }
            .frame(maxWidth: 440)
            .padding(.horizontal, 24)
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
