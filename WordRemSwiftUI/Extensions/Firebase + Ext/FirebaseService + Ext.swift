//
//  FirebaseService + Ext.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.04.2024.
//

import Foundation
import Firebase

extension FirebaseService {

    // Supabase kullanıcı kimliği — Firebase Auth yerine Supabase Auth
    private var supabaseUid: String? {
        SupabaseService.shared.currentUserId?.uuidString
    }

    // MARK: - Delete Deck (with all its words)
    func deleteCardAndTransactions(withId cardId: String) async throws {
        guard let uid = supabaseUid else { return }

        let cardRef = Firestore.firestore().collection("users").document(uid).collection("cards").document(cardId)
        let wordsRef = cardRef.collection("words")

        let words = try await wordsRef.getDocuments()

        for word in words.documents {
            try await word.reference.delete()
        }

        do {
            try await cardRef.delete()
        } catch {
            print("Error deleting document: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Delete Single Word from a Deck
    func deleteCardInfoAndTransactions(deckId: String, cardId: String) async throws {
        guard let uid = supabaseUid else { return }

        let cardRef = Firestore.firestore().collection("users").document(uid).collection("cards").document(deckId)
        let wordRef = cardRef.collection("words").document(cardId)

        do {
            try await wordRef.delete()
        } catch {
            print("Error deleting document: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Quiz Results
    func saveQuizResult(cardId: String, mode: String, score: Int, total: Int) async throws {
        guard let uid = supabaseUid else {
            throw NSError(domain: "FirebaseService", code: -1)
        }
        let db = Firestore.firestore()
        _ = try await db.collection("users")
            .document(uid)
            .collection("cards")
            .document(cardId)
            .collection("quizResults")
            .addDocument(data: [
                "mode": mode,
                "score": score,
                "total": total,
                "date": Timestamp(date: Date())
            ])
        print("✅ [FirebaseService] Quiz result saved — \(score)/\(total) [\(mode)]")
    }

    func fetchQuizResults(cardId: String) async throws -> [[String: Any]] {
        guard let uid = supabaseUid else { return [] }
        let db = Firestore.firestore()
        var results: [[String: Any]] = []
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("cards")
            .document(cardId)
            .collection("quizResults")
            .order(by: "date", descending: true)
            .getDocuments()

        for doc in snapshot.documents {
            var data = doc.data()
            data["id"] = doc.documentID
            data["cardId"] = cardId
            results.append(data)
        }
        return results
    }
}
