//
//  CardTextFieldViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

class CardPlusViewModel: ObservableObject {
    @Published public var wordName: String = ""
    @Published public var wordMean: String = ""
    @Published public var wordDescription: String = ""
    
    func addWordToCard(cardId:String) async {
        do {
            try await FirebaseService.shared.addWordToCard(cardId: cardId, wordName: wordName, wordMean: wordMean, wordDescription: wordDescription)
            print("Word added successfully")
        } catch {
            print("Error adding word: \(error)")
        }
    }
}
