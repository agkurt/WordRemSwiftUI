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
    @Binding var isEditing: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                Spacer()
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
            if isEditing {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            Task {
                               try await FirebaseService.shared.deleteCards()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1c2127"))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}
