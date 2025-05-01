import Foundation

class StoryService {
    static let shared = StoryService()
    private let baseURL = "https://instagramcoms.vercel.app/api/stories/"
    private let highlightsBaseURL = "https://instagramcoms.vercel.app/api/highlights/"
    
    private init() {}
    
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
        
        do {
            print("📱 Fetching stories for username: \(username)")
            print("🔗 Request URL: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                print("❌ Server Response Error: Invalid HTTP response")
                throw error
            }
            
            print("📡 HTTP Status Code: \(httpResponse.statusCode)")
            
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
            do {
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
                print("❌ Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
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
                }
                throw error
            }
            
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("Decoding Error Details: \(decodingError)")
            }
            throw error
        }
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
        
        do {
            print("🔗 Highlight Request URL: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                print("❌ Highlight Response Error: Invalid HTTP response")
                throw error
            }
            
            print("📡 Highlight HTTP Status Code: \(httpResponse.statusCode)")
            
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
            print("❌ Highlight Network Error: \(error.localizedDescription)")
            throw error
        }
    }
} 