//
//  WordGameViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 5.05.2024.
//

import Foundation
import SQLite
import SwiftUI

class WordGameViewModel: ObservableObject {
    
    @Published var words: [String] = []
    @Published var means: [String] = []
    @Published var id: Int64 = 0
    @Published var cardModels: [WordGameCardModel] = []
    
    func sqlLite() {
        do {
            let db = try Connection(Bundle.main.path(forResource: "WordDataBase", ofType: "db") ?? "")
            let wordsTable = Table("Words")
            let id = Expression<Int64>("id")
            let word = Expression<String>("word")
            let mean = Expression<String>("mean")
            let image = Expression<Data?>("image")

            
            for wordRow in try db.prepare(wordsTable) {
                let currentWord = try wordRow.get(word)
                let currentMean = try wordRow.get(mean)
                let currentImageData = try wordRow.get(image)
                let cardModel = WordGameCardModel(word: currentWord, mean: currentMean, id: try wordRow.get(id), imageData: currentImageData)
                
                self.cardModels.append(cardModel)
                self.words.append(currentWord)
                self.means.append(currentMean)
                print("id: \(try wordRow.get(id)), word: \(currentWord), mean: \(try wordRow.get(mean))")
            }
        } catch {
            print(error)
        }
    }
    
    func fetchImage() async throws {
        do {
            
        }
    }
}





