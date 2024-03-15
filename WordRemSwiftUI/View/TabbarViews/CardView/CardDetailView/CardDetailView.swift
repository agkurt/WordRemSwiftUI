//
//  CardDetailView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardDetailView: View {
    @ObservedObject var viewModel = CardDetailViewModel()
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
                        .onTapGesture {
                            withAnimation {
                                flipped.toggle()
                            }
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
                CardPlusView(cardId: cardId)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchCardInfo(cardId: cardId)
            }
        }
    }
}

#Preview {
    CardDetailView(cardName: "agk", cardId: "agk")
}

