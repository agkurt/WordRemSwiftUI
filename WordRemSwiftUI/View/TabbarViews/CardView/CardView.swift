//
//  CardView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 24.02.2024.
//

import SwiftUI

struct CardView: View {
    var title: String
    var image: Image

    // State variable for individual card animation
    @State private var cardOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .padding()
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: geometry.size.width)
            // Apply animation offset
            .offset(y: cardOffset)
            .background(Color(hex: "#8b6072"))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
            // Handle tap gesture for animation
            .onTapGesture {
                withAnimation(.spring()) {
                    // Animate card down by 50 points (adjust as needed)
                    cardOffset += 50
                }
            }
        }
    }
}


#Preview {
    CardView(title: "Pencil", image: Image(systemName: "pencil"))
}
