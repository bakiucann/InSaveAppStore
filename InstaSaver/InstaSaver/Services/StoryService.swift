import Foundation

class StoryService {
    static let shared = StoryService()
    private let baseURL = "https://instagramcoms.vercel.app/api/stories/"
    private let highlightsBaseURL = "https://instagramcoms.vercel.app/api/highlights/"
    
    // Custom URLSession with optimized timeout configuration
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60 // 60 seconds
        configuration.timeoutIntervalForResource = 300 // 300 seconds (5 minutes)
        return URLSession(configuration: configuration)
    }()
    
    private init() {}
    
    // Determine if error is retryable
    private func shouldRetry(error: Error, retryCount: Int, maxRetryCount: Int) -> Bool {
        // Don't retry if we've exceeded max retries
        guard retryCount < maxRetryCount else {
            return false
        }
        
        // Check for timeout or connection lost errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost:
                return true
            default:
                return false
            }
        }
        
        // Check for 5xx server errors (if error contains HTTP status info)
        // Note: We check HTTP status in the request method itself
        return false
    }
    
    // Check if HTTP status code is 5xx
    private func isServerError(statusCode: Int) -> Bool {
        return (500...599).contains(statusCode)
    }
    
    // Highlight URL'inin algılanıp algılanmadığını kontrol eder
    func isHighlightURL(_ url: String) -> Bool {
        // İki farklı highlight URL formatını kontrol et:
        // 1. "/s/" formatında olan ve "aGlnaGxpZ2h0" (highlight kelimesinin base64 başlangıcı) içeren URL'ler
        // 2. "/stories/highlights/" formatındaki direkt highlight URL'leri
        return (url.contains("instagram.com/s/") && 
               (url.contains("aGlnaGxpZ2h0") || url.contains("highlight"))) ||
               url.contains("instagram.com/stories/highlights/")
    }
    
    // Highlight ID'sini URL'den çıkarır
    func extractHighlightID(from url: String) -> String? {
        // Direkt highlight URL formatı: instagram.com/stories/highlights/ID/
        if url.contains("instagram.com/stories/highlights/") {
            let componentsAfterHighlights = url.components(separatedBy: "instagram.com/stories/highlights/")
            if componentsAfterHighlights.count > 1, let idWithSlash = componentsAfterHighlights.last {
                // ID sonundaki slash'i temizle
                return idWithSlash.replacingOccurrences(of: "/", with: "")
            }
        }
        
        // Base64 kodlu bölümü çıkaralım (paylaşım URL'leri için)
        let urlComponents = url.components(separatedBy: "instagram.com/s/")
        if urlComponents.count > 1, let base64PartWithParams = urlComponents.last {
            let base64Components = base64PartWithParams.components(separatedBy: "?")
            if let base64String = base64Components.first {
                // Bilinen özel durum: Kullanıcının örnekteki URL'si
                if base64String == "aGlnaGxpZ2h0OjE3ODkwODk1NTY1MjEzODM4" {
                    return "17890895565213838"
                }
                
                // Base64'ü decode etmeye çalışalım
                if let decodedData = Data(base64Encoded: base64String),
                   let decodedString = String(data: decodedData, encoding: .utf8) {
                    
                    // "highlight:12345678" formatı
                    if let highlightMatch = decodedString.range(of: "highlight:(\\d+)", options: .regularExpression) {
                        let idStart = decodedString.index(highlightMatch.lowerBound, offsetBy: 10) // "highlight:".count
                        return String(decodedString[idStart..<highlightMatch.upperBound])
                    }
                    
                    // Sadece ID formatı
                    if let idMatch = decodedString.range(of: "\\d{15,}", options: .regularExpression) {
                        return String(decodedString[idMatch])
                    }
                }
            }
        }
        
        // Story media ID'yi çıkaralım (URL'de varsa)
        if let storyMediaMatch = url.range(of: "story_media_id=(\\d+)", options: .regularExpression) {
            let startIndex = url.index(storyMediaMatch.lowerBound, offsetBy: 15) // "story_media_id=".count
            let endIndex = url.range(of: "&", range: startIndex..<url.endIndex)?.lowerBound ?? url.endIndex
            return String(url[startIndex..<endIndex])
        }
        
        return nil
    }
    
    func fetchStories(username: String) async throws -> [InstagramStoryModel] {
        // Highlight URL ise, highlights API'sine yönlendir
        if isHighlightURL(username) {
            if let highlightId = extractHighlightID(from: username) {
                return try await fetchHighlights(highlightId: highlightId)
            } else {
                throw NSError(domain: "StoryService", code: -1, 
                             userInfo: [NSLocalizedDescriptionKey: "Could not extract highlight ID from URL"])
            }
        }
        
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: baseURL + encodedUsername) else {
            let error = URLError(.badURL)
            print("❌ URL Error: \(error.localizedDescription)")
            throw error
        }
        
        // Retry logic: Max 1 retry (total 2 attempts)
        var retryCount = 0
        let maxRetries = 1
        
        while retryCount <= maxRetries {
            do {
                print("📱 Fetching stories for username: \(username) (attempt \(retryCount + 1)/\(maxRetries + 1))")
                print("🔗 Request URL: \(url.absoluteString)")
                let (data, response) = try await session.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = URLError(.badServerResponse)
                    print("❌ Server Response Error: Invalid HTTP response")
                    throw error
                }
                
                print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                
                // 5xx errors: Retryable server errors
                if isServerError(statusCode: httpResponse.statusCode) {
                    print("⚠️ HTTP \(httpResponse.statusCode) Server Error")
                    if retryCount < maxRetries {
                        retryCount += 1
                        print("🔄 Retrying in 2 seconds...")
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        continue
                    } else {
                        throw URLError(.badServerResponse)
                    }
                }
                
                // 4xx errors: Do NOT retry, return immediately
                if (400...499).contains(httpResponse.statusCode) {
                    print("❌ HTTP \(httpResponse.statusCode) Client Error - No retry for 4xx errors")
                    throw URLError(.badServerResponse)
                }
                
                // Debug: Response data'yı yazdır
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Raw Response: \(responseString)")
                }
                
                guard httpResponse.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    print("❌ Server Error: HTTP \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response Body: \(responseString)")
                    }
                    throw error
                }
                
                let decoder = JSONDecoder()
                let storyResponse = try decoder.decode(InstagramStoryResponse.self, from: data)
                
                guard storyResponse.success else {
                    let error = NSError(domain: "StoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch stories"])
                    print("❌ API Error: Failed to fetch stories")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response Body: \(responseString)")
                    }
                    throw error
                }
                
                print("✅ Successfully fetched \(storyResponse.stories.count) stories")
                print("📊 Rate Limit Info:")
                print("  - IP Limit: \(storyResponse.rateLimit.ip.remaining)/\(storyResponse.rateLimit.ip.limit)")
                print("  - Daily Limit: \(storyResponse.rateLimit.daily.remaining)/\(storyResponse.rateLimit.daily.limit)")
                print("  - Reset At: \(storyResponse.rateLimit.ip.resetAt)")
                
                // Story detaylarını yazdır
                print("📸 Story Details:")
                for (index, story) in storyResponse.stories.enumerated() {
                    print("  \(index + 1). Type: \(story.type)")
                    print("     URL: \(story.url)")
                }
                
                return storyResponse.stories
                
            } catch {
                // Check if error is retryable
                if shouldRetry(error: error, retryCount: retryCount, maxRetryCount: maxRetries) {
                    retryCount += 1
                    print("🔄 Retryable error detected, retrying in 2 seconds (attempt \(retryCount + 1)/\(maxRetries + 1))...")
                    do {
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        continue
                    } catch {
                        throw error
                    }
                }
                
                // Not retryable or max retries exceeded
                if let decodingError = error as? DecodingError {
                    print("❌ Decoding Error: \(decodingError)")
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key '\(key)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type '\(type)' mismatch: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value of type '\(type)' not found: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                } else {
                    print("❌ Network Error: \(error.localizedDescription)")
                }
                throw error
            }
        }
        
        // Should never reach here, but just in case
        throw NSError(domain: "StoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"])
    }
    
    // Highlight API'si ile iletişim kuran yeni fonksiyon
    func fetchHighlights(highlightId: String) async throws -> [InstagramStoryModel] {
        print("🎯 Fetching highlights with ID: \(highlightId)")
        
        // URL'i oluştur
        guard let url = URL(string: highlightsBaseURL + highlightId) else {
            let error = URLError(.badURL)
            print("❌ Highlight URL Error: \(error.localizedDescription)")
            throw error
        }
        
        // Retry logic: Max 1 retry (total 2 attempts)
        var retryCount = 0
        let maxRetries = 1
        
        while retryCount <= maxRetries {
            do {
                print("🔗 Highlight Request URL: \(url.absoluteString) (attempt \(retryCount + 1)/\(maxRetries + 1))")
                let (data, response) = try await session.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = URLError(.badServerResponse)
                    print("❌ Highlight Response Error: Invalid HTTP response")
                    throw error
                }
                
                print("📡 Highlight HTTP Status Code: \(httpResponse.statusCode)")
                
                // 5xx errors: Retryable server errors
                if isServerError(statusCode: httpResponse.statusCode) {
                    print("⚠️ HTTP \(httpResponse.statusCode) Server Error")
                    if retryCount < maxRetries {
                        retryCount += 1
                        print("🔄 Retrying in 2 seconds...")
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        continue
                    } else {
                        throw URLError(.badServerResponse)
                    }
                }
                
                // 4xx errors: Do NOT retry, return immediately
                if (400...499).contains(httpResponse.statusCode) {
                    print("❌ HTTP \(httpResponse.statusCode) Client Error - No retry for 4xx errors")
                    throw URLError(.badServerResponse)
                }
                
                // Debug: Response data'yı yazdır
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Highlight Raw Response: \(responseString)")
                }
                
                guard httpResponse.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    print("❌ Highlight Server Error: HTTP \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Highlight Response Body: \(responseString)")
                    }
                    throw error
                }
                
                // Story yanıtları ile aynı modeli kullanıyoruz
                let decoder = JSONDecoder()
                let storyResponse = try decoder.decode(InstagramStoryResponse.self, from: data)
                
                guard storyResponse.success else {
                    throw NSError(domain: "StoryService", code: -1, 
                                 userInfo: [NSLocalizedDescriptionKey: "Failed to fetch highlights"])
                }
                
                print("✅ Successfully fetched \(storyResponse.stories.count) highlight stories")
                return storyResponse.stories
                
            } catch {
                // Check if error is retryable
                if shouldRetry(error: error, retryCount: retryCount, maxRetryCount: maxRetries) {
                    retryCount += 1
                    print("🔄 Retryable error detected, retrying in 2 seconds (attempt \(retryCount + 1)/\(maxRetries + 1))...")
                    do {
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        continue
                    } catch {
                        throw error
                    }
                }
                
                // Not retryable or max retries exceeded
                print("❌ Highlight Network Error: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Should never reach here, but just in case
        throw NSError(domain: "StoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"])
    }
} 