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
    
    func fetchAllCardInfoForGame(deckId:String) async throws -> [WordGameCardModel] {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return []
        }
        var wordGameModel: [WordGameCardModel] = []
        
        do {
            let querySnapshot = try await Firestore.firestore().collection("users").document(uid).collection("cards").document(deckId).collection("words").getDocuments()
            for document in querySnapshot.documents {
                if let words = document.data()["wordName"] as? String,
                   let means = document.data()["wordMean"] as? String,
                   let sentences = document.data()["wordDescription"] as? String {
                    let gameModel = WordGameCardModel(id: document.documentID, words: words, means: means, sentences: sentences)
                    wordGameModel.append(gameModel)
                }
            }
        }catch {
            throw error
        }
        return wordGameModel
    }
}

