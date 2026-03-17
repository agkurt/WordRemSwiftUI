//
//  MainTabView.swift
//  WordRemSwiftUI
//
//  Custom bottom navigation bar — replaces the ArcMenuButton FAB.
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case home
    case translate
    case news
    case sentences
    case profile

    var icon: String {
        switch self {
        case .home:       return "rectangle.stack.fill"
        case .translate:  return "translate"
        case .news:       return "newspaper.fill"
        case .sentences:  return "text.word.spacing"
        case .profile:    return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:       return "Decks"
        case .translate:  return "Translate"
        case .news:       return "News"
        case .sentences:  return "Sentences"
        case .profile:    return "Profile"
        }
    }
}

struct MainTabView: View {
    @StateObject private var homeVM = HomeScreenViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var showCreateDeck = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: Page Content
            Group {
                switch selectedTab {
                case .home:
                    HomeScreenView(viewModel: homeVM, showCreateDeck: $showCreateDeck)
                case .translate:
                    NavigationStack { TranslationView() }
                case .news:
                    NavigationStack { NewsView() }
                case .sentences:
                    NavigationStack { SentenceScreenView() }
                case .profile:
                    NavigationStack { ProfileView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: Tab Bar
            CustomTabBar(selected: $selectedTab, onAddTap: { showCreateDeck = true })
        }
        .ignoresSafeArea(edges: .bottom)
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

    var body: some View {
        HStack(spacing: 0) {
            // Left tabs: Home, Translate
            ForEach([AppTab.home, AppTab.translate], id: \.self) { tab in
                TabBarItem(tab: tab, isSelected: selected == tab) {
                    withAnimation(.spring(response: 0.35)) { selected = tab }
                }
            }

            // Center "+" button
            AddButton(action: onAddTap)
                .padding(.horizontal, 8)

            // Right tabs: News, Sentences, Profile
            ForEach([AppTab.news, AppTab.sentences, AppTab.profile], id: \.self) { tab in
                TabBarItem(tab: tab, isSelected: selected == tab) {
                    withAnimation(.spring(response: 0.35)) { selected = tab }
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                // Frosted glass card
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(hex: "#141c26").opacity(0.97))
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 24, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
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
                    .foregroundStyle(isSelected ? Color(hex: "#f97316") : Color.white.opacity(0.38))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)

                Text(tab.label)
                    .font(.custom("Poppins-Regular", size: 9))
                    .foregroundStyle(isSelected ? Color(hex: "#f97316") : Color.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
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
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#f97316"), Color(hex: "#c2400c")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: Color(hex: "#f97316").opacity(0.55), radius: 16, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .offset(y: -16) // Pop up above tab bar
    }
}
