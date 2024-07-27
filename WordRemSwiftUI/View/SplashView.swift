//
//  SplashView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.07.2024.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var homeScreenViewModel = HomeScreenViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.allports], startPoint: .top, endPoint: .bottom)
            VStack {
                Image("appLogo")
                    .resizable()
                    .ignoresSafeArea()
                    .frame(width: .infinity, height: .infinity, alignment: .center)
            }
        }
    }

    func startRoute() {
        if authManager.userIsLoggedIn {
            HomeScreenView(viewModel: homeScreenViewModel)
        } else {
            LoginScreenView()
        }
    }
}
