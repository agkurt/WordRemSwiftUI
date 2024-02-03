//
//  SentenceViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import Foundation

class SentenceViewModel:ObservableObject {
    
    @Published var exampleWords: ExampleWord?
    @Published var word: String = ""
    @Published var errorMessage: String?
    
    func fetchAllWords() {
        URLSessionApiService.shared.getWords(word: word) { result in
            switch result {
            case .success(let exampleWord):
                DispatchQueue.main.async {
                    self.exampleWords = exampleWord
                }
                print("Word: \(exampleWord.word)")
                print("Examples: \(exampleWord.examples)")
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                print("Error: \(error)")
            }
        }
    }
}
