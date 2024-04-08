//
//  FirebaseService.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn

class FirebaseService: ObservableObject {
    
    static let shared = FirebaseService()
    
    private init() {
        
    }
    
    func registerUser(userRequest: RegisterModel, completion: @escaping (Bool, Error?) -> Void) {
        
        let username = userRequest.username
        let email = userRequest.email
        let password = userRequest.password
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let user = authResult?.user else {
                completion(false, nil)
                return
            }
            
            let db = Firestore.firestore()
            
            db.collection("users")
                .document(user.uid)
                .setData([
                    "username": username,
                    "email": email
                ]) { error in
                    if let error = error {
                        completion(false, error)
                        return
                    }
                    completion(true, nil)
                }
        }
    }
    
    func loginUser(loginModel:LoginModel,completion: @escaping (Bool,Error?)->Void) {
        
        let email = loginModel.email
        let password = loginModel.password
        
        Auth.auth().signIn(withEmail:email, password: password) { result, error in
            
            if let error = error {
                completion(false,error)
                return
            }
            
            guard let user = result?.user else {
                completion(false, nil)
                return
            }
            
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.uid)
            
            userRef.updateData(["lastLogin": FieldValue.serverTimestamp()]) { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func addCardName(name:String) async  {
            guard let uid = Auth.auth().currentUser?.uid else {
                return
            }
            
            do {
                _ = try await Firestore.firestore().collection("users").document(uid).collection("cards").addDocument(data: ["cardName" : name])
                
            }catch {
                print("Error fetching data: \(error.localizedDescription)")
            }
        }
    
    func fetchCardName() async -> ([String], [String]) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return ([], [])
        }
        
        let db = Firestore.firestore()
        var cardNames: [String] = []
        var cardIds: [String] = []
        
        do {
            let querySnapshot = try await db.collection("users").document(uid).collection("cards").getDocuments()
            for document in querySnapshot.documents {
                if let cardName = document.data()["cardName"] as? String {
                    cardNames.append(cardName)
                    cardIds.append(document.documentID)
                }
                
            }
        } catch {
            print("Error getting documents: \(error)")
        }
        
        return (cardNames, cardIds)
    }

    
    func addWordToCard(cardId: String, wordName: String, wordMean: String, wordDescription: String) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let db = Firestore.firestore()
        
        _ = try await db.collection("users").document(uid).collection("cards").document(cardId).collection("words").addDocument(data: [
            "wordName": wordName,
            "wordMean": wordMean,
            "wordDescription": wordDescription
        ])
    }
    
    func fetchTheCardNameInfo(cardId: String) async -> WordInfo {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            fatalError("")
        }
        
        var wordInfo = WordInfo(names: [], means: [], descriptions: [])

        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("users").document(uid).collection("cards").document(cardId).collection("words").getDocuments()
            
            for document in querySnapshot.documents {
                   if let wordName = document.data()["wordName"] as? String,
                      let wordMean = document.data()["wordMean"] as? String,
                      let wordDescription = document.data()["wordDescription"] as? String {
                       wordInfo.names.append(wordName)
                       wordInfo.means.append(wordMean)
                       wordInfo.descriptions.append(wordDescription)
                   }
               }
        } catch {
            print("Error getting documents: \(error)")
        }
        return wordInfo
    }
  
}
