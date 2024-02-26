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

class FirebaseService: ObservableObject {
    
    static let shared = FirebaseService()
    
    private init() { }
    
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
    
    func addCardName(cardName:String) async {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).collection("cardNames").addDocument(data: ["cardName" : cardName])
            
        }catch {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
    
    func fetchCardName() async -> [String] {
            
        guard let uid = Auth.auth().currentUser?.uid else {
            return []
        }
        
        let db = Firestore.firestore()
        var cardNames: [String] = []

        do {
            let querySnapshot = try await db.collection("users").document(uid).collection("cardNames").getDocuments()
            for document in querySnapshot.documents {
                if let cardName = document.data()["cardName"] as? String {
                    cardNames.append(cardName)
                }
            }
        } catch {
            print("Error getting documents: \(error)")
        }
        
        return cardNames
    }

}
