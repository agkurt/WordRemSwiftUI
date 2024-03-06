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
    let result: [ResultElement]
}

enum ResultElement: Codable,Hashable {
    case resultClass(ResultClass)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(ResultClass.self) {
            self = .resultClass(x)
            return
        }
        throw DecodingError.typeMismatch(ResultElement.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ResultElement"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .resultClass(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }
    }
}

// MARK: - ResultClass
struct ResultClass: Codable,Hashable {
    let key: String
    let url: String
    let description: String
    let image: String
    let name, source: String
}


