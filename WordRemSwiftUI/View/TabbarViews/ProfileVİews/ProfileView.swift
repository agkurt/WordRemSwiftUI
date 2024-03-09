//
//  ProfileView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 5.03.2024.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var isDarkModeEnabled = false
    @State private var selectedLanguage = 1
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    IconImageView()
                        .frame(alignment:.center)
                    
                    VStack(alignment:.leading) {
                        Section(header: Text("Genel")
                            .font(.largeTitle)) {
                                Toggle(isOn: $isDarkModeEnabled) {
                                    Text("Karanlık Mod")
                                }
                                HStack(spacing:50) {
                                    Text("Dil")
                                        .font(.largeTitle)
                                    Picker("Dil", selection: $selectedLanguage) {
                                        Text("Türkçe").tag(1)
                                        Text("İngilizce").tag(2)
                                    }
                                }
                                Section(header: Text("Hesap")
                                    .font(.largeTitle)) {
                                        NavigationLink(destination: AccountSettingsView()) {
                                            HStack {
                                                Image(systemName: "person.circle")
                                                Text("Hesap Ayarları")
                                            }
                                        }
                                        .foregroundColor(.primary)
                                    }
                            }
                    }
                    Spacer()
                }
                .padding()
                .navigationTitle("Profil")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .ignoresSafeArea()
    }
}

struct AccountSettingsView: View {
    var body: some View {
        Text("Hesap Ayarları Sayfası")
    }
}

#Preview {
    ProfileView()
}



