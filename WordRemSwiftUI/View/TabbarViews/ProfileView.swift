//
//  ProfileView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 20.02.2024.
//

import SwiftUI

struct ProfileView: View {
    @State private var isPremium = false
    var body: some View {
        ZStack {
            LinearBackgroundView()
            VStack(spacing:0) {
               IconImageView()
                GeometryReader { geometry in
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex:"#c7c9b1"))
                            .frame(width: geometry.size.width * 0.2,height: geometry.size.height * 0.30)
                    }
                }
                Spacer()
                
                VStack {
                    NavigationLink(destination: PremiumView()) {
                        Text("Get Premium")
                            .font(.largeTitle)
                            .padding()
                            .foregroundStyle(Color(hex:"#c7c9b1"))
                    }
                    
                    Text("Logout")
                        .font(.callout)
                        .foregroundStyle(Color(hex: "#8b8e62"))
                    
                }
               
               

            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .padding()
           
        }
    }
}

#Preview {
    ProfileView()
}
