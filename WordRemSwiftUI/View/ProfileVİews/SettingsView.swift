//
//  SettingsView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var authManager: AuthManager
    
    let settings: Array<Setting> = [
        Setting(title: "Theme", color: .red, imageName: "heart.square.fill"),
        Setting(title: "User Settings", color: .red, imageName: "person.crop.circle")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                List {
                    ForEach(settings, id: \.self) { setting in
                        NavigationLink(destination: RootSettingView(viewToDisplay: setting.title).navigationBarTitleDisplayMode(.inline)) {
                            HStack {
                                SettingImage(color: setting.color, imageName: setting.imageName)
                                Text(setting.title)
                            }
                        }
                    }
                }
              
            }
            .navigationTitle("Settings")
        }
    }
}
