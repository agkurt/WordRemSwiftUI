//
//  CardFlipView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 7.05.2024.
//

import SwiftUI

struct CardFlipView: View {
    
    @ObservedObject var viewModel: CardDetailViewModel
    @ObservedObject var notificationManager = NotificationManager()
    @Binding var isEditing: Bool
    @State var isFlipped: Bool
    @State var cardId: String
    @State var index: Int
    @State private var showEditSheet = false
    
    var body: some View {
        ZStack {
            // Front card view (Word + Description)
            CardDetailDesignView(
                wordName: $viewModel.wordNames.indices.contains(index) ? $viewModel.wordNames[index] : .constant(nil),
                wordMean: .constant(nil),
                wordDescription: viewModel.wordDescriptions.indices.contains(index) ? $viewModel.wordDescriptions[index] : .constant(nil),
                isEditing: $isEditing,
                targetLanguageCode: viewModel.targetLang,
                nativeLanguageCode: viewModel.sourceLang,
                onDelete: {
                    if isEditing {
                        viewModel.deleteCard(at: index, deckId: cardId)
                    }
                },
                onEdit: {
                    showEditSheet = true
                }
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0.0, y: 1.0, z: 0.0),
                perspective: 0.5
            )
            .scaleEffect(isFlipped ? 1.0 : 0.95)
            
            // Back card view (Meaning only)
            CardDetailDesignView(
                wordName: .constant(nil),
                wordMean: viewModel.wordMeans.indices.contains(index) ? $viewModel.wordMeans[index] : .constant(nil),
                wordDescription: .constant(nil),
                isEditing: $isEditing,
                targetLanguageCode: viewModel.targetLang,
                nativeLanguageCode: viewModel.sourceLang,
                onDelete: {
                    if isEditing {
                        viewModel.deleteCard(at: index, deckId: cardId)
                    }
                },
                onEdit: {
                    showEditSheet = true
                }
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? -180 : 0),
                axis: (x: 0.0, y: 1.0, z: 0.0),
                perspective: 0.5
            )
            .scaleEffect(isFlipped ? 0.95 : 1.0)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
                isFlipped.toggle()
            }
        }
        .sheet(isPresented: $showEditSheet) {
            // Reload data after edit dismiss
            Task {
                await viewModel.fetchCardInfo(cardId: cardId)
            }
        } content: {
            CardPlusView(
                cardId: cardId,
                editMode: true,
                editWordId: viewModel.cardIds.indices.contains(index) ? viewModel.cardIds[index] : "",
                // SWAP: wordName ve wordMean ters çünkü database'de swap edilmiş
                editWordName: viewModel.wordMeans.indices.contains(index) ? viewModel.wordMeans[index] ?? "" : "",  // ARKA YÜZ → Native
                editWordMean: viewModel.wordNames.indices.contains(index) ? viewModel.wordNames[index] ?? "" : "",   // ÖN YÜZ → Learning
                editWordDescription: viewModel.wordDescriptions.indices.contains(index) ? viewModel.wordDescriptions[index] ?? "" : ""
            )
        }
    }
}
