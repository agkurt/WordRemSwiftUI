
//  TabBarCustom.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//

import SwiftUI

struct TabBarCustom: View {
    @State var selectedTab = "house.circle"
    var body: some View {
        ZStack {
            LinearBackgroundView()
            if selectedTab == "house.circle" {
                HomeScreenView()
            } else if selectedTab == "plus.circle" {
                PlusView()
            } else if selectedTab == "person.crop.circle" {
                ProfileView()
            }
            
            VStack {
                Spacer()
                HStack(spacing:90) {
                    Image(systemName: "house.circle")
                        .foregroundColor(self.selectedTab == "house.circle" ? .blue : .gray)
                        .onTapGesture {
                            self.selectedTab = "house.circle"
                        }

                    Image(systemName: "plus.circle")
                        .foregroundColor(self.selectedTab == "plus.circle" ? .blue : .gray)
                        .onTapGesture {
                            self.selectedTab = "plus.circle"
                        }

                    Image(systemName: "person.crop.circle")
                        .foregroundColor(self.selectedTab == "person.crop.circle" ? .blue : .gray)
                        .onTapGesture {
                            self.selectedTab = "person.crop.circle"
                        }
                }
                .frame(maxWidth: .infinity,maxHeight:40)
                .font(.largeTitle)
                .padding()
                .background(Color(hex: "#c9bfb1"))
                .clipShape(.capsule(style: .circular))
            }
        }
    }
}

#Preview {
    TabBarCustom()
}

