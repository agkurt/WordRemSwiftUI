//
//  MotherTongueViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.04.2024.
//

import Foundation

final class MotherTongueViewModel: ObservableObject {
    
    @Published var motherTongue:Language = .french
    @Published var isSuccess = false
    
    func addMotherTongue(motherTongue:String) async {
        do {
            try await FirebaseService.shared.addMotherTongueLanguage(motherTongue: motherTongue)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isSuccess = true
            }
        }catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
}
