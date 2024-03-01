//
//  PlusViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 25.02.2024.
//

import SwiftUI

class PlusViewModel:ObservableObject {
    
    @Published public var cardName = ""
           
       func addCardName() async  {
            await FirebaseService.shared.addCardName(name: cardName)
       }
}
