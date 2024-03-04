//
//  EnglishModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import Foundation

// MARK: - EnglishModel
struct TranslateModel: Codable,Hashable {
    let translations: [Translation]
}

// MARK: - Translation
struct Translation: Codable,Hashable {
    let detectedSourceLanguage, text: String
}

