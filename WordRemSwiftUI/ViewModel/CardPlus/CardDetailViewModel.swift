//
//  CardDetailViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import SwiftUI

@MainActor
final class CardDetailViewModel: ObservableObject {
    
    @Published var wordNames: [String?] = []
    @Published var wordMeans: [String?] = []
    @Published var wordDescriptions: [String?] = []
    @Published var wordInfo: [WordInfo] = []
    @Published var cardIds: [String] = []
    
    func fetchCardInfo(cardId:String) async {
        do {
            let fetchedWordInfo = try await FirebaseService.shared.fetchTheCardNameInfo(cardId: cardId)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.wordInfo = fetchedWordInfo
                self.cardIds = fetchedWordInfo.map {$0.id}
                self.wordNames = fetchedWordInfo.map {$0.names}
                self.wordMeans = fetchedWordInfo.map {$0.means}
                self.wordDescriptions = fetchedWordInfo.map { $0.descriptions}
        }
        }catch {
            print(error)
        }
    }
    
    func deleteCard(at index: Int,deckId:String) {
        Task {
            guard index >= 0 && index < self.wordNames.count else {
                print("Index out of range")
                return
            }
            do {
                let cardId = self.cardIds[index]
                try await FirebaseService.shared.deleteCardInfoAndTransactions(deckId: deckId, cardId: cardId)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.wordInfo.remove(at: index)
                    self.wordNames.remove(at: index)
                    self.wordMeans.remove(at: index)
                    self.cardIds.remove(at: index)
                    self.wordDescriptions.remove(at: index)
                }
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
            }
        }
    }

}
