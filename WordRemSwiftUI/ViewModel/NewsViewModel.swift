//
//  NewsViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import Foundation

class NewsViewModel: ObservableObject {
    @Published var newsModel:NewsModel?
    
    func getNews() {
        URLSessionApiService.shared.getNews { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let news):
                    self.newsModel = news
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}
