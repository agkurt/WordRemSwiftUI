//
//  CardTextFieldViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import Foundation

class CardTextFieldViewModel:ObservableObject {
    
    @Published public var wordName:String = ""
    @Published public var wordMean:String = ""
    @Published public var wordDescription:String = ""
    
    
}
