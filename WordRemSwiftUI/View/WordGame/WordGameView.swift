//
//  WordGameView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 5.05.2024.
//

import SwiftUI

struct WordGameView: View {
    
    @ObservedObject private var viewModel = WordGameViewModel()
    @State var ifTouchToLearn = false
    @State var currentCardIndex = 0
    var deckId:String
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    ForEach(viewModel.words,id:\.self) { word in
                            Text("\(word)")
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchCardInfo(deckId:deckId)
                    print("\(viewModel.words)")
                }
            }
        }
    }
}

#Preview {
    WordGameView(deckId: "")
}

