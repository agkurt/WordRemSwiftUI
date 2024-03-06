//
//  Language.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import Foundation

enum Language: String, CaseIterable {
    case arabic = "Arabic"
    case bulgarian = "Bulgarian"
    case czech = "Czech"
    case danish = "Danish"
    case german = "German"
    case greek = "Greek"
    case english = "English"
    case spanish = "Spanish"
    case estonian = "Estonian"
    case finnish = "Finnish"
    case french = "French"
    case hungarian = "Hungarian"
    case indonesian = "Indonesian"
    case italian = "Italian"
    case japanese = "Japanese"
    case korean = "Korean"
    case lithuanian = "Lithuanian"
    case latvian = "Latvian"
    case norwegian = "Norwegian (Bokmål)"
    case dutch = "Dutch"
    case polish = "Polish"
    case portuguese = "Portuguese (all Portuguese varieties mixed)"
    case romanian = "Romanian"
    case russian = "Russian"
    case slovak = "Slovak"
    case slovenian = "Slovenian"
    case swedish = "Swedish"
    case turkish = "Turkish"
    case ukrainian = "Ukrainian"
    case chinese = "Chinese"
    
    var code: String {
        switch self {
        case .arabic: return "AR"
        case .bulgarian: return "BG"
        case .czech: return "CS"
        case .danish: return "DA"
        case .german: return "DE"
        case .greek: return "EL"
        case .english: return "EN"
        case .spanish: return "ES"
        case .estonian: return "ET"
        case .finnish: return "FI"
        case .french: return "FR"
        case .hungarian: return "HU"
        case .indonesian: return "ID"
        case .italian: return "IT"
        case .japanese: return "JA"
        case .korean: return "KO"
        case .lithuanian: return "LT"
        case .latvian: return "LV"
        case .norwegian: return "NB"
        case .dutch: return "NL"
        case .polish: return "PL"
        case .portuguese: return "PT"
        case .romanian: return "RO"
        case .russian: return "RU"
        case .slovak: return "SK"
        case .slovenian: return "SL"
        case .swedish: return "SV"
        case .turkish: return "TR"
        case .ukrainian: return "UK"
        case .chinese: return "ZH"
        }
    }
}


