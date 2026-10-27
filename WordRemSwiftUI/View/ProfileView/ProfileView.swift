//
//  ProfileView.swift
//  WordRemSwiftUI
//

import SwiftUI
import GameKit

struct ProfileView: View {

    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openURL) private var openURL
    @StateObject private var vm = ProfileScreenViewModel()
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var iap = InAppPurchaseManager.shared
    @ObservedObject private var gameCenter = GameCenterService.shared
    @State private var showPaywall = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showManageSubscription = false
    @State private var showUsernameSetup = false
    @State private var showAllAchievements = false
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                profileHeader
                heroCard
                statsOverviewRow
                streakCard
                learningProgressCard
                achievementsSection
                settingsSection
                accountSection
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 48)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        // Kaydırınca içerik saat/pil satırının altına girmesin
        .overlay(alignment: .top) {
            DS.Colors.paper.frame(height: 0).ignoresSafeArea(edges: .top)
        }
        .paperBackground()
        .navigationBarHidden(true)
        .task { await vm.loadProfile() }
        .sheet(isPresented: $showPrivacy) {
            SafariWebView(url: URL(string: "https://api.wordremai.app/privacy")!)
        }
        .sheet(isPresented: $showTerms) {
            SafariWebView(url: URL(string: "https://api.wordremai.app/terms")!)
        }
        // Apple'ın kendi abonelik ekranı: plan değiştirme / iptal
        .manageSubscriptionsSheet(isPresented: $showManageSubscription)
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
            OnboardingPaywallView(onContinue: { showPaywall = false }, entryPoint: "profile")
        }
        // Profil sekmesine her dönüşte (ör. quiz sonrası) güncel ilerlemeyi göster
        .onReceive(NotificationCenter.default.publisher(for: UserStore.didChangeNotification)) { _ in
            Task { await vm.loadProfile() }
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        Text(langManager.s(.tabProfile))
            .font(DS.Font.display(34, weight: .bold))
            .foregroundStyle(DS.Colors.ink)
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
                    // Bu ad yalnızca öğretmenin hitabı; sıralamada Game Center adı görünür (aşağıda)
                    Text(loc(["Öğretmen sana böyle seslenir", "Your tutor calls you", "Dein Tutor nennt dich", "Ton tuteur t'appelle",
                              "Tu tutor te llama", "Il tutor ti chiama", "Репетитор называет тебя", "老师这样称呼你"]))
                        .font(DS.Font.ui(12, weight: .medium))
                        .foregroundStyle(DS.Colors.muted)
                    HStack(spacing: 8) {
                        Text(vm.username)
                            .font(DS.Font.display(24))
                            .foregroundStyle(DS.Colors.ink)
                            .lineLimit(1)

                        if true {
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
                    leaderboardNameRow
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }

            if !iap.isPremium {
                // Upgrade Pro butonu
                Button {
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

                let unlockedCount = achievementService.localized.filter { $0.isUnlocked }.count
                Text("\(unlockedCount)/\(achievementService.localized.count)")
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
            let sorted = achievementService.localized.sorted {
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
            AllAchievementsSheet(achievements: achievementService.localized)
        }
    }

    // MARK: - Account (hesap yok: iCloud senkron notu + ilerlemeyi sıfırla)
    /// Sıralamadaki ad Game Center'dan gelir; uygulama içinden değişmez, Game Center profilinden değişir
    @ViewBuilder
    private var leaderboardNameRow: some View {
        if gameCenter.isAuthenticated, let name = gameCenter.playerName {
            HStack(spacing: 6) {
                Image(systemName: "trophy").font(.system(size: 11, weight: .semibold))
                Text(loc(["Sıralamada: ", "On leaderboard: ", "In der Rangliste: ", "Au classement : ",
                          "En la clasificación: ", "In classifica: ", "В рейтинге: ", "排行榜：" ]) + name)
                    .lineLimit(1)
                Button(loc(["Değiştir", "Change", "Ändern", "Modifier", "Cambiar", "Modifica", "Изменить", "更改"])) {
                    GKAccessPoint.shared.trigger(state: .localPlayerProfile) {}
                }
                .font(DS.Font.ui(12, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
            }
            .font(DS.Font.ui(12))
            .foregroundStyle(DS.Colors.muted)
        } else {
            Text(loc(["Sıralamada görünmek için Ayarlar → Game Center'dan giriş yap",
                      "To appear on the leaderboard, sign in under Settings → Game Center",
                      "Für die Rangliste: Einstellungen → Game Center anmelden",
                      "Pour le classement : Réglages → Game Center",
                      "Para la clasificación: Ajustes → Game Center",
                      "Per la classifica: Impostazioni → Game Center",
                      "Для рейтинга войдите: Настройки → Game Center",
                      "要上排行榜，请在 设置 → Game Center 登录"]))
                .font(DS.Font.ui(12))
                .foregroundStyle(DS.Colors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Ayarlar: ana dil + yasal metinler
    private func loc(_ v: [String]) -> String {
        let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
        let i = order.firstIndex(of: langManager.currentLanguageCode) ?? 1
        return v.indices.contains(i) ? v[i] : v[1]
    }

    private var settingsSection: some View {
        let target = (UserDefaults.standard.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased()
        return VStack(alignment: .leading, spacing: 12) {
            Text(LearningText.settings)
                .font(DS.Font.display(22, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
            VStack(spacing: 0) {
                Menu {
                    ForEach(LanguageManager.supportedCodes.filter { $0 != target }, id: \.self) { code in
                        Button {
                            Track.language("ui_change", from: langManager.currentLanguageCode, to: code, entryPoint: "profile")
                            langManager.setLanguage(code)
                        } label: {
                            Text("\(LearningLanguages.flags[code] ?? "") \(Self.endonym(code))")
                        }
                    }
                } label: {
                    settingsRow(icon: "globe",
                                title: loc(["Ana dil", "Native language", "Muttersprache", "Langue maternelle", "Idioma nativo", "Lingua madre", "Родной язык", "母语"]),
                                value: Self.endonym(langManager.currentLanguageCode))
                }
                if iap.isPremium {
                    Divider().padding(.leading, 48)
                    Button { showManageSubscription = true } label: {
                        settingsRow(icon: "creditcard",
                                    title: loc(["Aboneliği yönet", "Manage subscription", "Abo verwalten", "Gérer l'abonnement", "Gestionar suscripción", "Gestisci abbonamento", "Управление подпиской", "管理订阅"]))
                    }
                }
                Divider().padding(.leading, 48)
                Button { openURL(ReviewPrompt.writeReviewURL) } label: {
                    settingsRow(icon: "star",
                                title: loc(["WordRem AI'ı puanla", "Rate WordRem AI", "WordRem AI bewerten", "Noter WordRem AI", "Valorar WordRem AI", "Valuta WordRem AI", "Оценить WordRem AI", "为 WordRem AI 评分"]))
                }
                Divider().padding(.leading, 48)
                Button { showPrivacy = true } label: {
                    settingsRow(icon: "hand.raised",
                                title: loc(["Gizlilik Politikası", "Privacy Policy", "Datenschutz", "Confidentialité", "Privacidad", "Privacy", "Конфиденциальность", "隐私政策"]))
                }
                Divider().padding(.leading, 48)
                Button { showTerms = true } label: {
                    settingsRow(icon: "doc.text",
                                title: loc(["Kullanım Şartları", "Terms of Use", "Nutzungsbedingungen", "Conditions d'utilisation", "Términos de uso", "Termini d'uso", "Условия использования", "使用条款"]))
                }
                #if DEBUG
                Divider().padding(.leading, 48)
                Button { FreshUser.isOn ? FreshUser.stop() : FreshUser.start() } label: {
                    settingsRow(icon: "person.badge.plus",
                                title: FreshUser.isOn ? "Test: gerçek hesaba dön" : "Test: yeni kullanıcı olarak başla")
                }
                #endif
            }
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(DS.Colors.line, lineWidth: 1))
        }
    }

    /// Dil seçicide her dil kendi adıyla görünür (Deutsch, Français…), herkes kendi dilini bulsun
    private static func endonym(_ code: String) -> String {
        let loc = Locale(identifier: code)
        let name = loc.localizedString(forLanguageCode: code) ?? code
        return name.prefix(1).uppercased(with: loc) + name.dropFirst()
    }

    private func settingsRow(icon: String, title: String, value: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DS.Colors.accent)
                .frame(width: 22)
            Text(title)
                .font(DS.Font.ui(16, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
            Spacer()
            if let value {
                Text(value)
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.muted)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.muted)
        }
        .padding(.horizontal, 16).padding(.vertical, 15)
        .contentShape(Rectangle())
    }

    private var accountSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "icloud")
                    .foregroundStyle(DS.Colors.muted)
                Text(langManager.s(.profileSyncNote))
                    .font(DS.Font.ui(13))
                    .foregroundStyle(DS.Colors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            Button { showResetConfirm = true } label: {
                Text(langManager.s(.profileResetProgress))
                    .font(DS.Font.ui(13, weight: .medium))
                    .foregroundStyle(DS.Colors.danger)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .alert(langManager.s(.profileResetTitle), isPresented: $showResetConfirm) {
                Button(langManager.s(.profileResetConfirm), role: .destructive) {
                    authManager.resetAllProgress()
                }
                Button(langManager.s(.profileDeleteCancel), role: .cancel) {}
            } message: {
                Text(langManager.s(.profileResetMessage))
            }
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
            user  = try await DataService.shared.fetchUserProfile()
            stats = try await DataService.shared.fetchUserStats()
            // Fetch already-saved achievements (no new unlock toast on profile open)
            await AchievementService.shared.fetchSaved()
        } catch {
            print("❌ Profile load error: \(error)")
        }
        isLoading = false
    }

    func updateUsername(_ newUsername: String) async {
        DataService.shared.updateUsername(newUsername)
        user = try? await DataService.shared.fetchUserProfile()
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

    private static func loc(_ code: String, _ v: [String]) -> String {
        let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
        let i = order.firstIndex(of: code) ?? 1
        return v.indices.contains(i) ? v[i] : v[1]
    }

    private var isValid: Bool {
        username.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var body: some View {
        ZStack {
            DS.Colors.ink.opacity(0.4)
                .ignoresSafeArea()

            PaperCard(padding: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    // Close butonu — her zaman (ilk kurulumda da atlanabilir; Apple 4.8 / 5.1.1)
                    HStack(alignment: .top) {
                        Text(Self.loc(langManager.currentLanguageCode, ["Öğretmen sana nasıl seslensin?", "What should your tutor call you?",
                            "Wie soll dich dein Tutor nennen?", "Comment ton tuteur doit-il t'appeler ?", "¿Cómo quieres que te llame tu tutor?",
                            "Come vuoi che ti chiami il tuo tutor?", "Как репетитору тебя называть?", "老师该怎么称呼你？"]))
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

                    Text(Self.loc(langManager.currentLanguageCode, [
                        "Sesli derslerde öğretmen seni bu isimle çağırır. İstediğin zaman değiştirebilirsin. Sıralamada Game Center adın görünür.",
                        "Your tutor uses this name in voice lessons. You can change it anytime. The leaderboard shows your Game Center name.",
                        "Dein Tutor nutzt diesen Namen in den Sprachlektionen. Du kannst ihn jederzeit ändern. In der Rangliste steht dein Game-Center-Name.",
                        "Ton tuteur utilise ce prénom pendant les leçons. Tu peux le changer à tout moment. Le classement affiche ton nom Game Center.",
                        "Tu tutor usa este nombre en las clases de voz. Puedes cambiarlo cuando quieras. En la clasificación aparece tu nombre de Game Center.",
                        "Il tutor usa questo nome nelle lezioni vocali. Puoi cambiarlo quando vuoi. In classifica appare il tuo nome Game Center.",
                        "Репетитор обращается к тебе по этому имени. Его можно изменить в любой момент. В рейтинге показывается имя из Game Center.",
                        "老师会在语音课中这样称呼你，随时可以修改。排行榜显示你的 Game Center 名称。"]))
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
                        .textInputAutocapitalization(.words)
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
