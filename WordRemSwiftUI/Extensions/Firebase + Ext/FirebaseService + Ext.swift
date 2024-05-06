//
//  FirebaseService + Ext.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.04.2024.
//

import Foundation
import Firebase

extension FirebaseService {
    
    func deleteCardAndTransactions(withId cardId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
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
}


