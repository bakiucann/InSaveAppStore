import Foundation

struct InstagramStoryResponse: Codable {
    let success: Bool
    let stories: [InstagramStoryModel]
    let rateLimit: RateLimit
}

struct InstagramStoryModel: Codable, Identifiable {
    let type: String
    let url: String
    let thumbnailUrl: String
    let takenAt: Int
    
    var id: String {
        return "\(takenAt)"
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case url
        case thumbnailUrl = "thumbnail_url"
        case takenAt = "taken_at"
    }
}

struct RateLimit: Codable {
    let ip: LimitInfo
    let daily: LimitInfo
    let proxy: ProxyInfo
}

struct LimitInfo: Codable {
    let limit: Int
    let remaining: Int
    let resetAt: String
}

struct ProxyInfo: Codable {
    let available: Int
} 