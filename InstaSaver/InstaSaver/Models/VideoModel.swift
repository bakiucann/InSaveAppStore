// VideoModel.swift
import Foundation

struct VideoVersion: Codable, Identifiable {
    let type: Int
    let width: Int
    let height: Int
    let id: String
    let url: String
}

struct APIErrorResponse: Codable {
    let error: ErrorDetail
    
    struct ErrorDetail: Codable {
        let error: String
    }
}

// Carousel içindeki öğeler için model
struct CarouselItem: Codable {
    let index: Int
    let isPhoto: Bool
    let allVideoVersions: [VideoVersion]
    let downloadLink: String
    let thumbnailUrl: String
    let videoQuality: VideoQuality
    let videoTitle: String
}

struct InstagramAPIResponse: Codable {
    // Normal içerik için alanlar
    let allVideoVersions: [VideoVersion]?
    let downloadLink: String
    let thumbnailUrl: String
    let videoTitle: String
    let videoQuality: VideoQuality
    let isPhoto: Bool?
    
    // Carousel içerik için alanlar
    let isCarousel: Bool?
    let totalItems: Int?
    let caption: String?
    let items: [CarouselItem]?
    
    // Özelleştirilmiş decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Önce isCarousel'i kontrol edelim
        isCarousel = try container.decodeIfPresent(Bool.self, forKey: .isCarousel)
        
        if isCarousel == true {
            // Carousel içerik için alanları decode et
            totalItems = try container.decodeIfPresent(Int.self, forKey: .totalItems)
            caption = try container.decodeIfPresent(String.self, forKey: .caption)
            items = try container.decodeIfPresent([CarouselItem].self, forKey: .items)
            
            // İlk öğeyi veya boş değerleri kullan
            if let firstItem = items?.first {
                allVideoVersions = firstItem.allVideoVersions
                downloadLink = firstItem.downloadLink
                thumbnailUrl = firstItem.thumbnailUrl
                videoTitle = firstItem.videoTitle
                videoQuality = firstItem.videoQuality
                isPhoto = firstItem.isPhoto
            } else {
                allVideoVersions = []
                downloadLink = ""
                thumbnailUrl = ""
                videoTitle = ""
                videoQuality = VideoQuality.default
                isPhoto = false
            }
        } else {
            // Normal içerik için alanları decode et
            allVideoVersions = try container.decodeIfPresent([VideoVersion].self, forKey: .allVideoVersions) ?? []
            downloadLink = try container.decode(String.self, forKey: .downloadLink)
            thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
            videoTitle = try container.decode(String.self, forKey: .videoTitle)
            videoQuality = try container.decode(VideoQuality.self, forKey: .videoQuality)
            isPhoto = try container.decodeIfPresent(Bool.self, forKey: .isPhoto)
            
            // Carousel içerik değilse bu alanları null olarak ayarla
            totalItems = nil
            caption = nil
            items = nil
        }
    }
}

struct VideoQuality: Codable {
    let width: Int
    let height: Int
    
    static let `default` = VideoQuality(width: 720, height: 1280)
}

struct InstagramVideoModel: Codable, Identifiable, Equatable {
    let id: String
    let allVideoVersions: [VideoVersion]
    let downloadLink: String
    let thumbnailUrl: String
    let videoTitle: String
    let videoQuality: VideoQuality
    let isPhoto: Bool?
    let isCarousel: Bool?
    
    // Carousel için ek bilgiler
    var carouselItems: [CarouselItem]?
    var totalItems: Int?
    
    // Equatable protocol implementation
    static func == (lhs: InstagramVideoModel, rhs: InstagramVideoModel) -> Bool {
        return lhs.id == rhs.id
    }
}
