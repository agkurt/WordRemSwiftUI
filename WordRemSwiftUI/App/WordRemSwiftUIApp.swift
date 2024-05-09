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
    
    @StateObject private var sentenceViewModel = SentenceViewModel()
    @StateObject private var authManager = AuthManager()
    
    init () {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(sentenceViewModel: sentenceViewModel)
                .environmentObject(authManager)
                .environmentObject(sentenceViewModel)
        }
    }
}






