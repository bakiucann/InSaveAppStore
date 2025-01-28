// UserModel.swift
struct UserVideosAPIResponse: Codable {
    let code: Int
    let msg: String
    let processedTime: Double
    let data: UserVideosData?
}

struct UserVideosData: Codable {
    let videos: [UserVideoModel]
    let cursor: String?
    let hasMore: Bool?
}

struct UserVideoModel: Codable, Equatable {
    static func == (lhs: UserVideoModel, rhs: UserVideoModel) -> Bool {
        return lhs.videoId == rhs.videoId
    }
    
    let videoId: String
    let region: String
    let title: String
    let cover: String?  // Cover can be null
    let aiDynamicCover: String?  // Dynamic cover can be null
    let originCover: String?  // Origin cover can be null
    let duration: Int
    let play: String?  // Play URL can be null
    let wmplay: String?  // Watermarked play URL can be null
    let size: Int?
    let wmSize: Int?
    let music: String?
    let musicInfo: MusicInfo?  // Music info can be null
    let playCount: Int?
    let diggCount: Int?
    let commentCount: Int?
    let shareCount: Int?
    let downloadCount: Int?
    let collectCount: Int?
    let createTime: Int?
    let isAd: Bool?
    let commerceInfo: CommerceInfo?
    let commercialVideoInfo: String?
    let itemCommentSettings: Int?
    let author: Author?
    let isTop: Int?
}

struct MusicInfo: Codable {
    let id: String
    let title: String?
    let play: String?
    let cover: String?
    let author: String
    let original: Bool
    let duration: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, play, cover, author, original, duration
    }
    
    // Custom initializer to handle dynamic 'duration' type
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)  // Optional title
        play = try container.decodeIfPresent(String.self, forKey: .play)  // Optional play URL
        cover = try container.decodeIfPresent(String.self, forKey: .cover)  // Optional cover image
        author = try container.decode(String.self, forKey: .author)
        original = try container.decode(Bool.self, forKey: .original)
        
        // Handle 'duration' as either String or Int
        if let durationInt = try? container.decode(Int.self, forKey: .duration) {
            duration = durationInt
        } else if let durationString = try? container.decode(String.self, forKey: .duration), let durationInt = Int(durationString) {
            duration = durationInt
        } else {
            // Default value or throw error
            duration = 0
        }
    }
    
    // Manuel initializer ekliyoruz
    init(id: String, title: String?, play: String?, cover: String?, author: String, original: Bool, duration: Int) {
        self.id = id
        self.title = title
        self.play = play
        self.cover = cover
        self.author = author
        self.original = original
        self.duration = duration
    }
}

struct CommerceInfo: Codable {
    let advPromotable: Bool?
    let auctionAdInvited: Bool?
    let brandedContentType: Int?
    let withCommentFilterWords: Bool?
}

struct Author: Codable {
    let id: String
    let uniqueId: String
    let nickname: String
    let avatar: String?  // Avatar can be null
}
