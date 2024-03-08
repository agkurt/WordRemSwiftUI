//
//  TranslateViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import Foundation

class TranslateViewModel: ObservableObject {
    @Published var translatedText: String = ""
    @Published var showAlert = false

    func translate(text: String, sourceLang: String, targetLang: String) {
       URLSessionApiService.shared.getTranslate(text: text, targetLang: targetLang, sourceLang: sourceLang) { result in
         DispatchQueue.main.async {
           switch result {
           case .success(let translationResponse):
             print(translationResponse)
             if let translation = translationResponse.translations.first {
               self.translatedText = translation.text
             } else {
               print("No translation found.")
             }
           case .failure(let error):
             print("Error translating text: \(error.localizedDescription)")
             // Set showAlert to true on translation error
             self.showAlert = true
           }
         }
       }
     }
    
    func clearTranslatedText() {
        self.translatedText = ""
    }
}


