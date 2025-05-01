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
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.serverError("Invalid server response")))
                return
            }
            
            // HTTP durum kodunu kontrol et
            if httpResponse.statusCode == 403 {
                print("403 Forbidden Error")
                completion(.failure(.serverError("You don't have permission to access this content. The account might be private or the content has been removed.")))
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
    
    // İsteğin yeniden denenmesi için
    private func fetchWithRetry<T: Codable>(
        urlString: String,
        method: String = "POST",
        body: Data?,
        responseType: T.Type,
        currentRetryCount: Int = 0,
        maxRetryCount: Int = 3,
        completion: @escaping (Result<T, InstagramServiceError>) -> Void
    ) {
        let retryDelay: TimeInterval = pow(2.0, Double(currentRetryCount)) // Exponential backoff: 1, 2, 4 saniye
        
        performRequest(with: urlString, method: method, body: body, responseType: responseType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // Başarılı sonuç, direkt döndür
                completion(.success(response))
                
            case .failure(let error):
                // 403 hatası alındı ve maksimum deneme sayısına ulaşılmadıysa yeniden dene
                if case .serverError(let message) = error, message.contains("403") || message.contains("permission") {
                    if currentRetryCount < maxRetryCount {
                        print("🔄 403 hatası alındı, \(retryDelay) saniye sonra tekrar deneniyor (\(currentRetryCount + 1)/\(maxRetryCount))...")
                        
                        // Gecikme süresi ile tekrar dene
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            self.fetchWithRetry(
                                urlString: urlString,
                                method: method,
                                body: body,
                                responseType: responseType,
                                currentRetryCount: currentRetryCount + 1,
                                maxRetryCount: maxRetryCount,
                                completion: completion
                            )
                        }
                        return
                    }
                }
                
                // Diğer tüm hatalar veya maksimum deneme sayısı aşıldıysa hatayı döndür
                completion(.failure(error))
            }
        }
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
        
        // Retry mekanizması ile isteği gönder
        fetchWithRetry(
            urlString: endpoint,
            method: "POST",
            body: bodyData,
            responseType: InstagramAPIResponse.self,
            completion: completion
        )
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
