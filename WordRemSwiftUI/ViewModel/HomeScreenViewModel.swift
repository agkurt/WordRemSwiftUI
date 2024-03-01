//
//  HomeScreenViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import SwiftUI

class HomeScreenViewModel: ObservableObject {
    
    @Published public var cardNames: [String] = []
    @Published public var cardIds: [String] = []
    
    func fetchCardName() async {
        let (fetchedCardNames, fetchedCardIds) = await FirebaseService.shared.fetchCardName()
        DispatchQueue.main.async {
            self.cardNames = fetchedCardNames
            self.cardIds = fetchedCardIds
        }
    }
}




