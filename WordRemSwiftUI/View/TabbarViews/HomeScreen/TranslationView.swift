//
//  TranslateView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import SwiftUI

struct TranslationView: View {
    @ObservedObject var viewModel: TranslateViewModel
    
    @State private var inputText: String = ""
    @State private var sourceLang: Language = .english
    @State private var targetLang: Language = .turkish
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    
                    TextFieldView(text: $inputText,placeholder:"Enter the text to translate" )
                        .padding()
                    
                    Picker("Source Language", selection: $sourceLang) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.rawValue)
                                .tag(language)
                        }
                    }
                    .padding()
                    
                    Picker("Target Language", selection: $targetLang) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.rawValue)
                                .tag(language)
                        }
                    }
                    .padding()
                    
                    Button("Translate") {
                        viewModel.clearTranslatedText()
                        viewModel.translate(text: inputText, sourceLang: sourceLang.code, targetLang: targetLang.code)
                    }
                    .padding()
                    
                    Text(viewModel.translatedText)
                        .padding()
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Deeply Translate")
            .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    TranslationView(viewModel: TranslateViewModel())
}



