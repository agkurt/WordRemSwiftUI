//
//  APIKey.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 15.03.2024.
//

import Foundation

enum APIKey {

    static var geminiApi: String {
        guard let filePath = Bundle.main.path(forResource: "ApiKey-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'ApiKey-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "GeminiApi") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'ApiKey-Info.plist'.")
        }
        if value.starts(with: "_") || value.isEmpty {
            fatalError(
                ""
            )
        }
        return value
    }
    
    static var wordsApi: String {
        guard let filePath = Bundle.main.path(forResource: "ApiKey-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'ApiKey-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "WordsApi") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'ApiKey-Info.plist'.")
        }
        if value.starts(with: "_") || value.isEmpty {
            fatalError(
                ""
            )
        }
        return value
    }
    
    static var newsApi: String {
        guard let filePath = Bundle.main.path(forResource: "ApiKey-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'ApiKey-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "NewsApi") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'ApiKey-Info.plist'.")
        }
        if value.starts(with: "_") || value.isEmpty {
            fatalError(
                ""
            )
        }
        return value
    }
    
    static var translateApi: String {
        guard let filePath = Bundle.main.path(forResource: "ApiKey-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'GenerativeAI-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "TranslateApi") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'ApiKey-Info.plist'.")
        }
        if value.starts(with: "_") || value.isEmpty {
            fatalError(
                "Follow the instructions at https://ai.google.dev/tutorials/setup to get an API key."
            )
        }
        return value
    }
}

