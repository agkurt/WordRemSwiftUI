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
    @ObservedObject var viewModel = HomeScreenViewModel()
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            if viewModel.isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.blue)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1c2127"))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

