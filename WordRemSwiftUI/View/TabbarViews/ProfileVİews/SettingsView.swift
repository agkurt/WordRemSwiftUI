//
//  SettingsView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var viewModel : SettingsViewModel
    
    let settings: Array<Setting> = [
        Setting(title: "", color: .red, imageName: "heart.square.fill"),
        Setting(title: "widget", color: .yellow, imageName: "star.square.fill"),
        Setting(title: "some other setting", color: .green, imageName: "location.square.fill"),
        Setting(title: "another setting", color: .gray, imageName: "bookmark.square.fill")
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
                NavigationLink(destination: LoginScreenView()) {
                    Button(action: {
                        viewModel.signOut()
                    }, label: {
                        Text("Log out")
                    })
                }
                
            }
            .navigationTitle("Settings")
        }
    }
}
