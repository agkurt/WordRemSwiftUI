//
//  LineForTranslateView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.03.2024.
//

import SwiftUI
struct LineForTranslateView: View {
    
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
