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
                    .foregroundStyle(.white)
               
            }
            
            .frame(maxWidth: geometry.size.width * 1)
            .background(Color(hex: "#8b6072"))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
        }
    }
}

#Preview {
    CardView(title: "Pencil", image: Image(systemName: "pencil"))
}
