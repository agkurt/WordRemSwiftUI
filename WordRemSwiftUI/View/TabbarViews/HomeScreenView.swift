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
                                .onTapGesture {
                                    // Shift all cards down with animation
                                    withAnimation(.spring()) {
                                        // Adjust animation logic as needed
                                        // For example, use `offset` to move each card
                                    }
                                }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Cards")
        }
    }
}



#Preview {
    HomeScreenView()
}
