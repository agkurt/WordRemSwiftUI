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

class FirebaseService:ObservableObject {
    
    static let shared = FirebaseService()
    
    private init() { }
    
    func registerUser(userRequest:RegisterModel,completion: @escaping (Bool,Error?) -> Void) {
       
        let username = userRequest.username
        let email = userRequest.email
        let password = userRequest.password
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            print(password.count)
            if let error = error {
                completion(false,error)
                return
            }
            
            guard let result = result?.user else {
                completion(false,nil)
                return
            }
            
            let db = Firestore.firestore()
            
            db.collection("users")
                .document(result.uid)
                .setData([
                    "username":username,
                    "email":email,
                    "password":password
                ]) { error in
                    if let error = error {
                        completion(false,error)
                        return
                    }
                    completion(true,nil)
                }
        }
    }
}
