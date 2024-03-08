//
//  TRY.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import SwiftUI

struct GetWordsView: View {
    @ObservedObject var sentenceViewModel = SentenceViewModel()
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
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color(hex: "#313a45"))
                    .cornerRadius(30)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        if sentenceViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        else {
                            Text("Word: \(sentenceViewModel.exampleWords?.word ?? "")")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Examples:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
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
                    .padding()
                    .cornerRadius(30)
                    .background(Color.gray.opacity(0.2))
                    .padding()
                    Spacer()
                }
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
    GetWordsView()
}

