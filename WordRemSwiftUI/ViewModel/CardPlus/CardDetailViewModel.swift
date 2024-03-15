//
//  CardDetailViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import Foundation

class CardDetailViewModel: ObservableObject {
    
    @Published public var wordNames: [String] = []
    @Published public var wordMeans: [String] = []
    @Published public var wordDescriptions: [String] = []
    
    func fetchCardInfo(cardId:String) async {
        let (fetchWordNames,fetchWordMeans,fetchedWordDescription) = await FirebaseService.shared.fetchTheCardNameInfo(cardId: cardId)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.wordNames = fetchWordNames
            self.wordMeans = fetchWordMeans
            self.wordDescriptions = fetchedWordDescription
        }
    }
    
}
