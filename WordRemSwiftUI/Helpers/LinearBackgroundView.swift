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
            gradient: Gradient(colors: [Color(hex: "#222831")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
}


#Preview {
    LinearBackgroundView()
}
