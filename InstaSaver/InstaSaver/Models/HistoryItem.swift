import Foundation

struct HistoryItem: Identifiable {
    let id: String
    let title: String
    let originCover: String?
    let originalUrl: String?
    let date: Date
    let coverImageData: Data?
} 