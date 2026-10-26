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
    /// Yeni kelime kartı (puanlanmaz)
    case introduce       = "New Word"
    /// Hedef dildeki cümlenin doğru çevirisini seç
    case translateSentence = "Translate Sentence"
    /// Ana dildeki cümleyi hedef dilde kelime kutucuklarıyla kur
    case buildSentence   = "Build Sentence"
    /// Kelime ↔ anlam eşleştirme
    case matchPairs      = "Match Pairs"

    var id: String { rawValue }

    /// Ekranda görünen ad (uygulama dilinde)
    var title: String {
        switch self {
        case .multipleChoice:    return AL.s(.qmMultipleChoice)
        case .trueFalse:         return AL.s(.qmTrueFalse)
        case .writing:           return AL.s(.qmWriting)
        case .listening:         return AL.s(.qmListening)
        case .speaking:          return AL.s(.qmSpeaking)
        case .fillInTheBlank:    return AL.s(.qmFillBlank)
        case .sentenceBuilder:   return AL.s(.qmSentenceBuilder)
        case .introduce:         return AL.s(.qmIntroduce)
        case .translateSentence: return AL.s(.qmTranslateSentence)
        case .buildSentence:     return AL.s(.qmBuildSentence)
        case .matchPairs:        return AL.s(.qmMatchPairs)
        }
    }

    /// Deste quizinde seçilebilen modlar (ders akışına özel modlar hariç)
    static let deckModes: [QuizMode] = [.multipleChoice, .trueFalse, .writing, .listening, .speaking,
                                        .fillInTheBlank, .sentenceBuilder]

    var icon: String {
        switch self {
        case .multipleChoice: return "list.bullet.clipboard"
        case .trueFalse:      return "checkmark.circle"
        case .writing:        return "pencil.line"
        case .listening:      return "speaker.wave.2.fill"
        case .speaking:       return "mic.fill"
        case .fillInTheBlank:  return "text.insert"
        case .sentenceBuilder: return "list.number"
        case .introduce:       return "sparkles"
        case .translateSentence: return "text.bubble"
        case .buildSentence:   return "square.stack.3d.up"
        case .matchPairs:      return "rectangle.grid.2x2"
        }
    }

    var description: String {
        switch self {
        case .multipleChoice: return AL.s(.qmDescMultipleChoice)
        case .trueFalse:      return AL.s(.qmDescTrueFalse)
        case .writing:        return AL.s(.qmDescWriting)
        case .listening:      return AL.s(.qmDescListening)
        case .speaking:       return AL.s(.qmDescSpeaking)
        case .fillInTheBlank:  return AL.s(.qmDescFillBlank)
        case .sentenceBuilder: return AL.s(.qmDescSentenceBuilder)
        case .introduce:       return AL.s(.qmDescIntroduce)
        case .translateSentence: return AL.s(.qmDescTranslateSentence)
        case .buildSentence:   return AL.s(.qmDescBuildSentence)
        case .matchPairs:      return AL.s(.qmDescMatchPairs)
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
        case .introduce, .buildSentence: return 1
        case .translateSentence: return 1
        case .matchPairs:      return 3
        }
    }
}
