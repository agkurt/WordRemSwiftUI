//
//  LineView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.02.2024.
//

import SwiftUI

struct LineView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @State var textPlace:String
    
    var body: some View {
        HStack {
            Spacer()
                .frame(height: 1)
                .background(getColorBasedOnScheme())
            
            Text(textPlace)
                .padding(.horizontal)
                .frame(width: 170)
            
            Spacer()
                .frame(height: 1)
                .background(getColorBasedOnScheme())
        }
    }
    
    private func getColorBasedOnScheme() -> Color {
           switch colorScheme {
           case .light:
               return .black // Black line in light mode
           case .dark:
               return .white // White line in dark mode 
           default:
               return .gray // Fallback
           }
       }
}
