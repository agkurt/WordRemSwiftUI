//
//  TranslateViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import Foundation

class TranslateViewModel:ObservableObject {
    @Published var text = ""
    @Published var englishModels: TranslateModel?
    
    func getTranslate() {
        URLSessionApiService.shared.getTranslation(text: text) { result in
            switch result {
            case .success(let translationModel):
                let translatedText = translationModel.translations[0].text
                print("Çevrilmiş metin:", translatedText)
            case .failure(let error):
                print("Hata:", error)
            }
        }
    }
}
