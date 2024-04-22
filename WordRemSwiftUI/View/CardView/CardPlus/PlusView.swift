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
                VStack(alignment:.center) {
                    FlagSelectionView(selectedFlag: $viewModel.selectedFlag)
                    TextFieldView(text: $viewModel.cardName, placeholder: "Card name")
                        .shadow(radius: 10)
                        .padding()
                    Button(action: {
                        Task {
                            await viewModel.addCardName()
                            completion()
                        }
                        dismiss()
                    }, label: {
                        Text("Done")
                            .padding()
                    })
                    .disabled(viewModel.cardName.isEmpty)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    PlusView(completion: {
        
    })
}
