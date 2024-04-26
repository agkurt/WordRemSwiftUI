//
//  LineView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.02.2024.
//

import SwiftUI

struct LineView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Spacer()
                .frame(height: 1)
                .background(getColorBasedOnScheme())
            
            Spacer()
                .frame(height: 1)
                .background(getColorBasedOnScheme())
        }
    }
    
    private func getColorBasedOnScheme() -> Color {
           switch colorScheme {
           case .light:
               return .black
           case .dark:
               return .white
           default:
               return .gray
           }
       }
}
