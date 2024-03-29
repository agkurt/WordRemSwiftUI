//
//  CardPlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardPlusView: View {
    @StateObject private var viewModel = CardPlusViewModel()
    @State private var isOnToggle = false
    var cardId:String
    @FocusState private var focusedField: CardFocusableField?
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    Text("Create Your Word")
                        .font(.custom("Poppins-Medium", size: 25))
                        .padding()
                        .frame(maxWidth: .infinity,alignment:.leading)
                    
                    VStack(spacing:20) {
                        CardTextField(text: $viewModel.wordName, placeholder: "Word name")
                            .focused($focusedField, equals: .wordName)
                        CardTextField(text: $viewModel.wordMean, placeholder: "Word mean ")
                            .focused($focusedField, equals: .wordMean)
                        CardTextField(text: $viewModel.wordDescription, placeholder: "Word description")
                            .focused($focusedField, equals: .wordDescription)
                        
                    }
                    .padding()
                    
                    LineView(textPlace: "Set your reminder")
                    
                    Toggle(isOn:$isOnToggle , label: {
                        Text("Reminder")
                        
                    })
                    .padding()
                    Spacer()
                    VStack {
                        Button(action: {
                            Task {
                                await viewModel.addWordToCard(cardId: cardId)
                            }
                            dismiss()
                        }, label: {
                            if viewModel.wordName.isEmpty || viewModel.wordMean.isEmpty || viewModel.wordDescription.isEmpty {
                                Text("Done")
                                    .foregroundStyle(.red)
                                    .padding()
                                    .background(Color.init(hex: "#313a45"))
                                    .clipShape(.rect(cornerRadius: 30))
                                    .opacity(0.5)
                            }else {
                                Text("Done")
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(Color.init(hex: "#313a45"))
                                    .clipShape(.rect(cornerRadius: 30))
                                    .opacity(1)
                            }
                            
                        })
                        .disabled(viewModel.wordName.isEmpty || viewModel.wordMean.isEmpty || viewModel.wordDescription.isEmpty)
                       
                    }
                }
                .ignoresSafeArea(.keyboard)
                .onSubmit(focusNextField)
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
        }
    }
    
    private func focusNextField() {
        switch focusedField {
        case .wordName:
            focusedField = .wordMean
        case .wordMean:
            focusedField = .wordDescription
        case .wordDescription:
            focusedField = .wordMean
        case .none:
            break
        }
    }
}


#Preview {
    CardPlusView(cardId: "agk")
}
