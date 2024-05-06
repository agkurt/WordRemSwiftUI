//
//  CardViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 22.04.2024.
//

import Foundation

@MainActor
class CardViewModel: ObservableObject {
    
    @Published var selectedFlag:FlagModel = .turkey
    
}
