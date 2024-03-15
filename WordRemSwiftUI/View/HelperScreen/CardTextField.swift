//
//  CardTextField.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardTextField: View {
    @Binding public var text:String
    var placeholder:String = ""
    @Environment(\.colorScheme) private var colorScheme

    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.custom("Poppins-Light", size: 15))
            .frame(maxWidth: .infinity,alignment:.center)
            .padding()
            .background(getColorBasedOnScheme())
            .foregroundColor(.white)
            .cornerRadius(30)
    }
    
    private func getColorBasedOnScheme() -> Color  {
        switch colorScheme {
        case .light:
            return Color.init(hex: "#a2a7ac")

        case .dark:
            return Color.init(hex: "#1c2127")
            
        default:
            return Color.init(hex:"#313a45")
        }
    }
}


