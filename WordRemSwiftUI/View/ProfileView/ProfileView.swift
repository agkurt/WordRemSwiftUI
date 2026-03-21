//
//  ProfileView.swift
//  WordRemSwiftUI
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var vm = ProfileScreenViewModel()
    @State private var showPaywall = false
    @State private var showGuestLoginSheet = false
    @State private var showLoginScreen = false
    @State private var showUsernameSetup = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#f4f6f9").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header (PathHeaderView ile aynı stil) ──────────
                profileHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Guest login banner
                        if authManager.isAnonymous { guestLoginBanner }

                        // Avatar + isim + level + upgrade butonu
                        heroCard

                        // Kompakt istatistikler (4 kutu küçük)
                        compactStatsGrid

                        // Başarımlar
                        achievementsSection

                        // Alt aksiyonlar
                        VStack(spacing: 10) {
                            if !authManager.isAnonymous, (vm.user?.usernameChanges ?? 0) == 1 {
                                changeUsernameButton
                            }
                            signOutButton
                        }

                        Spacer(minLength: 24)
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
                    Text("İlerlemenizi Kaydedin")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                    Text("Hesap oluşturun, her şey güvende kalsın")
                        .font(.custom("Poppins-Regular", size: 12))
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
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(AL.f(.profileLevelFormat, vm.userLevel))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            // XP pill
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#f59e0b"))
                Text("\(vm.user?.totalXp ?? 0) XP")
                    .font(.custom("Poppins-Bold", size: 14))
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
                    .font(.custom("Poppins-Bold", size: 14))
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
                            .font(.custom("Poppins-Bold", size: 26))
                            .foregroundStyle(Color(hex: "#64748b"))
                    }
                }
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.username)
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    // Level + XP + Streak inline
                    HStack(spacing: 8) {
                        Label(AL.f(.profileLevelFormat, vm.userLevel), systemImage: "star.fill")
                            .font(.custom("Poppins-SemiBold", size: 11))
                            .foregroundStyle(Color(hex: "#f59e0b"))
                        Label("\(vm.user?.totalXp ?? 0) XP", systemImage: "bolt.fill")
                            .font(.custom("Poppins-SemiBold", size: 11))
                            .foregroundStyle(Color(hex: "#64748b"))
                        Label("\(vm.user?.streakDays ?? 0)", systemImage: "flame.fill")
                            .font(.custom("Poppins-SemiBold", size: 11))
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().padding(.horizontal, 16)

            // Upgrade Pro butonu — hero card içinde, her zaman görünür
            Button {
                EventManager.shared.logPaywallEvent("upgrade_tapped_profile")
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(AL.s(.profileUpgradePro))
                        .font(.custom("Poppins-Bold", size: 14))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#FFAA44"), Color(hex: "#E8409C"), Color(hex: "#6B22E0")],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .shadow(color: Color(hex: "#E8409C").opacity(0.35), radius: 8, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
    }

    // MARK: - Compact Stats Grid (4 kutu)
    private var compactStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            CompactStatTile(icon: "bolt.fill",              color: Color(hex: "#f59e0b"),
                            label: AL.s(.profileTotalXP),   value: "\(vm.user?.totalXp ?? 0)")
            CompactStatTile(icon: "flame.fill",             color: .orange,
                            label: AL.s(.profileStreak),    value: AL.f(.profileDaysFormat, vm.user?.streakDays ?? 0))
            CompactStatTile(icon: "checkmark.circle.fill",  color: .green,
                            label: AL.s(.profileCompleted), value: "\(vm.stats.completedLevels)")
            CompactStatTile(icon: "target",                 color: Color(hex: "#E8409C"),
                            label: AL.s(.profileAccuracy),  value: String(format: "%.0f%%", vm.stats.accuracy))
        }
    }

    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AL.s(.profileAchievements))
                .font(.custom("Poppins-SemiBold", size: 17))
                .foregroundStyle(Color(hex: "#1a1a2e"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(icon: "flame.fill",   title: AL.s(.profileFirstStreak),
                                     isUnlocked: (vm.user?.streakDays ?? 0) >= 1, color: .orange)
                    AchievementBadge(icon: "star.fill",    title: AL.s(.profile5Levels),
                                     isUnlocked: vm.stats.completedLevels >= 5, color: Color(hex: "#FFAA44"))
                    AchievementBadge(icon: "bolt.fill",    title: AL.s(.profile100XP),
                                     isUnlocked: (vm.user?.totalXp ?? 0) >= 100, color: Color(hex: "#f59e0b"))
                    AchievementBadge(icon: "target",       title: AL.s(.profileSharpEye),
                                     isUnlocked: vm.stats.accuracy >= 90, color: Color(hex: "#E8409C"))
                    AchievementBadge(icon: "crown.fill",   title: AL.s(.profile500XP),
                                     isUnlocked: (vm.user?.totalXp ?? 0) >= 500, color: Color(hex: "#6B22E0"))
                }
            }
        }
    }

    // MARK: - Change Username (1 kereye mahsus)
    private var changeUsernameButton: some View {
        Button { showUsernameSetup = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                Text("Kullanıcı Adını Değiştir")
                    .font(.custom("Poppins-SemiBold", size: 14))
            }
            .foregroundStyle(AppTheme.Colors.primaryOrange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.Colors.primaryOrange.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.primaryOrange.opacity(0.2), lineWidth: 1))
            )
        }
    }

    // MARK: - Sign Out
    private var signOutButton: some View {
        Button { authManager.signOut() } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                Text(AL.s(.profileSignOut))
                    .font(.custom("Poppins-SemiBold", size: 14))
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

    func loadProfile() async {
        isLoading = true
        do {
            user  = try await SupabaseDataService.shared.fetchUserProfile()
            stats = try await SupabaseDataService.shared.fetchUserStats()
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
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(label)
                    .font(.custom("Poppins-Regular", size: 11))
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
                    .fill(isUnlocked ? color.opacity(0.15) : Color(hex: "#e2e8f0"))
                    .frame(width: 58, height: 58)
                    .shadow(color: isUnlocked ? color.opacity(0.2) : .clear, radius: 6, y: 3)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isUnlocked ? color : .gray.opacity(0.35))
            }
            Text(title)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundStyle(isUnlocked ? Color(hex: "#1a1a2e") : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 72)
        .opacity(isUnlocked ? 1.0 : 0.45)
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Character Picker Sheet
// MARK: ═══════════════════════════════════════════════════════════

struct CharacterPickerSheet: View {
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
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundStyle(Color(hex: "#1a1a2e"))
                        Text("xcassets'e karakter görselleri eklenecek")
                            .font(.custom("Poppins-Regular", size: 13))
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
            .navigationTitle("Karakter Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.custom("Poppins-SemiBold", size: 14))
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

                        Text("İlerlemenizi Kaydedin")
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundStyle(Color(hex: "#1a1a2e"))

                        Text("Hesap oluşturarak XP'leriniz, serileriniz ve tüm ilerlemeniz güvende kalsın. Uygulamayı silseniz bile her şey yerli yerinde.")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)

                    // Buttons
                    VStack(spacing: 12) {
                        // Apple
                        GuestLoginButton(
                            icon: "apple.logo",
                            label: "Apple ile Devam Et",
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
                            label: "Google ile Devam Et",
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
                            label: "E-posta ile Kayıt Ol",
                            background: Color(hex: "#f97316"),
                            foreground: .white
                        ) {
                            onEmailSelected?()
                        }
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.custom("Poppins-SemiBold", size: 14))
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
                    .font(.custom("Poppins-SemiBold", size: 15))
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

                Text(isFirstSetup ? "Kullanıcı adın ne olsun?" : "Kullanıcı adını değiştir")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                    .padding(.top, 6)

                Text(isFirstSetup
                     ? "Bu isim leaderboard ve profilinde görünecek."
                     : "Bu hakkı yalnızca 1 kez kullanabilirsin.\nLeaderboard ve profilinde güncellenir.")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                TextField("Kullanıcı adı (min. 3 karakter)", text: $username)
                    .font(.custom("Poppins-Medium", size: 15))
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
                            Text("Kaydet")
                                .font(.custom("Poppins-SemiBold", size: 16))
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
