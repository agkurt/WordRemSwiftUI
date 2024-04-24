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
    @Published var selectedFlag:[String] = []
    @Published var isEditing: Bool = false
    @Published var cards: [Card] = []
    @Published var isLoading:Bool = false
    
    func fetchCardName() async {
        do {
            let fetchedCards = try await FirebaseService.shared.fetchCardName()
            OperationQueue.main.addOperation {
                self.cards = fetchedCards
                self.selectedFlag = fetchedCards.map { $0.selectedFlag.rawValue }
                self.cardNames = fetchedCards.map { $0.name }
                self.cardIds = fetchedCards.map { $0.id }
            }
        } catch {
            print("Error fetching cards: \(error.localizedDescription)")
            DispatchQueue.main.async {
            }
        }
    }
    
    func deleteCard(at index: Int) {
        Task {
            guard index >= 0 && index < self.cards.count else {
                print("Index out of range")
                return
            }
            do {
                let cardId = self.cardIds[index]
                try await FirebaseService.shared.deleteCard(withId: cardId)
                DispatchQueue.main.async {
                    self.cards.remove(at: index)
                    self.cardNames.remove(at: index)
                    self.cardIds.remove(at: index)
                    self.selectedFlag.remove(at: index)
                }
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
            }
        }
    }
}


