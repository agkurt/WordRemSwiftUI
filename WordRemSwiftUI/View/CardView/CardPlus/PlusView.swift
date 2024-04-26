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
                    Text("Translate işlemi için dil seçimi ")
                    HStack {
                        
                        Text("Source Language")
                        Spacer()
                        
                        Picker("Source Language", selection: $viewModel.sourceLanguage) {
                            ForEach(Language.allCases, id: \.self) { language in
                                Text(language.rawValue)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                    .padding()
                    
                    HStack {
                        Text("Target Language")
                        Spacer()
                        Picker("Target Language", selection: $viewModel.targetLanguage) {
                            ForEach(Language.allCases, id: \.self) { language in
                                Text(language.rawValue)
                            }
                        }
                        
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                    .padding()
                    TextFieldView(text: $viewModel.cardName, placeholder: "Card name")
                        .shadow(radius: 10)
                        .padding()
                    Button(action: {
                        Task {
                            await viewModel.addCardNameInfo()
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
