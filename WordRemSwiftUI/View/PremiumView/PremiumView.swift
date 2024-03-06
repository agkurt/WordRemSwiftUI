//
//  PremiumView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 20.02.2024.
//

import SwiftUI

struct PremiumView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PremiumView()
}
