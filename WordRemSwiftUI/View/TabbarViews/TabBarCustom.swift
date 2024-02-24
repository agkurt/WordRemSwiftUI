
//  TabBarCustom.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//

import SwiftUI

struct TabBarCustom: View {
    @State var selectedTab = "house.circle"
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                if selectedTab == "house.circle" {
                    HomeScreenView()
                } else if selectedTab == "person.crop.circle" {
                    ProfileView()
                }
                
                VStack {
                    Spacer()
                    ZStack(alignment: .bottom) {
                        VStack {
                            HStack(spacing:200) {
                                VStack {
                                    Image(systemName: "house.circle")
                                        .foregroundColor(self.selectedTab == "house.circle" ? Color(hex: "#8b6072") : .gray)

                                        .onTapGesture {
                                            self.selectedTab = "house.circle"
                                    }
                                }
                                
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(self.selectedTab == "person.crop.circle" ? Color(hex: "#8b6072") : .gray)
                                    .onTapGesture {
                                        self.selectedTab = "person.crop.circle"
                                    }
                            }
                            .frame(maxWidth: .infinity,maxHeight:40)
                            .font(.largeTitle)
                            .padding(.top,10)
                            .clipShape(.capsule(style: .circular))
                            .background(Color(hex: "#37414f"))
                        }
                        
                        NavigationLink(destination: PlusView()) {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .frame(width: 75, height: 75)
                                .foregroundStyle(Color(hex: "#8b6072"))
                                .background(Color(hex: "#37414f"))
                                .shadow(radius: 10)
                                .clipShape(.capsule(style: .circular))
                                
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }
}

#Preview {
    TabBarCustom()
}

