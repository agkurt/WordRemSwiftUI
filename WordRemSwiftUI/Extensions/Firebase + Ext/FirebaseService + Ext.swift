//
//  FirebaseService + Ext.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.04.2024.
//

import Foundation
import Firebase

extension FirebaseService {
    
    func deleteCards() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let collectionRef = Firestore.firestore().collection("users").document(uid).collection("cards")
        let documents = try await collectionRef.getDocuments()
        
        for document in documents.documents {
            do {
                try await collectionRef.document(document.documentID).delete()
            } catch {
                print("Error deleting document: \(error.localizedDescription)")
            }
        }
    }
}
