//
//  QuizMode.swift
//  WordRemSwiftUI
//

import Foundation

enum QuizMode: String, CaseIterable, Identifiable {
    case multipleChoice = "Multiple Choice"
    case trueFalse      = "True / False"
    case writing        = "Writing"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .multipleChoice: return "list.bullet.clipboard"
        case .trueFalse:      return "checkmark.circle"
        case .writing:        return "pencil.line"
        }
    }

    var description: String {
        switch self {
        case .multipleChoice: return "Choose the correct meaning from 4 options"
        case .trueFalse:      return "Decide if the word-meaning pair is correct"
        case .writing:        return "Type the meaning of the word"
        }
    }

    var minimumWordCount: Int {
        switch self {
        case .multipleChoice: return 4
        case .trueFalse:      return 2
        case .writing:        return 1
        }
    }
}
