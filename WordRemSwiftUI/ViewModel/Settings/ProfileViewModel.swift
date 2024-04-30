//
//  ProfileViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.04.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import FirebaseStorage

class ProfileViewModel: ObservableObject {
    
    @Published var username: [String] = []
    @Published var email: [String] = []
    @Published var imageURL: URL?
    
    func fetchUsernameInfo() async {
        do {
            let fetch = try await FirebaseService.shared.fetchUsernameAndEmailInfo()
            OperationQueue.main.addOperation {
                self.username = fetch.map { $0.username}
                self.email = fetch.map {$0.email}
            }
        }catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    func uploadPhoto(image: UIImage) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageData = image.jpegData(compressionQuality: 0.8)
        
        guard let data = imageData else {
            return
        }
        
        let imageName = "\(UUID().uuidString).jpg"
        let imageRef = storageRef.child("profileImages/\(uid)/\(imageName)")
        
        imageRef.putData(data, metadata: nil) { metaData, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("Download URL is nil")
                    return
                }
                
                self.imageURL = downloadURL
                
                let db = Firestore.firestore()
                db.collection("profileImages").document(uid).collection("image").addDocument(data: ["profileImageURL":downloadURL.absoluteString])
                
            }
        }
    }
    
   
}
