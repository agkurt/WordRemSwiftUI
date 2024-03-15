//
//  AIMessage.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 16.03.2024.
//

import Foundation

struct AIMessage {
    let sender: Sender
    let content: String
}

enum Sender {
    case user
    case assistant
}
