//
//  NewsModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import Foundation

// MARK: - NewsModel
struct NewsModel: Codable,Hashable {
    let success: Bool
    let result: [ResultClass]
}

// MARK: - Result
struct ResultClass: Codable,Hashable {
    let key, url, description, image: String
    let name, source: String
}



