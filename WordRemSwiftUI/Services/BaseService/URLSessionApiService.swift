//
//  URLSessionApiService.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import Foundation
import GoogleGenerativeAI

class URLSessionApiService {
    
    static let shared = URLSessionApiService()
    
    private init() { }
    
    
    func getWords(word: String, completion: @escaping (Result<ExampleWord, Error>) -> Void) {
        
        let headers = [
            "X-RapidAPI-Key": APIKey.wordsApi,
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
        
        let apiKey = APIKey.translateApi
        let baseURL = "https://api-free.deepl.com/v2"
        
        
        guard let url = URL(string: "\(baseURL)/translate") else {
            return
        }
        
        let parameters: [String: Any] = [
            "text": [text],
            "target_lang": targetLang,
            "source_lang": sourceLang
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
    
    
    func getNews(completion: @escaping (Result<NewsModel,Error>)->Void) {
        
        let headers = [
            "content-type": "application/json",
            "authorization": "apikey \(APIKey.newsApi)"
        ]
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.collectapi.com/news/getNews?country=en&tag=general")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        URLSession.shared.dataTask(with: request as URLRequest) { data,response,error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(error!))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(NewsModel.self, from: data)
                completion(.success(decodedData))
            }catch {
                completion(.failure(error))
            }
            
        }
        .resume()
    }
    
    func geminiApi(userPrompt:String) async -> AIMessage? {
        let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.geminiApi)
        let prompt = userPrompt
        do {
            let response = try await model.generateContent(prompt)
            if let modelAnswer = response.text {
                print(modelAnswer)
                return AIMessage(sender: .assistant, content: modelAnswer)
            }
        }catch {
            print(error)
        }
        return nil
    }
    
}
