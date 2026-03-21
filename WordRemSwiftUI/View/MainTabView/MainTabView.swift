//
//  MainTabView.swift
//  WordRemSwiftUI
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case path
    case home
    case leaderboard
    case profile

    var icon: String {
        switch self {
        case .home:        return "books.vertical.fill"
        case .path:        return "map.fill"
        case .leaderboard: return "trophy.fill"
        case .profile:     return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:        return "Decks"
        case .path:        return "Path"
        case .leaderboard: return "Rank"
        case .profile:     return "Profile"
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
        Group {
            switch selectedTab {
            case .home:
                HomeScreenView(viewModel: homeVM, showCreateDeck: $showCreateDeck)
            case .path:
                PathMapView(vm: pathVM)
            case .leaderboard:
                LeaderboardView()
            case .profile:
                NavigationStack { ProfileView() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            floatingBottomBar
                .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showCreateDeck) {
            PlusView(completion: {
                Task { await homeVM.fetchCardName() }
            })
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
    }

    // MARK: - Floating Bottom Bar
    private var floatingBottomBar: some View {
        VStack(spacing: 0) {
            // + butonu sadece Decks tabında görünür
            if selectedTab == .home {
                Button {
                    if let action = tabBarModifier.customAddAction {
                        action()
                    } else {
                        showCreateDeck = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#f97316"), Color(hex: "#E8409C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                            .shadow(color: Color(hex: "#f97316").opacity(0.45), radius: 12, y: 4)
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 10)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            // Tab Bar
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.rawValue) { tab in
                    TabBarItem(tab: tab, isSelected: selectedTab == tab) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: -4)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedTab)
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
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isSelected
                        ? Color(hex: "#f97316")
                        : Color(hex: "#94a3b8")
                    )
                    .frame(height: 24)
                    .scaleEffect(isSelected ? 1.12 : 1.0)

                Text(tab.label)
                    .font(.custom("Poppins-Medium", size: 10))
                    .foregroundStyle(
                        isSelected
                        ? Color(hex: "#f97316")
                        : Color(hex: "#94a3b8")
                    )
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scale Button Style
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

#Preview {
    MainTabView()
        .environmentObject(TabBarModifier())
        .environmentObject(AuthManager())
}
