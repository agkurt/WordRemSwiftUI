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
            .background(Color(hex: "#1c2127"))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
        }
    }
}


#Preview {
    CardView(title: "Pencil", image: Image(systemName: "pencil"))
}
