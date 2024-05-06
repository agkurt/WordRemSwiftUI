//
//  CardTextFieldViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

@MainActor
class CardPlusViewModel: ObservableObject {
    
    @Published var wordName: String = ""
    @Published var wordMean: String = ""
    @Published var wordDescription: String = ""
    @Published var examplesWord:ExampleWord?
    @Published var isDelete = false
    @Published var sourceLang:[String] = []
    @Published var targetLang:[String] = []
    @Published var translatedText = ""
    @Published var isLoading = false
    @Published var isLoadingSentence = false
    
    func addWordToCard(cardId:String) async {
        await FirebaseService.shared.addWordToCard(cardId: cardId, wordName: wordName, wordMean: wordMean, wordDescription: wordDescription)
    }
    
    func createSentenceUseToWord(name:String) async {
        isLoadingSentence = true
        URLSessionApiService.shared.getWords(word: name) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self.examplesWord = data
                    self.wordDescription = self.examplesWord?.examples.first ?? ""
                    self.isLoadingSentence = false
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    self.isLoadingSentence = false
                }
            }
        }
    }
    
    func fetchLanguageInfo(cardId:String) async {
        do {
            let fetch = try await FirebaseService.shared.fetchSourceAndTargetLang(cardId: cardId)
            DispatchQueue.main.async {
                self.sourceLang = fetch.map { $0.sourceLang ?? ""}
                self.targetLang = fetch.map { $0.targetLang ?? ""}
            }
        }catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    func translateForWordName(targetLang:String, sourceLang:String,text:String) async  {
        self.isLoading = true
        URLSessionApiService.shared.getTranslate(text: text, targetLang: targetLang, sourceLang: sourceLang) { result in
            switch result {
            case .success(let translationResponse):
                print(translationResponse)
                DispatchQueue.main.async {
                    if let translation = translationResponse.translations.first {
                        self.translatedText = translation.text
                        self.wordMean = translation.text
                        self.isLoading = false
                    } else {
                        print("No translation found.")
                    }
                }
            case .failure(let error):
                print(error)
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

