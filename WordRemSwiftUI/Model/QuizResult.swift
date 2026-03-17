//
//  QuizResult.swift
//  WordRemSwiftUI
//

import Foundation

struct QuizResult: Identifiable {
    var id: String = UUID().uuidString
    let cardId: String
    let mode: String
    let score: Int
    let total: Int
    let date: Date

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(score) / Double(total) * 100
    }

    var grade: String {
        switch percentage {
        case 90...:   return "🏆 Excellent!"
        case 70..<90: return "🎯 Great!"
        case 50..<70: return "📚 Keep Going!"
        default:      return "💪 Practice More!"
        }
    }
}

/// Tracks per-question outcome for result review
struct QuizAnswerRecord: Identifiable {
    let id = UUID()
    let question: QuizQuestion
    let userAnswer: String
    let isCorrect: Bool
}
