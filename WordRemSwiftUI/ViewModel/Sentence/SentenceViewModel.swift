//
//  SentenceViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import Foundation
import SwiftUI

@MainActor
final class SentenceViewModel:ObservableObject {
    
    @Published var exampleWords: ExampleWord?
    @Published var word: String = ""
    @Published var errorMessage: String?
    @Published var colorScheme: ColorScheme?
    @Published var isLoading = false
    
    func fetchAllWords() {
        URLSessionApiService.shared.getWords(word: word) { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let exampleWord):
                    self.exampleWords = exampleWord
                case .failure(let error): 
                    self.errorMessage = error.localizedDescription
                    print("Error: \(error)")
                }
            }
        }
    }
    
    func getColorBasedOnScheme() -> Color  {
        switch colorScheme {
        case .light:
            return Color.init(hex: "#a2a7ac")
            
        case .dark:
            return Color.init(hex: "#1c2127")
            
        default:
            return Color.init(hex:"#313a45")
        }
    }
    
}
