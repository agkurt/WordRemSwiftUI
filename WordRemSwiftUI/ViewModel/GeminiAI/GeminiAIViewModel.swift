//
//  GeminiAIViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 16.03.2024.
//

import Foundation

@MainActor
final class GeminiAIViewModel: ObservableObject {
    @Published var userPrompt: String = ""
    @Published var messages: [AIMessage] = []
    @Published var newMessage: String = ""
    
    func receiveMessage(_ message: AIMessage) {
        messages.append(message)
    }
    
    func fetchAnswer() {
        userPrompt = newMessage
        Task {
            if let answer = await URLSessionApiService.shared.geminiApi(userPrompt: userPrompt) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.receiveMessage(answer)
                }
            }
        }
    }
}

