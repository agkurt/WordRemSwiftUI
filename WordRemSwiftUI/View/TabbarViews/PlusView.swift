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
                        
                    Button(action: {
                        Task {
                            await viewModel.addCardName()
                        }
                        dismiss()
                        
                    }, label: {
                        Text("Done")
                    })
                    .buttonStyle(LoginButtonStyle())
                    
                }
            }
            .navigationTitle("PlusView")
            .toolbar {
                ToolbarItem {
                    Button ("kapat", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
        
    }
}

struct PlusView_Previews: PreviewProvider {
    static var previews: some View {
        PlusView()
    }
}



