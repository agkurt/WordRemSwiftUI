//
//  MainTabView.swift
//  WordRemSwiftUI
//
//  Custom bottom navigation bar.
//  Faz 6: Added ".path" (Path/Gamification) tab between home and translate.
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case home
    case path        // 🆕 Gamified Path
    case translate
    case leaderboard // 🏆 Leaderboard
    case profile

    var icon: String {
        switch self {
        case .home:         return "rectangle.stack.fill"
        case .path:         return "map.fill"
        case .translate:    return "translate"
        case .leaderboard:  return "trophy.fill"
        case .profile:      return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:         return "Decks"
        case .path:         return "Path"
        case .translate:    return "Translate"
        case .leaderboard:  return "Rank"
        case .profile:      return "Profile"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var tabBarModifier: TabBarModifier
    @StateObject private var homeVM = HomeScreenViewModel()
    @StateObject private var pathVM = PathMapViewModel()
    @State private var selectedTab: AppTab = .path
    @State private var showCreateDeck = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Page Content
            Group {
                switch selectedTab {
                case .home:
                    HomeScreenView(viewModel: homeVM, showCreateDeck: $showCreateDeck)
                case .path:
                    PathMapView(vm: pathVM)
                case .translate:
                    NavigationStack { LeaderboardView() }
                case .leaderboard:
                    LeaderboardView()
                case .profile:
                    NavigationStack { ProfileView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: Tab Bar
            CustomTabBar(selected: $selectedTab, onAddTap: {
                if let action = tabBarModifier.customAddAction {
                    action()
                } else {
                    showCreateDeck = true
                }
            })
        }
        .sheet(isPresented: $showCreateDeck) {
            PlusView(completion: {
                Task { await homeVM.fetchCardName() }
            })
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
    }
}

// MARK: - Custom Tab Bar

private struct CustomTabBar: View {
    @Binding var selected: AppTab
    let onAddTap: () -> Void

    /// All tabs except home and profile which anchor the sides;
    /// home = leftmost, profile = rightmost, path/translate/news fill middle.
    private var leftTabs:  [AppTab] { [.path, .home] }
    private var rightTabs: [AppTab] { [.leaderboard, .profile] }

    var body: some View {
        VStack(spacing: 0) {
            // Elegant top separator
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, AppTheme.Colors.inputBorder, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)

            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    // Left group
                    HStack(spacing: 0) {
                        ForEach(leftTabs, id: \.rawValue) { tab in
                            TabBarItem(tab: tab, isSelected: selected == tab) {
                                withAnimation(.spring(response: 0.35)) { selected = tab }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Space for AddButton
                    Spacer().frame(width: 50)

                    // Right group
                    HStack(spacing: 0) {
                        ForEach(rightTabs, id: \.rawValue) { tab in
                            TabBarItem(tab: tab, isSelected: selected == tab) {
                                withAnimation(.spring(response: 0.35)) { selected = tab }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 10)
                .padding(.bottom, 6)

                // Center "+" button
                AddButton(action: onAddTap)
            }
        }
        .background(
            AppTheme.Colors.navBarBackground
                .background(Material.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: AppTheme.Shadows.softColor, radius: AppTheme.Shadows.softRadius, y: -2)
    }
}

private struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.Colors.primaryOrange : AppTheme.Colors.textSecondary)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .frame(height: 24)
                    .animation(.spring(response: 0.3), value: isSelected)

                Text(tab.label)
                    .font(.custom(isSelected ? "Poppins-SemiBold" : "Poppins-Regular", size: 10))
                    .foregroundStyle(isSelected ? AppTheme.Colors.primaryOrange : AppTheme.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.Colors.primaryOrange, AppTheme.Colors.darkOrange],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: AppTheme.Shadows.vibrantColor,
                            radius: AppTheme.Shadows.vibrantRadius,
                            y: AppTheme.Shadows.vibrantY)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25), value: isPressed)
            .offset(y: -20)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}
