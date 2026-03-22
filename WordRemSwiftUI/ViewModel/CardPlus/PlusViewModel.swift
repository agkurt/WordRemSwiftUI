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
    
    init() {
        // Load user's saved languages from onboarding
        loadUserLanguages()
    }
    
    func addCardNameInfo() async {
        await FirebaseService.shared.addCardNameInfo(name: cardName, selectedFlag: selectedFlag,sourceLang: sourceLanguage.code,targetLang: targetLanguage.code)
    }
    
    private func loadUserLanguages() {
        // Load native language as source
        if let nativeCode = UserDefaults.standard.string(forKey: "userNativeLanguage"),
           let native = Language.allCases.first(where: { $0.code == nativeCode }) {
            sourceLanguage = native
        }
        
        // Load target language from onboarding
        if let targetCode = UserDefaults.standard.string(forKey: "userTargetLanguage"),
           let target = Language.allCases.first(where: { $0.code == targetCode }) {
            targetLanguage = target
            
            // Set flag based on target language
            selectedFlag = flagForLanguage(target)
        }
    }
    
    private func flagForLanguage(_ language: Language) -> FlagModel {
        switch language.code {
        case "EN": return .english
        case "TR": return .turkey
        case "FR": return .french
        case "DE": return .german
        case "IT": return .italian
        case "RU": return .russian
        case "JA": return .japanese
        case "KO": return .korean
        case "ZH": return .chinese
        case "AR": return .arabic
        case "BG": return .bulgarian
        case "CS": return .czech
        case "ET": return .estonian
        case "EL": return .greek
        case "HU": return .hungarian
        case "ID": return .indonesian
        case "LV": return .latvian
        case "LT": return .lithuanian
        case "RO": return .romanian
        case "SV": return .swedish
        case "UK": return .ukrainian
        // Languages without matching flags - default to English
        case "ES", "PT", "FI", "DA", "NB", "NL", "PL", "SK", "SL": 
            return .english
        default: return .english
        }
    }
}

