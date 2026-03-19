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
        case .home:         return "folder"
        case .path:         return "path"
        case .translate:    return "translate"
        case .leaderboard:  return "leaderboards"
        case .profile:      return "setting"
      
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

    // Gradient renkler (görüntüdeki palette: turuncu → pembe → mor)
    private let gradientColors: [Color] = [
        Color(hex: "#f97316"),
        Color(hex: "#ec4899"),
        Color(hex: "#8b5cf6")
    ]

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Seçili arka plan (gradient glow)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.15) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 44)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Image(tab.icon)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .scaleEffect(isSelected ? 1.12 : 1.0)
                }
                .frame(width: 52, height: 44)

                // Seçim göstergesi — küçük gradient kapsül
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: isSelected ? 20 : 0, height: 3)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image("plusicon")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#f97316"), Color(hex: "#ec4899"), Color(hex: "#8b5cf6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: Color(hex: "#ec4899").opacity(0.45),
                    radius: 10, y: 4
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.25), value: isPressed)
                .offset(y: -18)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

#Preview {
    MainTabView()
}

