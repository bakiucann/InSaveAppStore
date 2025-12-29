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
    
    // Custom URLSession with optimized timeout configuration
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60 // 60 seconds
        configuration.timeoutIntervalForResource = 300 // 300 seconds (5 minutes)
        return URLSession(configuration: configuration)
    }()
    
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
        // Timeout is handled by URLSessionConfiguration
        if let body = body {
            request.httpBody = body
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        session.dataTask(with: request) { data, response, error in
            // Handle network errors first
            if let error = error {
                if let urlError = error as? URLError {
                    print("Network error: \(urlError.localizedDescription) (code: \(urlError.code.rawValue))")
                    // Timeout and connection lost will be retried by fetchWithRetry
                    completion(.failure(.networkError(error)))
                    return
                } else {
                    print("Network error: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.serverError("Invalid server response")))
                return
            }
            
            // 5xx errors: Retryable server errors
            if self.isServerError(statusCode: httpResponse.statusCode) {
                print("⚠️ HTTP \(httpResponse.statusCode) Server Error - Will retry if retry count allows")
                
                // Try to decode error message from response body if available
                // API may return: { error: "message" } or { error: { error: "message" } }
                if let data = data {
                    // First try: Standard APIErrorResponse format
                    if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        print("⚠️ API Error (structured): \(errorResponse.error.error)")
                        completion(.failure(.serverError(errorResponse.error.error)))
                        return
                    }
                    
                    // Second try: Simple error format { error: "message", message: "..." }
                    if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorDict["error"] as? String ?? errorDict["message"] as? String {
                        print("⚠️ API Error (simple): \(errorMessage)")
                        completion(.failure(.serverError(errorMessage)))
                        return
                    }
                    
                    // Third try: Plain text error
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("⚠️ API Error Response (text): \(errorString)")
                    }
                }
                
                // Generic 5xx error (will be mapped to "error_private_or_server" in ViewModels)
                // Note: All 5xx errors indicate server issues, which often means private account or service unavailable
                completion(.failure(.serverError("Server error \(httpResponse.statusCode). All services failed.")))
                return
            }
            
            // 4xx errors: Do NOT retry, return immediately
            if (400...499).contains(httpResponse.statusCode) {
                let statusCode = httpResponse.statusCode
                print("❌ HTTP \(statusCode) Error - No retry for 4xx errors")
                
                // Try to decode error message if available
                // Note: All 4xx errors will be mapped to "error_private_or_server" in ViewModels
                if let data = data,
                   let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    completion(.failure(.serverError(errorResponse.error.error)))
                } else {
                    // Generic 4xx error message (will be mapped in ViewModels)
                    let errorMessage = "Server returned error code \(statusCode)"
                    completion(.failure(.serverError(errorMessage)))
                }
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
    
    // Simplified retry logic: Max 1 retry (total 2 attempts)
    // Retry ONLY for: Timeout, NetworkConnectionLost, or 5xx server errors
    // Do NOT retry for 4xx errors
    private func fetchWithRetry<T: Codable>(
        urlString: String,
        method: String = "POST",
        body: Data?,
        responseType: T.Type,
        currentRetryCount: Int = 0,
        maxRetryCount: Int = 1, // Strictly 1 retry (total 2 attempts)
        completion: @escaping (Result<T, InstagramServiceError>) -> Void
    ) {
        performRequest(with: urlString, method: method, body: body, responseType: responseType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // Success: return immediately
                completion(.success(response))
                
            case .failure(let error):
                // Check if we should retry
                let shouldRetry = self.shouldRetry(error: error, retryCount: currentRetryCount, maxRetryCount: maxRetryCount)
                
                if shouldRetry {
                    let retryDelay: TimeInterval = 2.0 // Fixed 2 second delay
                    print("🔄 Retryable error detected, retrying in \(retryDelay) seconds (attempt \(currentRetryCount + 1)/\(maxRetryCount + 1))...")
                    
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
                } else {
                    // Don't retry: return error immediately
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Determine if error is retryable
    private func shouldRetry(error: InstagramServiceError, retryCount: Int, maxRetryCount: Int) -> Bool {
        // Don't retry if we've exceeded max retries
        guard retryCount < maxRetryCount else {
            return false
        }
        
        switch error {
        case .networkError(let networkError):
            // Retry for timeout and connection lost errors
            if let urlError = networkError as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost:
                    return true
                default:
                    return false
                }
            }
            return false
            
        case .serverError(let message):
            // Check if message indicates a 5xx error (we set this in performRequest)
            if message.contains("Server error") && message.contains("Will retry") {
                return true
            }
            // All other server errors (4xx, etc.) - don't retry
            return false
            
        case .noData:
            // No data might be a server issue, but we don't retry to avoid infinite loops
            return false
            
        default:
            // Invalid URL, decoding errors, etc. - don't retry
            return false
        }
    }
    
    // Helper to check if HTTP response is 5xx
    private func isServerError(statusCode: Int) -> Bool {
        return (500...599).contains(statusCode)
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
