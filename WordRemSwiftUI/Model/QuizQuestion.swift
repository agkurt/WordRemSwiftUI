//
//  QuizQuestion.swift
//  WordRemSwiftUI
//

import Foundation

struct QuizQuestion: Identifiable {
    let id = UUID()
    let wordInfo: WordInfo
    let mode: QuizMode

    // Multiple Choice
    let options: [String]       // 4 shuffled options (means)
    let correctAnswer: String   // correct wordMean

    // True / False
    let displayedMeaning: String // shown meaning (may be fake)
    let isCorrectPair: Bool      // whether wordInfo.means == displayedMeaning
}
