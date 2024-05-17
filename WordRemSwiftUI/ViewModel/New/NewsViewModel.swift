//
//  NewsViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import Foundation


final class NewsViewModel: ObservableObject {
    @Published var newsModel:NewsModel?
    @Published var isLoading = false
    
    func getNews() {
        URLSessionApiService.shared.getNews { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
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
