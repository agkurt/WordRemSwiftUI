//
//  ProfileView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 20.02.2024.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @ObservedObject var viewModel =  ProfileViewModel()
    
    @State private var isSignOut = false
    
    var body: some View {
        ZStack {
            LinearBackgroundView()
            VStack(spacing:0) {
                IconImageView()
                    .padding(.top,20)
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
                            .foregroundStyle(Color(hex:"#c7c9b1"))
                        
                    }
                    
                    Text("Logout")
                        .font(.callout)
                        .foregroundStyle(Color(hex: "#8b8e62"))
                        .onTapGesture {
                            viewModel.signOut()
                        }
                    
                    
                }
                .frame(maxHeight: 200)
                .padding()
                .padding(.bottom,20)
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .padding()
        }
        .ignoresSafeArea(.container)
    }
}

#Preview {
    ProfileView()
}
