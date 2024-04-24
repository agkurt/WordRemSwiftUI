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
    @Published var sourceLang:[String] = []
    @Published var targetLang:[String] = []
    @Published var translatedText = ""
    
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
    
    func fetchLanguageInfo(cardId:String) async {
        do {
            let fetch = try await FirebaseService.shared.fetchSourceAndTargetLang(cardId: cardId)
            OperationQueue.main.addOperation {
                self.sourceLang = fetch.map { $0.sourceLang ?? ""}
                self.targetLang = fetch.map { $0.targetLang ?? ""}
            }
        }catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    func translateForWordName(targetLang:String, sourceLang:String,text:String) async {
        URLSessionApiService.shared.getTranslate(text: text, targetLang: targetLang, sourceLang: sourceLang) { result in
            switch result {
            case .success(let translationResponse):
                print(translationResponse)
                OperationQueue.main.addOperation {
                    if let translation = translationResponse.translations.first {
                        self.translatedText = translation.text
                    } else {
                        print("No translation found.")
                    }
                }
            case .failure(let error):
                print(error)
                print(error.localizedDescription)
            }
        }
    }
}

