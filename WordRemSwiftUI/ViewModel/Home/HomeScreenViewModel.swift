//
//  HomeScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI

@MainActor
class HomeScreenViewModel: ObservableObject {
    
    @Published var cardNames: [String] = []
    @Published var cardIds: [String] = []
    @Published var selectedFlag:[String] = []
    @Published var isEditing: Bool = false
    @Published var cards: [Card] = []
    @Published var isLoading:Bool = false
    
    func fetchCardName() async {
        isLoading = true
        do {
            let fetchedCards = try await FirebaseService.shared.fetchCardName()
            DispatchQueue.main.async {
                self.cards = fetchedCards
                self.selectedFlag = fetchedCards.map { $0.selectedFlag?.rawValue ?? "" }
                self.cardNames = fetchedCards.map { $0.name ?? "" }
                self.cardIds = fetchedCards.map { $0.id ?? "" }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("Error fetching cards: \(error.localizedDescription)")
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
                try await FirebaseService.shared.deleteCardAndTransactions(withId: cardId)
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


