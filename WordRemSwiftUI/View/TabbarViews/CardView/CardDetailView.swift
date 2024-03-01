//
//  CardDetailView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardDetailView: View {
    
    var cardName: String
    var cardId:String
    
    @State private var showSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    
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
        }
    }
}

#Preview {
    CardDetailView(cardName: "agk", cardId: "agk")
}

