//
//  FirebaseService.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

class FirebaseService: ObservableObject {
    
    static let shared = FirebaseService()
    
    private init() {
        
    }
    
    /// Returns the current authenticated user's UID (Supabase), or nil if not logged in.
    func currentUserUID() -> String? {
        return SupabaseAuthService.shared.currentUserId?.uuidString
    }
    
    func addCardNameInfo(name:String,selectedFlag:FlagModel,sourceLang:String,targetLang:String) async {
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            return
        }
        let flagString = selectedFlag.rawValue
        let creationDate = Timestamp(date: Date())
        
        do {
            _ = try await Firestore.firestore().collection("users").document(uid).collection("cards").addDocument(data: ["cardName" : name,"selectedFlag":flagString,"targetLang":targetLang,"sourceLang":sourceLang,"creationData":creationDate])
        }catch {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
    
    func fetchCardName() async throws -> [Card] {
        
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            return []
        }
        
        let db = Firestore.firestore()
        var cards: [Card] = []
        
        do {
            let querySnapshot = try await db.collection("users").document(uid).collection("cards").order(by: "creationData",descending: true).getDocuments()
            for document in querySnapshot.documents {
                if let cardName = document.data()["cardName"] as? String,
                   let flagString = document.data()["selectedFlag"] as? String,
                   let flag = FlagModel(rawValue: flagString) {
                    let card = Card(id: document.documentID, name: cardName, selectedFlag: flag)
                    cards.append(card)
                }
            }
        } catch {
            throw error
        }
        
        return cards
    }

    
    func fetchTheCardNameInfo(cardId: String) async throws -> [WordInfo] {
        
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            return []
        }
        
        var wordInfos: [WordInfo] = []
        
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("users").document(uid).collection("cards").document(cardId).collection("words").order(by: "creationDate",descending: true).getDocuments()
            for document in querySnapshot.documents {
                if let wordName = document.data()["wordName"] as? String,
                   let wordMean = document.data()["wordMean"] as? String,
                   let wordDescription = document.data()["wordDescription"] as? String {
                    let wordInfo = WordInfo(id: document.documentID, names: wordName, means: wordMean, descriptions: wordDescription)
                    wordInfos.append(wordInfo)
                }
            }
        } catch {
            print("Error getting documents: \(error)")
        }
        return wordInfos
    }
    
    func fetchUsernameAndEmailInfo() async throws -> [RegisterModel] {
        
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            return []
        }
        
        let db = Firestore.firestore()
        var registerModels: [RegisterModel] = []
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if let username = document.data()?["username"] as? String,
               let email = document.data()?["email"] as? String
            {
                let registerModel = RegisterModel(username: username, email: email)
                registerModels.append(registerModel)
            }
            
        } catch {
            print("Error getting documents: \(error)")
        }
        return registerModels
    }
    

    func fetchSourceAndTargetLang(cardId:String) async throws -> [Card] {
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            return []
        }
        
        let db = Firestore.firestore()
        var cards: [Card] = []
        
        do {
            let documentSnapshot = try await db.collection("users").document(uid).collection("cards").document(cardId).getDocument()
            if let sourceLang = documentSnapshot.data()?["sourceLang"] as? Language.RawValue,
               let targetLang = documentSnapshot.data()?["targetLang"] as? Language.RawValue {
                let card = Card(id: documentSnapshot.documentID, targetLang: targetLang, sourceLang: sourceLang)
                cards.append(card)
            }
        } catch {
            print("Error getting documents: \(error)")
        }
        
        return cards
    }
    
    func addMotherTongueLanguage(motherTongue:String) async throws {
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            throw NSError(domain: "", code: -1)
        }
        
        let db = Firestore.firestore()
        
        _ = try await db.collection("users").document(uid).collection("motherTongue").addDocument(data: ["motherTongue":motherTongue])
    }
    
    
    func addWordToCard(cardId: String, wordName: String, wordMean: String, wordDescription: String) async  {
        
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            return
        }
        
        let db = Firestore.firestore()
        let creationDate = Timestamp(date: Date())
        
        do {
            _ = try await db.collection("users").document(uid).collection("cards").document(cardId).collection("words").addDocument(data: [
                "wordName": wordName,
                "wordMean": wordMean,
                "wordDescription": wordDescription,
                "creationDate":creationDate
            ])
        }catch {
            print(error)
        }
    }
    
    func updateWordInCard(cardId: String, wordId: String, wordName: String, wordMean: String, wordDescription: String) async {
        guard let uid = SupabaseAuthService.shared.currentUserId?.uuidString else {
            return
        }
        
        let db = Firestore.firestore()
        
        do {
            try await db.collection("users").document(uid)
                .collection("cards").document(cardId)
                .collection("words").document(wordId)
                .updateData([
                    "wordName": wordName,
                    "wordMean": wordMean,
                    "wordDescription": wordDescription
                ])
        } catch {
            print("❌ Update error: \(error.localizedDescription)")
        }
    }
}

