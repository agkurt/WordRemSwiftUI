//
//  MotherTongueViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.04.2024.
//

import Foundation

class MotherTongueViewModel: ObservableObject {
    
    @Published var motherTongue:Language = .turkish
    @Published var isSuccess = false
    
    func addMotherTongue(motherTongue:String) async {
        do {
            try await FirebaseService.shared.addMotherTongueLanguage(motherTongue: motherTongue)
            OperationQueue.main.addOperation {
                self.isSuccess = true
            }
        }catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
}
