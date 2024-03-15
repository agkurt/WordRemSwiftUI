//
//  GeminiAI.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 15.03.2024.
//

import SwiftUI

struct GeminiAIView: View {
    @ObservedObject var viewModel = GeminiAIViewModel()
    @State private var newMessage: String = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages, id: \.content) { message in
                    HStack {
                        if message.sender == .user {
                            Spacer()
                            Text(message.content)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text(message.content)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                }
            }
            
            HStack {
                TextField("Mesajınızı yazın...", text: $newMessage)
                Button(action: {
                    let userMessage = AIMessage(sender: .user, content: newMessage)
                    viewModel.receiveMessage(userMessage)
                    viewModel.newMessage = newMessage
                    viewModel.fetchAnswer()
                    newMessage = ""
                }) {
                    Text("Gönder")
                }
            }
            .padding()
        }
    }
}


#Preview {
    GeminiAIView()
}
