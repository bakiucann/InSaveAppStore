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

struct InstagramAPIResponse: Codable {
    let allVideoVersions: [VideoVersion]
    let downloadLink: String
    let thumbnailUrl: String
    let videoTitle: String
    let videoQuality: VideoQuality
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
    
    // Equatable protocol implementation
    static func == (lhs: InstagramVideoModel, rhs: InstagramVideoModel) -> Bool {
        return lhs.id == rhs.id
    }
}
