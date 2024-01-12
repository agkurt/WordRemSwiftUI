//
//  UrlSessionApiService.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.01.2024.
//

import Foundation

class UrlSessionApiService: ApiServiceProtocol {
    
    static let shared = UrlSessionApiService()
    
    private init() { }
    
    func getRequest<T:Codable>(completion: @escaping (Result<T, Error>) -> Void) {
        
        let headers = [
            "X-RapidAPI-Key": "30c9e7ec39msheded83facd06704p1ef228jsnf8acccb45fa8",
            "X-RapidAPI-Host": "wordsapiv1.p.rapidapi.com"
        ]
        
        let word: String
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://wordsapiv1.p.rapidapi.com/words/word/examples")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if (error != nil) {
                print(error as Any)
            }else {
                let httpResponse = response as? HTTPURLResponse
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "Not found data", code: 0,userInfo: nil)))
                return
            }
            
            do {
                let decodeData = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodeData))
            }catch {
                completion(.failure(error))
            }
        }.resume()
        
    }
}



