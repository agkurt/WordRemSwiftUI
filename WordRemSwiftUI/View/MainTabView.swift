//
//  MainTabView.swift
//  WordRemSwiftUI
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case today
    case words
    case path
    case profile
    /// Sekme çubuğunda yok; Bugün ekranındaki kupa butonundan sheet olarak açılır
    case leaderboard

    static let barTabs: [AppTab] = [.today, .path, .words, .profile]

    var icon: String {
        switch self {
        case .today:       return "waveform"
        case .words:       return "text.book.closed"
        case .path:        return "square.grid.2x2"
        case .profile:     return "person"
        case .leaderboard: return "trophy"
        }
    }

    var label: String {
        switch self {
        case .today:       return AL.s(.tabTalk)
        case .words:       return AL.s(.tabWords)
        case .path:        return AL.s(.tabPractice)
        case .profile:     return AL.s(.tabProfile)
        case .leaderboard: return AL.s(.tabRank)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var tabBarModifier: TabBarModifier
    @EnvironmentObject var langManager: LanguageManager
    @StateObject private var homeVM = HomeScreenViewModel()
    @StateObject private var pathVM = PathMapViewModel()
    @State private var selectedTab: AppTab = DemoData.startTab ?? .today
    @State private var wordsSegment: WordsView.Segment = .learned
    @State private var showCreateDeck = false
    @State private var showLeaderboard = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch selectedTab {
            case .today, .leaderboard:
                TalkHomeView(onOpenLeaderboard: { showLeaderboard = true })
            case .words:
                WordsView(homeVM: homeVM, showCreateDeck: $showCreateDeck, segment: $wordsSegment)
            case .path:
                PathMapView(vm: pathVM)
            case .profile:
                NavigationStack { ProfileView() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .sheet(isPresented: $showCreateDeck) {
            PlusView(completion: {
                Task { await homeVM.fetchCardName() }
            })
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(selectedTab: Binding(
                get: { .leaderboard },
                set: { tab in
                    showLeaderboard = false
                    selectedTab = tab
                }
            ))
            .environmentObject(langManager)
        }
        // "Rem": alışkanlık saati, widget/bildirim cevaplarını oku, arka plana geçerken hatırlatmaları kur
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                SmartReminders.noteAppOpened()
                ReviewScheduler.shared.reload()
            case .background:
                Task { await SmartReminders.reschedule() }
            default:
                break
            }
        }
        // Bildirim/widget'tan gelince Konuş sekmesine geç (ders/tekrar orada açılır)
        .onReceive(AppRouter.shared.$route) { route in
            if route != nil { selectedTab = .today }
        }
    }

    private var showsAddButton: Bool { selectedTab == .words && wordsSegment == .decks }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            if showsAddButton {
                HStack {
                    Spacer()
                    Button {
                        if let action = tabBarModifier.customAddAction {
                            action()
                        } else {
                            showCreateDeck = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(DS.Colors.paperRaised)
                            .frame(width: 56, height: 56)
                            .background(DS.Colors.ink, in: Circle())
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 12)
                }
                .transition(.opacity)
            }

            VStack(spacing: 0) {
                Rectangle().fill(DS.Colors.line).frame(height: 1)
                HStack(spacing: 0) {
                    ForEach(AppTab.barTabs, id: \.rawValue) { tab in
                        TabBarItem(tab: tab, isSelected: selectedTab == tab) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(DS.Colors.paper.ignoresSafeArea(edges: .bottom))
        }
        .animation(.easeOut(duration: 0.2), value: showsAddButton)
    }
}

// MARK: - Tab Bar Item
private struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .frame(height: 24)
                Text(tab.label)
                    .font(DS.Font.ui(11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? DS.Colors.ink : DS.Colors.muted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    MainTabView()
        .environmentObject(TabBarModifier())
        .environmentObject(AuthManager())
        .environmentObject(LanguageManager.shared)
}
