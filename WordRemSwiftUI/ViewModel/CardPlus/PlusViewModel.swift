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
    
    func addCardName() async {
        await FirebaseService.shared.addCardNameAndFlag(name: cardName, selectedFlag: selectedFlag)
        OperationQueue.main.addOperation {
            self.isLoading = true
        }
    }
}
