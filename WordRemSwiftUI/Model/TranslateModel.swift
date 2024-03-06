//
//  TranslateModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import Foundation

struct TranslationResponse: Codable {
    let translations: [Translation]
}

struct Translation: Codable {
    let detected_source_language: String
    let text: String
}
