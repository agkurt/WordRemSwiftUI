//
//  CardDetailViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import SwiftUI

@MainActor
class CardDetailViewModel: ObservableObject {
    
    @Published var wordNames: [String] = []
    @Published var wordMeans: [String] = []
    @Published var wordDescriptions: [String] = []
    @Published var wordInfo: [WordInfo] = []
    
    func fetchCardInfo(cardId:String) async {
        do {
            let fetchedWordInfo = try await FirebaseService.shared.fetchTheCardNameInfo(cardId: cardId)
            DispatchQueue.main.async {
                self.wordInfo = fetchedWordInfo
                self.wordNames = fetchedWordInfo.map {$0.names}
                self.wordMeans = fetchedWordInfo.map {$0.means}
                self.wordDescriptions = fetchedWordInfo.map { $0.descriptions}
        }
        }catch {
            print(error)
        }
    }
}
