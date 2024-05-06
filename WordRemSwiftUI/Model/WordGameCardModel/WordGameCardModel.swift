//
//  CardModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 5.05.2024.
//

import Foundation
import UIKit

struct WordGameCardModel:Hashable,Identifiable {
    var word:String
    var mean:String
    var id:Int64?
    var imageData:Data?
    
    var image: UIImage? {
        guard let imageData = self.imageData else { return nil }
        return UIImage(data: imageData)!
      }
    
}
