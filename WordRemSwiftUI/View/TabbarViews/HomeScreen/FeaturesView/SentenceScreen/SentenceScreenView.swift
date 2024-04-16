//
//  TRY.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import SwiftUI

struct SentenceScreenView: View {
    @EnvironmentObject var sentenceViewModel: SentenceViewModel
    @State private var showAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    TextFieldView(text: $sentenceViewModel.word, placeholder: "Enter a word")
                        .padding()
                        .autocapitalization(.none)
                    
                    Button("Fetch The Sentence") {
                        sentenceViewModel.fetchAllWords()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    
                    .padding()
                    .foregroundColor(.white)
                    .background(Color(hex: "#313a45"))
                    .cornerRadius(30)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            if sentenceViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            else {
                                
                                VStack(alignment:.leading) {
                                    Text("Word: \(sentenceViewModel.exampleWords?.word ?? "")")
                                        .font(.headline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity,alignment:.leading)
                                    Text("Examples:")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                }
                                
                                ForEach(sentenceViewModel.exampleWords?.examples ?? [], id: \.self) { example in
                                    Text("- \(example)")
                                }
                                
                                if sentenceViewModel.exampleWords?.examples.indices.isEmpty == true {
                                    Text(" - No sentences related to this word found. Use the different word.")
                                        .bold()
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Spacer()
                        
                        .padding()
                        .cornerRadius(30)
                    }
                    .padding()
                }
            }
            
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
            .navigationTitle("Sentence")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text("Use only the English word to bring sentences together"), dismissButton: .default(Text("OK")))
            }
        }
        .onReceive(sentenceViewModel.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                showAlert = true
                print(errorMessage)
            }
        }
    }
}

#Preview {
    SentenceScreenView()
}

