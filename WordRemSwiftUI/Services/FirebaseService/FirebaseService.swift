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
        
        print("Before createUser - Password Count: \(password.count), Email Count: \(email.count)")

        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            print("Inside createUser - Password Count: \(password.count), Email Count: \(email.count)")
            
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let user = authResult?.user else {
                completion(false, nil)
                return
            }
            guard password.count >= 6, email.count > 0 else {
                completion(false, NSError(domain: "FirebaseService", code: 1, userInfo: ["description": "Invalid password or email length."]))
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
}

