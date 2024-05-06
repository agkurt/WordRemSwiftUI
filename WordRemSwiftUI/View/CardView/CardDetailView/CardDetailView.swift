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
    @State var isEditing: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                ScrollView {
                    VStack {
                        ForEach(viewModel.wordInfo.indices, id: \.self) { index in
                            CardDetailDesignView(wordName: $viewModel.wordNames[index],wordMean: $viewModel.wordMeans[index],wordDescription: $viewModel.wordDescriptions[index],isEditing: $isEditing,onDelete: {
                                if isEditing {
                                    viewModel.deleteCard(at: index, deckId: cardId)
                                }
                            })
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchCardInfo(cardId: cardId)
                }
            }
            
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Image(systemName: isEditing ? "checkmark":"trash")
                    }
                }
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
