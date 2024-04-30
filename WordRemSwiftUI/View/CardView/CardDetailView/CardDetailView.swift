//
//  CardDetailView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardDetailView: View {
    
    @StateObject var viewModel = CardDetailViewModel()
    var cardName: String
    var cardId: String
    @State private var showSheet = false
    @State private var flipped = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                ScrollView {
                    VStack {
                        ForEach(viewModel.wordNames.indices, id: \.self) { index in
                            CardDetailDesignView(wordName: viewModel.wordNames[index],wordMean: viewModel.wordMeans[index],wordDescription: viewModel.wordDescriptions[index])
                        }
                    }
                }
            }
            .navigationTitle("WORDS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showSheet) {
                CardPlusView(completion: {
                    Task {
                        try await viewModel.fetchCardInfo(cardId:cardId)
                    }
                }, cardId: cardId)
            }
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.fetchCardInfo(cardId: cardId)
                }catch {
                    print(error)
                    print(error.localizedDescription)
                }
            }
        }
    }
}
