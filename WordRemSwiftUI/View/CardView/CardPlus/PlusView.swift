//
//  PlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 20.02.2024.
//

import SwiftUI

struct PlusView: View {
    @StateObject var viewModel = PlusViewModel()
    @Environment(\.dismiss) private var dismiss
    var completion: () -> Void
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    FlagSelectionView(selectedFlag: $viewModel.selectedFlag)
                    Spacer()
                    TextFieldView(text: $viewModel.cardName, placeholder: "Card name")
                        .shadow(radius: 10)
                    Button(action: {
                        Task {
                            await viewModel.addCardName()
                        }
                        dismiss()
                    }, label: {
                        Text("Done")
                            .padding()
                    })
                    .disabled(viewModel.cardName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PlusView(completion: {
        
    })
}
