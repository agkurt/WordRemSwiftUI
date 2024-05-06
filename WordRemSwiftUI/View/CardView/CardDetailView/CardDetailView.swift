//
//  CardDetailView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardDetailView: View {
    
    @ObservedObject var viewModel: CardDetailViewModel
    var cardName: String
    @State var cardId: String
    @State private var showSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                ScrollView {
                    VStack {
                        ForEach(viewModel.wordInfo.indices, id: \.self) { index in
                            CardDetailDesignView(wordName: $viewModel.wordNames[index],wordMean: $viewModel.wordMeans[index],wordDescription: $viewModel.wordDescriptions[index])
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchCardInfo(cardId: cardId)
                }
            }
            .navigationTitle("WORDS")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSheet.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showSheet) {
                        CardPlusView(cardId: cardId, completion: {
                            Task {
                                await viewModel.fetchCardInfo(cardId:cardId)
                            }
                        })
                    }
                }
            }
           
        }
    }
}
