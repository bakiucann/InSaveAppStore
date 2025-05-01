import Foundation

// Wrapper struct to match the actual API response structure
struct InstagramProfileResponse: Codable {
    let success: Bool?
    let profileInfo: ProfileInfoWrapper?
    let posts: PostsData?
}

// Intermediate struct to represent the "profileInfo" object
struct ProfileInfoWrapper: Codable {
    let data: InstagramProfileModel?
}

// Intermediate struct for the "posts" object
struct PostsData: Codable {
    let data: PostsWrapper?
}

struct PostsWrapper: Codable {
    let count: Int?
    let items: [PostItem]?
}

// Model to hold relevant profile information
struct InstagramProfileModel: Codable, Identifiable {
    let id: String?
    let username: String?
    let fullName: String?
    let biography: String?
    let profilePicUrl: String?
    let profilePicUrlHd: String?
    let externalUrl: String?
    let followerCount: Int?
    let followingCount: Int?
    let mediaCount: Int?
    let isVerified: Bool?
    let isPrivate: Bool?
    let category: String?
    let bioLinks: [BioLink]?

    // Computed property to get the best available profile picture URL
    var bestProfilePicUrl: URL? {
        if let urlString = profilePicUrlHd, let url = URL(string: urlString) {
            return url
        }
        if let urlString = profilePicUrl, let url = URL(string: urlString) {
            return url
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case biography
        case profilePicUrl = "profile_pic_url"
        case profilePicUrlHd = "profile_pic_url_hd"
        case externalUrl = "external_url"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case mediaCount = "media_count"
        case isVerified = "is_verified"
        case isPrivate = "is_private"
        case category
        case bioLinks = "bio_links"
    }
}

// Model for individual post/reel items in the grid
struct PostItem: Codable, Identifiable {
    let id: String
    let mediaType: Int?
    let thumbnailUrl: String?
    let videoUrl: String?
    let isVideo: Bool?

    var bestThumbnailUrl: URL? {
        if let urlString = thumbnailUrl, let url = URL(string: urlString) {
            return url
        }
        return nil
    }
    
    var isReel: Bool {
        return mediaType == 2 && isVideo == true
    }

    enum CodingKeys: String, CodingKey {
        case id
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
        case videoUrl = "video_url"
        case isVideo = "is_video"
    }
}

// Model for items in the bio_links array
struct BioLink: Codable, Identifiable {
    let id = UUID()
    let linkId: Int64?
    let url: String?
    let title: String?
    let linkType: String?

    enum CodingKeys: String, CodingKey {
        case linkId = "link_id"
        case url
        case title
        case linkType = "link_type"
    }
} 
