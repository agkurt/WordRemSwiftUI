//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//

import SwiftUI

struct HomeScreenView: View {

    @ObservedObject var viewModel = HomeScreenViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.cardNames.indices, id: \.self) { index in
                            CardView(title: viewModel.cardNames[index],
                                     image: Image(systemName: "pencil"))
                            
                        }
                    }
                    .onAppear {
                        Task {
                            await viewModel.fetchCardName()
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Cards")
            .tint(.purple)
        }
    }
}

#Preview {
    HomeScreenView()
}
