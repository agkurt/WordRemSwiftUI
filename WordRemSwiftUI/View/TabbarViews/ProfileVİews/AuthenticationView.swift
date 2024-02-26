//
//  AuthenticationView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//
import SwiftUI

struct AuthenticationView: View {
    @StateObject var viewModel = ProfileViewModel()

    var body: some View {
        Group {
            if viewModel.isSignedIn {
                ProfileView(viewModel: viewModel)
            } else {
                LoginScreenView()
            }
        }
        .environmentObject(viewModel)
    }
}
