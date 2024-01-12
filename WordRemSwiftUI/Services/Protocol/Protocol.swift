//
//  Protocol.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.01.2024.
//

import Foundation

// MARK: - CREATE GENERIC PROTOCOL
protocol ApiServiceProtocol {
    func getRequest<T:Codable>(completion: @escaping (Result<T,Error>)-> Void)
        
}
