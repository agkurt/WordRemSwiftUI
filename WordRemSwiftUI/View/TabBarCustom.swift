
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
            VStack {
                Spacer()
                HStack(spacing:90) {
                    Button(action: {
                        self.selectedTab = "house.circle"
                    }, label: {
                        Image(systemName: "house.circle")
                            .foregroundColor(self.selectedTab == "house.circle" ? .blue : .gray)
                    })
                   
                    Button(action: {
                        self.selectedTab = "plus.circle"
                    }, label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(self.selectedTab == "plus.circle" ? .blue : .gray)
                    })
                    
                    Button(action: {
                        self.selectedTab = "person.crop.circle"
                    }, label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(self.selectedTab == "person.crop.circle" ? .blue : .gray)
                    })
                    
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
