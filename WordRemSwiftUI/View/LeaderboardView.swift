//
//  LeaderboardView.swift
//  WordRemSwiftUI
//
//  Sıralama bir defter sayfası: sıra numaraları kenar boşluğunda, isimden XP'ye noktalı çizgi,
//  ilk üçe madalya yerine küçük mürekkep mühürleri, kendi satırın yapışkan not renginde.
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
                    .modifier(BoardTextColumn())

                // Guest kullanıcıya login yönlendirme
                if !gameCenter.isAuthenticated {
                    guestPromptView
                        .modifier(BoardTextColumn())

                } else if vm.isLoading && vm.users.isEmpty {
                    ProgressView()
                        .tint(DS.Colors.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)

                } else if let err = vm.errorMessage {
                    errorView(err)
                        .modifier(BoardTextColumn())

                } else if vm.users.isEmpty {
                    emptyView
                        .modifier(BoardTextColumn())

                } else {
                    // ── Benim Sıram ───────────────────────────
                    if let rank = vm.currentUserRank(), let me = vm.currentUser {
                        BoardOwnRankCard(rank: rank, user: me)
                            .modifier(BoardTextColumn())
                            .padding(.vertical, 6)
                    }

                    // ── Sıralama (ilk 20): çizgili satırlar ───
                    LazyVStack(spacing: 0) {
                        let top = Array(vm.users.prefix(20).enumerated())
                        ForEach(top, id: \.element.id) { index, user in
                            BoardRankRow(
                                rank: index + 1,
                                user: user,
                                isCurrentUser: user.id == vm.currentUserId
                            )
                        }
                    }
                    .overlay(alignment: .top) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        // Kenar boşluğu çizgisi sayfa boyunca; içerikle aynı genişlikte ortalanır (iPad'de de hizalı)
        .overlay {
            MarginLine()
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
        }
        // Sheet içinde aşağı çekmek sayfayı kapatsın diye pull-to-refresh yok; kapatma butonu da var
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 44, height: 44)
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
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
                .font(.system(size: 16, design: .serif).italic())
                .foregroundStyle(DS.Colors.muted)
        }
        .padding(.trailing, 28)   // kapatma düğmesine yer
    }

    // MARK: - Guest Prompt
    private var guestPromptView: some View {
        StickyNote {
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

/// Metin sütunu: kenar boşluğu çizgisinin sağından başlar
private struct BoardTextColumn: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.leading, DS.Page.textX)
            .padding(.trailing, 24)
    }
}

/// İlk üç için küçük mürekkep mührü (madalya yerine)
private struct BoardRankStamp: View {
    let rank: Int
    var size: CGFloat = 36

    private var color: Color {
        switch rank {
        case 1:  return DS.Colors.accent
        case 2:  return DS.Colors.slate
        default: return DS.Colors.inkSoft
        }
    }

    var body: some View {
        ZStack {
            Circle().strokeBorder(color, lineWidth: 2)
            Circle().strokeBorder(color, lineWidth: 1).padding(size * 0.1)
            Text("\(rank)")
                .font(DS.Font.display(size * 0.42, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rank == 2 ? 8 : -12))
        .accessibilityLabel("\(rank)")
    }
}

/// Kendi sıran: sayfaya yapıştırılmış not
private struct BoardOwnRankCard: View {
    @EnvironmentObject var langManager: LanguageManager
    let rank: Int
    let user: SBUser

    var body: some View {
        StickyNote(angle: -1) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text("#\(rank)")
                    .font(DS.Font.display(34, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .monospacedDigit()
                Text(user.username)
                    .font(DS.Font.display(18, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(user.totalXp) XP")
                    .font(DS.Font.ui(14, weight: .semibold))
                    .foregroundStyle(DS.Colors.accentText)
                    .monospacedDigit()
            }
        }
    }
}

/// Defter satırı: kenar boşluğunda sıra (ilk üçte mühür), isim ........ XP
private struct BoardRankRow: View {
    @EnvironmentObject var langManager: LanguageManager
    let rank: Int
    let user: SBUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(user.username)
                .font(DS.Font.display(18, weight: isCurrentUser ? .bold : .regular))
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(1)
            DottedLeader().alignmentGuide(.lastTextBaseline) { d in d[.bottom] }
            Text("\(user.totalXp) XP")
                .font(DS.Font.ui(15, weight: isCurrentUser ? .bold : .semibold))
                .foregroundStyle(isCurrentUser ? DS.Colors.accentText : DS.Colors.inkSoft)
                .monospacedDigit()
        }
        .padding(.leading, DS.Page.textX)
        .padding(.trailing, 24)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .overlay(alignment: .leading) {
            // Sıra numarası kenar boşluğunda, çizgiye yaslı
            Group {
                if rank <= 3 {
                    BoardRankStamp(rank: rank)
                        .frame(width: DS.Page.marginX, alignment: .center)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 17, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .monospacedDigit()
                        .frame(width: DS.Page.marginX - 14, alignment: .trailing)
                }
            }
        }
        .background(isCurrentUser ? DS.Colors.note : .clear)
        .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LeaderboardView(selectedTab: .constant(.leaderboard))
}
