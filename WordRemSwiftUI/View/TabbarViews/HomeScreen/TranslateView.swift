//
//  TranslateView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import SwiftUI

struct TranslateView: View {
    @ObservedObject var viewModel = TranslateViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                TextFieldView(text: $viewModel.text,placeholder: "Word")
                    .padding()
                Button {
                    viewModel.getTranslate()
                } label: {
                    Text("Get Translate")
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                
                ForEach(viewModel.englishModels?.translations ?? [], id: \.self) { translation in
                    Text(translation.text)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))
                .cornerRadius(10)
                .padding()
            }
            .navigationTitle("Translate Word")
        }
    }
}

#Preview {
    TranslateView()
}
