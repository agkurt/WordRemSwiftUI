//
//  CardDetailViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import Foundation

class CardDetailViewModel: ObservableObject {
    
    @Published var wordNames: [String] = []
    @Published var wordMeans: [String] = []
    @Published var wordDescriptions: [String] = []
    @Published var translatedText: [String] = []
    
    func fetchCardInfo(cardId:String) async throws {
        let fetchedWordInfo = await FirebaseService.shared.fetchTheCardNameInfo(cardId: cardId)
        OperationQueue.main.addOperation {
            self.wordNames = fetchedWordInfo.map {$0.names}
            self.wordMeans = fetchedWordInfo.map {$0.means}
            self.wordDescriptions = fetchedWordInfo.map { $0.descriptions}
            self.objectWillChange.send()
        }
    }
}
