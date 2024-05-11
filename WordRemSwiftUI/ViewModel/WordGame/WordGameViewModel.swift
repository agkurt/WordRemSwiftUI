//
//  WordGameViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 5.05.2024.
//

import Foundation
import SwiftUI

class WordGameViewModel: ObservableObject {
    
    @Published var words: [String] = []
    @Published var means: [String] = []
    @Published var sentences: [String] = []
    @Published var cardModels: [WordGameCardModel] = []
    
    func fetchCardInfo(deckId:String) async {
        do {
            let fetch = try await FirebaseService.shared.fetchAllCardInfoForGame(deckId: deckId)
            DispatchQueue.main.async {
                self.words = fetch.map {$0.words}
                self.means = fetch.map {$0.means}
                self.sentences = fetch.map {$0.sentences}
            }
        }catch {
            print(error)
        }
    }
}





