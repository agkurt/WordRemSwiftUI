//
//  AppDelegate.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 1.03.2024.
//

import SwiftUI
import GoogleSignIn
import Firebase

class AppDelegate: UIResponder,UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("launc is starting")
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    
}

