//
//  WordRemSwiftUIApp.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI
import Firebase

@main
struct WordRemSwiftUIApp: App {
    // Initialize Firebase in the initializer
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                RegisterScreenView()
            }
        }
    }
}

