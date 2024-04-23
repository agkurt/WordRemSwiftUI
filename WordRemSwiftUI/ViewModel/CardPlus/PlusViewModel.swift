//
//  PlusViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 25.02.2024.
//

import SwiftUI

class PlusViewModel:ObservableObject {
    
    @Published public var cardName = ""
    @Published var isLoading = false
    @Published var selectedFlag:FlagModel = .turkey
    @Published var sourceLanguage: Language = .english
    @Published var targetLanguage: Language = .turkish
    
    func addCardNameInfo() async {
        await FirebaseService.shared.addCardNameInfo(name: cardName, selectedFlag: selectedFlag,sourceLang: sourceLanguage.rawValue,targetLang: targetLanguage.rawValue)
        OperationQueue.main.addOperation {
            self.isLoading = true
        }
    }
}
