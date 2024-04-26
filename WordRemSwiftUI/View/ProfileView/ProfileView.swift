//
//  ProfileView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.04.2024.
//

import SwiftUI

struct ProfileView: View {
    
    @StateObject var profileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    LineView()
                    Picker("Language", selection: $profileViewModel.motherTongue) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    
                    Button(action: {
                      
                    }, label: {
                        Text("Change")
                    })
                    .buttonStyle(BorderedButtonStyle())
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button(action: {
                        
                    }, label: {
                        Text("x")
                    })
                }
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
        }
    }
}

#Preview {
    ProfileView(profileViewModel: ProfileViewModel())
}
