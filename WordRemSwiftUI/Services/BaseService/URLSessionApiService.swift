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
    
    func getTranslate(text: String, targetLang: String,sourceLang:String, completion: @escaping (Result<TranslationResponse, Error>) -> Void) {
        
        let apiKey = "58305ba3-80b3-43fb-83fe-4358876f4b2e:fx"
        let baseURL = "https://api-free.deepl.com/v2"
        
        
        guard let url = URL(string: "\(baseURL)/translate") else {
            return
        }
        
        let parameters: [String: Any] = [
            "text": [text],
            "target_lang": targetLang
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            do {
                let translationResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
                completion(.success(translationResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

