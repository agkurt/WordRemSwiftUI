//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//

import SwiftUI

struct HomeScreenView: View {

    @ObservedObject var viewModel = HomeScreenViewModel()
    @State private var currentPage: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    TabView(selection: $currentPage) {
                        ForEach(viewModel.cardNames.indices, id: \.self) { index in
                            CardView(title: viewModel.cardNames[index],
                                     image: Image(systemName: "pencil"))
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Cards")
            .tint(.purple)
        }
        .onAppear {
            Task {
                await viewModel.fetchCardName()
            }
        }
    }
}

#Preview {
    HomeScreenView()
}


