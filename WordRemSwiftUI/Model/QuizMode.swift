//
//  QuizMode.swift
//  WordRemSwiftUI

import Foundation

enum QuizMode: String, CaseIterable, Identifiable {
    case multipleChoice = "Multiple Choice"
    case trueFalse      = "True / False"
    case writing        = "Writing"
    /// Kelimeyi dinle → doğru anlamı seç
    case listening      = "Listening"
    /// Kelimeyi gör/duy → mikrofona söyle
    case speaking       = "Speaking"
    /// Cümledeki boşluğu doldur
    case fillInTheBlank  = "Fill in the Blank"
    /// Kelimeleri doğru sırayla diz
    case sentenceBuilder = "Sentence Builder"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .multipleChoice: return "list.bullet.clipboard"
        case .trueFalse:      return "checkmark.circle"
        case .writing:        return "pencil.line"
        case .listening:      return "speaker.wave.2.fill"
        case .speaking:       return "mic.fill"
        case .fillInTheBlank:  return "text.insert"
        case .sentenceBuilder: return "list.number"
        }
    }

    var description: String {
        switch self {
        case .multipleChoice: return "Choose the correct meaning from 4 options"
        case .trueFalse:      return "Decide if the word-meaning pair is correct"
        case .writing:        return "Type the meaning of the word"
        case .listening:      return "Listen to the word and choose its meaning"
        case .speaking:       return "Hear the word and repeat it aloud"
        case .fillInTheBlank:  return "Complete the sentence with the missing word"
        case .sentenceBuilder: return "Arrange the words to form a correct sentence"
        }
    }

    var minimumWordCount: Int {
        switch self {
        case .multipleChoice: return 4
        case .trueFalse:      return 2
        case .writing:        return 1
        case .listening:      return 4
        case .speaking:       return 1
        case .fillInTheBlank:  return 4
        case .sentenceBuilder: return 2
        }
    }
}
