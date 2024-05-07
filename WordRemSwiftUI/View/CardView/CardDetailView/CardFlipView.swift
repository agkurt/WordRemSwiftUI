//
//  CardFlipView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 7.05.2024.
//

import SwiftUI

struct CardFlipView: View {
    
    @ObservedObject var viewModel: CardDetailViewModel
    @Binding var isEditing: Bool
    @Binding var isFlipped: Bool
    var cardId: String
    var index: Int
    
    var body: some View {
        ZStack {
            
            CardDetailDesignView(wordName: $viewModel.wordNames[index], wordMean: .constant(nil), wordDescription: $viewModel.wordDescriptions[index], isEditing: $isEditing, onDelete: {
                if isEditing {
                    viewModel.deleteCard(at: index, deckId: cardId)
                }
            })
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : -90),
                axis: (x:0.0,y:1.0,z:0.0)
            )
            
            .animation(isFlipped ? .linear.delay(0.35): .linear,value: isFlipped )
            
            // Back card view
            CardDetailDesignView(wordName:.constant(nil) ,wordMean: $viewModel.wordMeans[index],wordDescription:.constant(nil) ,isEditing: $isEditing,onDelete: {
                if isEditing {
                    viewModel.deleteCard(at: index, deckId: cardId)
                }
            })
            .rotation3DEffect(
                .degrees(isFlipped ? 90:0),
                axis: (x:0.0,y:1.0,z:0.0)
            )
            .animation(isFlipped ? .linear: .linear.delay(0.35),value: isFlipped)
        }
        
    }
}
