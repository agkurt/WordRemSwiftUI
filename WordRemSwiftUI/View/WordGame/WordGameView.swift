//
//  WordGameView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 5.05.2024.
//

import SwiftUI

struct WordGameView: View {
    @StateObject private var viewModel = WordGameViewModel()
    @State var ifTouchToLearn = false
    @State var currentCardIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    Text("Choose 4 words to learn")
                    if currentCardIndex < viewModel.cardModels.count {
                        WordCardView(
                            word: $viewModel.cardModels[currentCardIndex].word,
                            mean: $viewModel.cardModels[currentCardIndex].mean,
                            ifTouchToLearn: $ifTouchToLearn, 
                            imageData: $viewModel.cardModels[currentCardIndex].imageData
                        )
                        .padding(.bottom, 20)
                    }
                    
                    HStack(spacing: 100) {
                        VStack {
                            Image(systemName: "hand.point.left")
                            Text("Know it")
                        }
                        .onTapGesture {
                            ifTouchToLearn = false
                            if currentCardIndex < viewModel.cardModels.count - 1 {
                                currentCardIndex += 1
                            }
                        }
                        VStack {
                            Image(systemName: "hand.point.right")
                            Text("Learn")
                        }
                        .onTapGesture {
                            ifTouchToLearn = true
                            if currentCardIndex < viewModel.cardModels.count - 1 {
                                currentCardIndex += 1
                            }
                        }
                    }
                    .font(.title)
                    .padding()
                }
            }
            .onAppear {
                viewModel.sqlLite()
            }
        }
    }
}

