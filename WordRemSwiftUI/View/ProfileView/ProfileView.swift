//
//  ProfileView.swift
//  WordRemSwiftUI
//

import SwiftUI
import Lottie

struct ProfileView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var vm = ProfileScreenViewModel()
    @State private var showPaywall = false
    @State private var showLottieTest = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#f4f6f9").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header (PathHeaderView ile aynı stil) ──────────
                profileHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Avatar + İsim + Seviye
                        avatarCard
                        // XP & Streak kartları
                        xpStreakRow
                        // İstatistik ızgarası
                        statsGrid
                        // Başarımlar
                        achievementsSection
                        // Pro yükseltme
                        upgradeButton
                        // Çıkış
                        signOutButton

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await vm.loadProfile() }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(onContinue: { showPaywall = false })
        }
        .sheet(isPresented: $showLottieTest) {
            LottieTestView()
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showLottieTest = true
            } label: {
                Label("Lottie Test", systemImage: "play.circle.fill")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#8b5cf6"), in: Capsule())
                    .shadow(color: Color(hex: "#8b5cf6").opacity(0.4), radius: 8, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
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

    // MARK: - Avatar Card
    private var avatarCard: some View {
        HStack(spacing: 20) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                // Karakter resmi veya baş harfi
                ZStack {
                    Circle()
                        .fill(Color(hex: "#f1f5f9"))
                        .frame(width: 80, height: 80)

                    if let char = vm.selectedCharacter {
                        Image(char)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Text(vm.initials)
                            .font(.custom("Poppins-Bold", size: 32))
                            .foregroundStyle(Color(hex: "#64748b"))
                    }
                }
                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)

                // + butonu
                Button { vm.showCharacterPicker = true } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FFAA44"), Color(hex: "#E8409C")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .offset(x: 2, y: 2)
            }
            .sheet(isPresented: $vm.showCharacterPicker) {
                CharacterPickerSheet(selected: $vm.selectedCharacter)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(vm.username)
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundStyle(Color(hex: "#1a1a2e"))

                if let displayName = vm.user?.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundStyle(.secondary)
                }

                // Level badge
                HStack(spacing: 5) {
                    Image("starss")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(AL.f(.profileLevelFormat, vm.userLevel))
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#FFAA44").opacity(0.15), Color(hex: "#E8409C").opacity(0.15)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
        )
    }

    // MARK: - XP & Streak Row
    private var xpStreakRow: some View {
        HStack(spacing: 14) {
            ProfileStatCard(
                icon: "bolt.fill",
                iconColor: Color(hex: "#f59e0b"),
                title: AL.s(.profileTotalXP),
                value: "\(vm.user?.totalXp ?? 0)",
                bgColors: [Color(hex: "#fef3c7"), Color(hex: "#fde68a")]
            )
            ProfileStatCard(
                icon: "flame.fill",
                iconColor: .orange,
                title: AL.s(.profileStreak),
                value: AL.f(.profileDaysFormat, vm.user?.streakDays ?? 0),
                bgColors: [Color(hex: "#fed7aa"), Color(hex: "#fdba74")]
            )
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AL.s(.profileStatistics))
                .font(.custom("Poppins-SemiBold", size: 17))
                .foregroundStyle(Color(hex: "#1a1a2e"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MiniStatCard(icon: "checkmark.circle.fill", label: AL.s(.profileCompleted),
                             value: "\(vm.stats.completedLevels)", color: .green)
                MiniStatCard(icon: "questionmark.circle.fill", label: AL.s(.profileQuizzes),
                             value: "\(vm.stats.totalAttempts)", color: .blue)
                MiniStatCard(icon: "target", label: AL.s(.profileAccuracy),
                             value: String(format: "%.0f%%", vm.stats.accuracy), color: Color(hex: "#E8409C"))
                MiniStatCard(icon: "star.fill", label: AL.s(.profileLevel),
                             value: "\(vm.userLevel)", color: Color(hex: "#FFAA44"))
            }
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

    // MARK: - Upgrade Pro
    private var upgradeButton: some View {
        Button {
            EventManager.shared.logPaywallEvent("upgrade_tapped_profile")
            showPaywall = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text(AL.s(.profileUpgradePro))
                    .font(.custom("Poppins-Bold", size: 15))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#FFAA44"), Color(hex: "#E8409C"), Color(hex: "#6B22E0")],
                    startPoint: .leading, endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: Color(hex: "#E8409C").opacity(0.4), radius: 12, y: 6)
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
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Subviews
// MARK: ═══════════════════════════════════════════════════════════

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
// MARK: - Lottie Test View (Geçici)
// MARK: ═══════════════════════════════════════════════════════════

struct LottieTestView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#f4f6f9").ignoresSafeArea()

            VStack(spacing: 24) {
                // Başlık
                Text("Lottie Önizleme")
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundStyle(Color(hex: "#1a1a2e"))

                // Animasyon
                LottieView(animation: .named("reeny_waving"))
                    .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 240, height: 240)

                Text("jelly")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(.secondary)

                Button {
                    dismiss()
                } label: {
                    Text("Kapat")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#8b5cf6"), in: Capsule())
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
