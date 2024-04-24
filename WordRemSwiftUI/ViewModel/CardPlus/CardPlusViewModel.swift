//
//  CardTextFieldViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

class CardPlusViewModel: ObservableObject {
    
    @Published var wordName: String = ""
    @Published var wordMean: String = ""
    @Published var wordDescription: String = ""
    @Published var examplesWord:ExampleWord?
    @Published var isDelete = false
    
    func addWordToCard(cardId:String) async {
        do {
            try await FirebaseService.shared.addWordToCard(cardId: cardId, wordName: wordName, wordMean: wordMean, wordDescription: wordDescription)
            print("Word added successfully")
        } catch {
            print("Error adding word: \(error)")
        }
    }
    
    func createSentenceUseToWord(name:String) async {
        
        URLSessionApiService.shared.getWords(word: name) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self.examplesWord = data
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

