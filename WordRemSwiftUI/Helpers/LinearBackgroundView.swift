//
//  LinearBackgroundView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 14.02.2024.
//

import SwiftUI

struct LinearBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: getColorBasedOnScheme(), // Dynamic color selection
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }

    @Environment(\.colorScheme) private var colorScheme

    private func getColorBasedOnScheme() -> Gradient {
        switch colorScheme {
        case .light:
            return Gradient(colors: [
                Color.white
            ])
        case .dark:
            return Gradient(colors: [
                Color(hex: "#222831"),
                Color(hex: "#171A20")
            ])
        default:
            return Gradient(colors: [.gray, .black])
        }
    }
}


#Preview {
    LinearBackgroundView()
}
