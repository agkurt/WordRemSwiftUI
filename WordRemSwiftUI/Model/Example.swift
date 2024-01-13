//
//  Example.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.01.2024.
//


import Foundation

// MARK: - Example
struct Example: Codable, Identifiable {
    var id: Int
    let word: String
    let pronunciation: Pronunciation
}

// MARK: - Pronunciation
struct Pronunciation: Codable {
    let all: String
}

