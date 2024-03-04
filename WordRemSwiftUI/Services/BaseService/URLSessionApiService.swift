//
//  URLSessionApiService.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import Foundation

class URLSessionApiService {
    
    static let shared = URLSessionApiService()
    
    private init() { }
    
    func getWords(word: String, completion: @escaping (Result<ExampleWord, Error>) -> Void) {
        
        let headers = [
            "X-RapidAPI-Key": "30c9e7ec39msheded83facd06704p1ef228jsnf8acccb45fa8",
            "X-RapidAPI-Host": "wordsapiv1.p.rapidapi.com"
        ]
        
        guard var components = URLComponents(string: "https://wordsapiv1.p.rapidapi.com/words") else {
            completion(.failure(NSError(domain: "Not available url", code: 404, userInfo: nil)))
            return
        }
        
        components.path = "/words/\(word)/examples"
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Not available url", code: 404, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                completion(.failure(error))
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "Not found data", code: 404, userInfo: nil)))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(ExampleWord.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    func getTranslation(text: String, completion: @escaping (Result<TranslateModel, Error>) -> Void) {
        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("58305ba3-80b3-43fb-83fe-4358876f4b2e:fx", forHTTPHeaderField: "Authorization") // Replace with your actual API key
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try! JSONEncoder().encode(["text": text, "target_lang": "DE"])
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 204, userInfo: nil)))
                return
            }

            do {
                let decodedData = try JSONDecoder().decode(TranslateModel.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
