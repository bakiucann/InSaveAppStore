//
//  InstagramService.swift
//  InstaSaver
//
//  Created by Baki Uçan on 27.04.2025.
//

import Foundation

enum InstagramServiceError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(String)
    case unknownError
}

class InstagramService {
    static let shared = InstagramService()
    static let baseURL = "https://instagram-apis.vercel.app/api/video"
    
    private func performRequest<T: Codable>(
        with urlString: String,
        method: String = "POST",
        body: Data?,
        responseType: T.Type,
        completion: @escaping (Result<T, InstagramServiceError>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15 // 15 saniye zaman aşımı
        if let body = body {
            request.httpBody = body
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as? URLError, error.code == .timedOut {
                print("Request timed out")
                completion(.failure(.serverError("İstek zaman aşımına uğradı. Lütfen tekrar deneyin.")))
                return
            }
            
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(.failure(.noData))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                
                // Önce hata yanıtını kontrol et
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    completion(.failure(.serverError(errorResponse.error.error)))
                    return
                }
                
                // Hata yoksa normal yanıtı decode et
                let decodedResponse = try decoder.decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        print("Missing key: \(key)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type) for key \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: expected \(type) for key \(context.codingPath)")
                    default:
                        print("Other decoding error: \(decodingError)")
                    }
                }
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    func fetchReelInfo(
        url: String,
        quality: Int? = nil,
        completion: @escaping (Result<InstagramAPIResponse, InstagramServiceError>) -> Void
    ) {
        let endpoint = InstagramService.baseURL
        var requestBody: [String: Any] = ["url": url]
        if let quality = quality {
            requestBody["quality"] = quality
        }
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(.failure(.invalidURL)) // Alternatif bir hata kullanabilirsiniz
            return
        }
        
        performRequest(
            with: endpoint,
            method: "POST",
            body: bodyData,
            responseType: InstagramAPIResponse.self
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension InstagramServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("You have entered an invalid URL. Please check the URL and try again.", comment: "")
        case .noData:
            return NSLocalizedString("No data was received from the server. Please try again later.", comment: "")
        case .decodingError:
            return NSLocalizedString("There was an error processing the data. Please try again.", comment: "")
        case .networkError(let error):
            if let urlError = error as? URLError, urlError.code == .timedOut {
                return NSLocalizedString("The request timed out. Please check your internet connection and try again.", comment: "")
            }
            return NSLocalizedString("A network error occurred. Please check your internet connection and try again.", comment: "")
        case .serverError(let message):
            return NSLocalizedString(message, comment: "")
        case .unknownError:
            return NSLocalizedString("An unknown error occurred. Please try again.", comment: "")
        }
    }
}
