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
    @Published var examplesWord:ExampleWord?
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
                OperationQueue.main.addOperation {
                    self.examplesWord = data
                }
                
            case .failure(let error):
                print("error fetch the words")
                print(error)
            }
        }
    }
}
