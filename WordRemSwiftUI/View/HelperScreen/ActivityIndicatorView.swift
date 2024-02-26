//
//  ActivityIndicatorView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 18.02.2024.
//

import SwiftUI

struct ActivityIndicatorView: View {
    
    let color: Color
    @Binding var isAnimating : Bool
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .opacity(0.15)
                .scaleEffect(isAnimating ? 0.8 : 1)
                .animation(Animation.easeInOut
                    .repeatForever(autoreverses: true),value: 0)
            
            Circle()
                .fill(color)
                .opacity(0.30)
                .scaleEffect(isAnimating ? 0.6 : 1)
                .frame(width: 75,height: 75)
                .animation(Animation.easeInOut.repeatForever(autoreverses: true),value: 0)
            
            Circle()
                .fill(color)
                .frame(width: 50,height: 50)
                .scaleEffect(isAnimating ? 0.4 : 1)
                .animation(Animation.easeInOut.repeatForever(autoreverses: true),value: 0)
        }
    }
}

