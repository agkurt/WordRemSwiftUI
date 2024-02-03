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
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter a Word", text: $sentenceViewModel.word)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                Button("Fetch Words") {
                    sentenceViewModel.fetchAllWords()
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Word: \(sentenceViewModel.exampleWords?.word ?? "")")
                        .font(.headline)
                    Text("Examples:")
                        .font(.headline)
                        .foregroundColor(.blue)
                    ForEach(sentenceViewModel.exampleWords?.examples ?? [], id: \.self) { example in
                        Text("- \(example)")
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))
                .cornerRadius(10)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Get Example Word")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text("Don't use different language word.This is just perceive english word"), dismissButton: .default(Text("OK")))
            }
        }
        .onReceive(sentenceViewModel.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                showAlert = true
            }
        }
    }
}

#Preview {
    GetWordsView()
}
