//
//  CardModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 29.02.2024.
//

import Foundation

struct Card: Identifiable {
    var id: String?
    var name: String?
    var selectedFlag: FlagModel?
    var targetLang:String?
    var sourceLang:String?
}
    
