//
//  ExampleApiService.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.01.2024.
//

import Foundation

class ExampleApiService {
    
    let apiService : ApiServiceProtocol
    
    init(apiService: ApiServiceProtocol) {
        self.apiService = apiService
    }
   
     
    func getRequest(completion: @escaping (Result<[Example],Error>) ->Void) {
        
        
        
    }
}
