//
//  FirebaseService + Ext.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.04.2024.
//

import Foundation
import Firebase

extension FirebaseService {
    
    func deleteCard(withId cardId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let documentRef = Firestore.firestore().collection("users").document(uid).collection("cards").document(cardId)
        
        do {
            try await documentRef.delete()
        } catch {
            print("Error deleting document: \(error.localizedDescription)")
            throw error
        }
    }
}

