//
//  TranslateView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 2.03.2024.
//

//
// TranslateView.swift
// WordRemSwiftUI
//
// Created by Ahmet Göktürk Kurt on 2.03.2024.
//

import SwiftUI

struct TranslationView: View {
    @StateObject var viewModel = TranslateViewModel()
    @State private var inputText: String = ""
    @State private var sourceLang: Language = .english
    @State private var targetLang: Language = .turkish
    @State private var isEditing: Bool = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    TextField("Enter text", text: $inputText)
                        .padding()
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .font(.title)
                        .onChange(of: inputText) { newValue in
                            viewModel.clearTranslatedText()
                            Task {
                                await viewModel.translate(text: newValue, sourceLang: sourceLang.code, targetLang: targetLang.code)
                            }
                        }
                    Spacer()
                    
                    LineForTranslateView()
                    
                    Text(viewModel.translatedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title)
                    
                    Spacer()
                    
                    HStack {
                        Picker("Source Language", selection: $sourceLang) {
                            ForEach(Language.allCases, id: \.self) { language in
                                Text(language.rawValue)
                                    .tag(language)
                                    .foregroundStyle(.white)
                            }
                        }
                        .accentColor(.white)
                        .padding()
                        .background(Color(hex: "#313a45"))
                        Spacer()
                        
                        Button(action: {
                            let tempLang = sourceLang
                            sourceLang = targetLang
                            targetLang = tempLang
                        }) {
                            Image(systemName: "arrow.swap")
                                .accentColor(.primary)
                                .padding()
                        }
                        
                        
                        Picker("Target Language", selection: $targetLang) {
                            ForEach(Language.allCases, id: \.self) { language in
                                Text(language.rawValue)
                                    .tag(language)
                                    .foregroundStyle(.white)
                            }
                        }
                        .accentColor(.white)
                        .padding()
                        .background(Color(hex: "#313a45"))
                    }
                    .padding()
                    
                    Spacer()
                    
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Translation Error"),
                                message: Text("There was a problem translating the text. Please try again later."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                }
                .padding()
                .navigationTitle("Deeply Translate")
                .navigationBarTitleDisplayMode(.inline)
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
        }
    }
}

#Preview {
    TranslationView()
}
