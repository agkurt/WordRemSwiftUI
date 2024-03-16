//
//  PlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 20.02.2024.
//

import SwiftUI

struct PlusView: View {
    
    @ObservedObject var viewModel = PlusViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    
                    TextFieldView(text: $viewModel.cardName, placeholder: "Card name")
                        .shadow(radius: 10)
                        .padding()
                    
                    Button(action: {
                        Task {
                            await viewModel.addCardName()
                            viewModel.cardName = ""
                        }
                        dismiss()
                    }, label: {
                        Text("Done")
                            .font(.custom("Poppins-Light", size: 15))
                            .padding()
                            .background(Color(hex: "#313a45"))
                            .foregroundColor(viewModel.cardName.isEmpty ? .red: .white)
                            .opacity(viewModel.cardName.isEmpty ? 0.5 : 1 )
                            .cornerRadius(30)
                    })
                    .disabled(viewModel.cardName.isEmpty)

                }
                .padding()
            }
            .navigationTitle("PlusView")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}




