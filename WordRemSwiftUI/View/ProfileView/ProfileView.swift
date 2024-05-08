//
//  ProfileView.swift
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

struct ProfileView: View {
    
    @StateObject var profileViewModel = ProfileViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                                        
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Çıkış Yap")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 220, height: 60)
                            .background(Color.red)
                            .cornerRadius(15.0)
                    }
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            
            .onAppear {
                Task {
                    await profileViewModel.fetchUsernameInfo()
                    
                }
            }
        }
    }
    
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(profileViewModel: ProfileViewModel())
    }
}
