//
//  HomeScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI

@MainActor
final class HomeScreenViewModel: ObservableObject {
    
    @Published var cardNames: [String] = []
    @Published var cardIds: [String] = []
    @Published var selectedFlag:[String] = []
    @Published var cardWordCounts: [Int] = []
    @Published var isEditing: Bool = false
    @Published var cards: [Card] = []
    @Published var isLoading:Bool = false
    
    func fetchCardName() async {
        isLoading = true
        do {
            let fetchedCards = try await FirebaseService.shared.fetchCardName()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.cards = fetchedCards
                self.selectedFlag = fetchedCards.map { $0.selectedFlag?.rawValue ?? "" }
                self.cardNames = fetchedCards.map { $0.name ?? "" }
                self.cardIds = fetchedCards.map { $0.id ?? "" }
                self.cardWordCounts = fetchedCards.map { $0.wordCount }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
            }
            print("Error fetching cards: \(error.localizedDescription)")
        }
    }
    
    func deleteCard(at index: Int) {
        guard index >= 0 && index < self.cardIds.count else {
            print("Index out of range")
            return
        }
        // id'yi await'ten önce yakala; silme sonrası index kaymış olabilir
        let cardId = self.cardIds[index]
        Task {
            do {
                try await FirebaseService.shared.deleteCardAndTransactions(withId: cardId)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self,
                          let i = self.cardIds.firstIndex(of: cardId) else { return }
                    if i < self.cards.count { self.cards.remove(at: i) }
                    if i < self.cardNames.count { self.cardNames.remove(at: i) }
                    self.cardIds.remove(at: i)
                    if i < self.selectedFlag.count { self.selectedFlag.remove(at: i) }
                    if i < self.cardWordCounts.count { self.cardWordCounts.remove(at: i) }
                }
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
            }
        }
    }
}


