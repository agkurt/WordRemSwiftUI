//
//  WordCardView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 5.05.2024.
//

import SwiftUI

struct WordCardView: View {
    
    @Binding var word: String
    @Binding var mean: String
    @Binding var ifTouchToLearn: Bool
    @Binding var imageData: Data?
    @State var successWord = 0.0
    
    var body: some View {
        VStack {
            VStack(alignment:.center, spacing: 10) {
                LazyVStack {
                    Slider(
                        value: $successWord,
                        in: 1...5
                    )
                    if let imageData = imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                        
                        LineView()
                        Text(word)
                            .font(.title)
                        Text(mean)
                            .font(.callout)
                    }
                }
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary, lineWidth: 0.4)
                )
                .opacity(1)
                .padding()
            }
        }
    }
}
