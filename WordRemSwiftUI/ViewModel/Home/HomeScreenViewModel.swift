//
//  HomeScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI

class HomeScreenViewModel: ObservableObject {
    
    @Published var cardNames: [String] = []
    @Published var cardIds: [String] = []
    @Published var isEditing:Bool = false
    
    func fetchCardName() async {
        let (fetchedCardNames, fetchedCardIds) = await FirebaseService.shared.fetchCardName()
        DispatchQueue.main.async {
            self.cardNames = fetchedCardNames
            self.cardIds = fetchedCardIds
        }
    }
    
    func deleteCard(at index: Int) {
        Task {
            do {
                try await FirebaseService.shared.deleteCards()
                DispatchQueue.main.async {
                    self.cardNames.remove(at: index)
                    self.cardIds.remove(at: index)
                }
            } catch {
                print("Error deleting cards: \(error.localizedDescription)")
            }
        }
    }
    
}




