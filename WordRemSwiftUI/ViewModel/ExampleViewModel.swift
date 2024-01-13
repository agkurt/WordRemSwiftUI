//
//  ExampleViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 13.01.2024.
//

import Foundation

class ExampleViewModel: ObservableObject {
    
    @Published var example :[Example] = []
    
    let exampleApiService : ExampleApiService
    
    init(exampleApiService: ExampleApiService) {
        self.exampleApiService = exampleApiService
    }
    
    func fetchExample() {
        exampleApiService.getRequest { result in
            switch result {
            case .success(let example):
                DispatchQueue.main.async {
                    self.example = example
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
