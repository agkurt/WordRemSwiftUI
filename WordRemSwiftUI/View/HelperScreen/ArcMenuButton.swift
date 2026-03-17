//
//  ArcMenuButton.swift
//  WordRemSwiftUI
//

import SwiftUI

struct ArcMenuButton: View {
    @State var isExpanded = false
    let buttons: [String]

    private let menuItems: [(icon: String, label: String)] = [
        ("text.word.spacing", "Sentences"),
        ("newspaper.fill",    "News"),
        ("translate",         "Translate"),
        ("person.fill",       "Profile"),
    ]

    var body: some View {
        ZStack {
            // Tap background to close
            if isExpanded {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4)) { isExpanded = false }
                    }
                    .transition(.opacity)
                    .allowsHitTesting(true)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        // Sub-buttons (arc)
                        ForEach(menuItems.indices, id: \.self) { index in
                            if index < buttons.count {
                                NavigationLink(destination: destinationView(forIndex: index)) {
                                    VStack(spacing: 5) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: "#f97316"), Color(hex: "#ea580c")],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 48, height: 48)
                                                .shadow(color: Color(hex: "#f97316").opacity(0.45), radius: 10, y: 4)
                                            Image(systemName: menuItems[index].icon)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundStyle(.white)
                                        }
                                        Text(menuItems[index].label)
                                            .font(.custom("Poppins-Regular", size: 9))
                                            .foregroundStyle(.white.opacity(0.85))
                                            .shadow(radius: 3)
                                    }
                                }
                                .offset(
                                    x: isExpanded ? CGFloat(cos((Double(index) * 55 + 115) * .pi / 180) * 90) : 0,
                                    y: isExpanded ? CGFloat(sin((Double(index) * 55 + 115) * .pi / 180) * 90) : 0
                                )
                                .scaleEffect(isExpanded ? 1.0 : 0.2)
                                .opacity(isExpanded ? 1.0 : 0)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.62)
                                    .delay(Double(index) * 0.05),
                                    value: isExpanded
                                )
                            }
                        }

                        // Main FAB
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#f97316"), Color(hex: "#c2400c")],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color(hex: "#f97316").opacity(0.55), radius: 16, y: 6)

                                Image(systemName: isExpanded ? "xmark" : "square.grid.2x2.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                    .animation(.spring(response: 0.4), value: isExpanded)
                            }
                        }
                    }
                    .padding(.trailing, 22)
                    .padding(.bottom, 30)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    func destinationView(forIndex index: Int) -> some View {
        switch buttons[index] {
        case "text.word.spacing":  return AnyView(SentenceScreenView())
        case "newspaper":          return AnyView(NewsView())
//        case "translate":          return AnyView(TranslationView())
        case "person.crop.circle": return AnyView(ProfileView())
        default:                   return AnyView(EmptyView())
        }
    }
}
