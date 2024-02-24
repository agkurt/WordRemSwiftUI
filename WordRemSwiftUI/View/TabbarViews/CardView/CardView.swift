//
//  CardView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 24.02.2024.
//

import SwiftUI


struct CardView: View {
    var title: String
    var subtitle: String
    var image: Image

    var body: some View {
        GeometryReader { geometry in
            VStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipped()
                    .padding()
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            .frame(maxWidth: geometry.size.width * 1)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
        }
    }
}

#Preview {
    CardView(title: "Pencil", subtitle: "Use the for write process", image: Image(systemName: "pencil"))
}
