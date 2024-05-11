//
//  CardRowView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 10.05.2024.
//

import SwiftUI

struct CardRowView: View {
    @Binding var isEditing: Bool
    let index: Int
    let viewModel: HomeScreenViewModel

    var body: some View {
        NavigationLink(destination: CardDetailView(cardId:viewModel.deckIds[index], cardName: viewModel.cardNames[index])) {
            CardView(isEditing: $isEditing,
                     title:viewModel.cardNames[index],
                     image: viewModel.selectedFlag[index],
                      onDelete: {
                if isEditing {
                    viewModel.deleteCard(at: index)
                }
            })
            .foregroundStyle(.white)
        }
    }
}


