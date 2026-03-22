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
    @Published var sourceLang: String = "TR" // Native language
    @Published var targetLang: String = "EN" // Learning language

    func fetchCardInfo(cardId: String) async {
        do {
            let fetchedWordInfo = try await FirebaseService.shared.fetchTheCardNameInfo(cardId: cardId)
            // Already on MainActor — no need for DispatchQueue.main.async
            self.wordInfo = fetchedWordInfo
            self.cardIds = fetchedWordInfo.map { $0.id }
            self.wordNames = fetchedWordInfo.map { $0.names }
            self.wordMeans = fetchedWordInfo.map { $0.means }
            self.wordDescriptions = fetchedWordInfo.map { $0.descriptions }
            
            // Fetch language info
            await fetchLanguageInfo(cardId: cardId)
        } catch {
            print(error)
        }
    }
    
    private func fetchLanguageInfo(cardId: String) async {
        do {
            let fetch = try await FirebaseService.shared.fetchSourceAndTargetLang(cardId: cardId)
            self.sourceLang = fetch.first?.sourceLang ?? "TR"
            self.targetLang = fetch.first?.targetLang ?? "EN"
        } catch {
            print("❌ Error fetching language info: \(error)")
        }
    }

    func deleteCard(at index: Int, deckId: String) {
        guard index >= 0 && index < self.wordNames.count else {
            print("Index out of range")
            return
        }
        let cardId = self.cardIds[index]
        Task { @MainActor in
            do {
                try await FirebaseService.shared.deleteCardInfoAndTransactions(deckId: deckId, cardId: cardId)
                self.wordInfo.remove(at: index)
                self.wordNames.remove(at: index)
                self.wordMeans.remove(at: index)
                self.cardIds.remove(at: index)
                self.wordDescriptions.remove(at: index)
            } catch {
                print("Error deleting card: \(error.localizedDescription)")
            }
        }
    }
}
