//
//  PlusViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 25.02.2024.
//

import SwiftUI

@MainActor // main thread
final class PlusViewModel:ObservableObject {
    
    @Published var cardName = ""
    @Published var selectedFlag:FlagModel = .english
    @Published var sourceLanguage: Language = .english
    @Published var targetLanguage: Language = .turkish
    
    func addCardNameInfo() async {
        await FirebaseService.shared.addCardNameInfo(name: cardName, selectedFlag: selectedFlag,sourceLang: sourceLanguage.code,targetLang: targetLanguage.code)
    }
}
