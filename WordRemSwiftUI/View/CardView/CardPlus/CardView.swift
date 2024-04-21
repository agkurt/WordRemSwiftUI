//
//  CardView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 24.02.2024.
//

import SwiftUI

struct CardView: View {
    
    var title: String
    var onDelete: () -> Void
    @Binding var isEditing: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "pencil")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 100,maxHeight: 100)
                Spacer()
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            if isEditing {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.white)
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

