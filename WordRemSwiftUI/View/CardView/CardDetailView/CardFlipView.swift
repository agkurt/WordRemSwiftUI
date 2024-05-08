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
    @State var isFlipped: Bool
    @State var cardId: String
    @State var index: Int
    
    var body: some View {
        ZStack {
            // front card view
            CardDetailDesignView(wordName: $viewModel.wordNames.indices.contains(index) ? $viewModel.wordNames[index] : .constant(nil), wordMean: .constant(nil), wordDescription: .constant(nil), isEditing: $isEditing, onDelete: {
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
            CardDetailDesignView(wordName:.constant(nil) ,wordMean: viewModel.wordMeans.indices.contains(index) ? $viewModel.wordMeans[index] : .constant(nil),wordDescription:viewModel.wordDescriptions.indices.contains(index) ? $viewModel.wordDescriptions[index] : .constant(nil) ,isEditing: $isEditing,onDelete: {
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
        .onTapGesture {
            withAnimation(.easeIn) {
                isFlipped.toggle()
            }
        }
        
    }
}
