// VideoViewModel.swift
import Foundation
import Combine
import CoreData

class VideoViewModel: ObservableObject {
    @Published var video: InstagramVideoModel?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private var instagramService = InstagramService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Helper function to extract Reel ID from URL
    func extractInstagramID(from url: String) -> String? {
        guard let url = URL(string: url) else { return nil }
        let pathComponents = url.pathComponents
        
        // Check for share
        if let shareIndex = pathComponents.firstIndex(of: "share"), shareIndex + 1 < pathComponents.count {
            return pathComponents[shareIndex + 1]
        }
        
        // Check for reel (singular)
        if let reelIndex = pathComponents.firstIndex(of: "reel"), reelIndex + 1 < pathComponents.count {
            return pathComponents[reelIndex + 1]
        }
        
        // Check for reels (plural)
        if let reelsIndex = pathComponents.firstIndex(of: "reels"), reelsIndex + 1 < pathComponents.count {
            return pathComponents[reelsIndex + 1]
        }
        
        // Check for post
        if let postIndex = pathComponents.firstIndex(of: "p"), postIndex + 1 < pathComponents.count {
            return pathComponents[postIndex + 1]
        }
        
        return nil
    }
    
    // Helper function to format Instagram URL
    private func formatInstagramURL(_ url: String) -> String {
        return url.replacingOccurrences(of: "instagram.com/reels/", with: "instagram.com/reel/")
    }
    
    func fetchVideoInfo(url: String, quality: Int? = nil) {
        self.isLoading = true
        self.errorMessage = nil // Hata mesajını sıfırla
        self.video = nil // Önceki videoyu sıfırla
        
        // Format the URL before validation
        let formattedURL = formatInstagramURL(url)
        
        // Validate URL format before making the network request
        guard isValidURL(formattedURL) else {
            self.errorMessage = InstagramServiceError.invalidURL.localizedDescription + "#\(UUID())"
            self.isLoading = false // Ensure isLoading is set to false
            return
        }
        
        instagramService.fetchReelInfo(url: formattedURL, quality: quality) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let videoData):
                    if let instagramID = self?.extractInstagramID(from: formattedURL) {
                        // Modeli oluştur
                        var model = InstagramVideoModel(
                            id: instagramID,
                            allVideoVersions: videoData.allVideoVersions ?? [],
                            downloadLink: videoData.downloadLink,
                            thumbnailUrl: videoData.thumbnailUrl,
                            videoTitle: videoData.videoTitle,
                            videoQuality: videoData.videoQuality,
                            isPhoto: videoData.isPhoto,
                            isCarousel: videoData.isCarousel
                        )
                        
                        // Carousel için ek bilgileri ekle
                        if videoData.isCarousel == true {
                            model.carouselItems = videoData.items
                            model.totalItems = videoData.totalItems
                            
                            // Debug bilgisi
                            print("🎠 Carousel içeriği: \(videoData.totalItems ?? 0) öğe içeriyor")
                            if let items = videoData.items {
                                print("🎠 İlk öğe: \(items.first?.downloadLink ?? "bilinmiyor")")
                            }
                        }
                        
                        self?.video = model
                    } else {
                        self?.errorMessage = "Could not extract Instagram ID from URL"
                    }
                case .failure(let error):
                    print("❌ Error fetching video info: \(error.localizedDescription)")
                    print("❌ Error type: \(error)")
                    
                    // Map errors to user-friendly messages
                    switch error {
                    case InstagramServiceError.networkError(let networkError):
                        // Check for timeout or connection errors
                        if let urlError = networkError as? URLError {
                            print("❌ URLError code: \(urlError.code.rawValue)")
                            switch urlError.code {
                            case .timedOut, .networkConnectionLost:
                                self?.errorMessage = NSLocalizedString("error_connection_timeout", comment: "")
                                print("✅ Mapped to: error_connection_timeout")
                            default:
                                // Other network errors - check if it's a timeout-related error
                                self?.errorMessage = NSLocalizedString("error_connection_timeout", comment: "")
                                print("✅ Mapped to: error_connection_timeout (default network error)")
                            }
                        } else {
                            self?.errorMessage = NSLocalizedString("error_connection_timeout", comment: "")
                            print("✅ Mapped to: error_connection_timeout (non-URLError)")
                        }
                    case InstagramServiceError.serverError(let message):
                        // ALL 4xx and 5xx errors map to private account message
                        print("❌ Server error message: \(message)")
                        self?.errorMessage = NSLocalizedString("error_private_or_server", comment: "")
                        print("✅ Mapped to: error_private_or_server")
                    case InstagramServiceError.decodingError:
                        // Decoding errors might indicate private account or invalid response
                        self?.errorMessage = NSLocalizedString("error_private_or_server", comment: "")
                        print("✅ Mapped to: error_private_or_server (decoding error)")
                    case InstagramServiceError.noData:
                        // No data might be due to private account
                        self?.errorMessage = NSLocalizedString("error_private_or_server", comment: "")
                        print("✅ Mapped to: error_private_or_server (no data)")
                    case InstagramServiceError.invalidURL:
                        // Invalid URL - use localized description
                        self?.errorMessage = InstagramServiceError.invalidURL.localizedDescription + "#\(UUID())"
                        print("✅ Mapped to: invalidURL localized description")
                    default:
                        // Unknown errors - default to private account message
                        self?.errorMessage = NSLocalizedString("error_private_or_server", comment: "")
                        print("✅ Mapped to: error_private_or_server (unknown error)")
                    }
                    
                    print("📱 Final error message set: \(self?.errorMessage ?? "nil")")
                }
            }
        }
    }
    
    func clearVideoData() {
        video = nil
        errorMessage = nil
    }
    
    // URL Validation Function
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        // Additional checks can be added here if necessary (e.g., specific schemes)
        return ["http", "https"].contains(url.scheme?.lowercased() ?? "")
    }
    
    func setVideo(_ video: InstagramVideoModel) {
        self.video = video
    }
    
    // MARK: - Smart Refetch Helpers
    
    /// Lightweight health check for a video URL using HTTP HEAD.
    /// - Returns: true if statusCode is in 200...299, false otherwise (including timeout / errors).
    private func checkVideoUrlStatus(url: String) async -> Bool {
        guard let url = URL(string: url) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5 // seconds
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            print("⚠️ URL health check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Build an InstagramVideoModel from a HistoryItem using only local data (no network).
    private func makeVideoModel(from item: HistoryItem) -> InstagramVideoModel {
        InstagramVideoModel(
            id: item.id,
            allVideoVersions: [
                VideoVersion(
                    type: 101,
                    width: 1080,
                    height: 1920,
                    id: item.id + "_hd",
                    url: item.originalUrl ?? ""
                ),
                VideoVersion(
                    type: 103,
                    width: 720,
                    height: 1280,
                    id: item.id + "_sd",
                    url: item.originalUrl ?? ""
                )
            ],
            downloadLink: item.originalUrl ?? "",
            thumbnailUrl: item.originCover ?? "",
            videoTitle: item.title,
            videoQuality: VideoQuality.default,
            isPhoto: item.type == "photo",
            isCarousel: false
        )
    }
    
    /// Fetch fresh video info from the API and return an InstagramVideoModel without mutating view-model state.
    private func fetchVideoModel(url: String, quality: Int? = nil) async throws -> InstagramVideoModel {
        let formattedURL = formatInstagramURL(url)
        // Validate before hitting the network
        guard isValidURL(formattedURL) else {
            throw InstagramServiceError.invalidURL
        }
        return try await withCheckedThrowingContinuation { continuation in
            instagramService.fetchReelInfo(url: formattedURL, quality: quality) { [weak self] result in
                switch result {
                case .success(let videoData):
                    guard let instagramID = self?.extractInstagramID(from: formattedURL) else {
                        continuation.resume(throwing: InstagramServiceError.invalidURL)
                        return
                    }
                    var model = InstagramVideoModel(
                        id: instagramID,
                        allVideoVersions: videoData.allVideoVersions ?? [],
                        downloadLink: videoData.downloadLink,
                        thumbnailUrl: videoData.thumbnailUrl,
                        videoTitle: videoData.videoTitle,
                        videoQuality: videoData.videoQuality,
                        isPhoto: videoData.isPhoto,
                        isCarousel: videoData.isCarousel
                    )
                    if videoData.isCarousel == true {
                        model.carouselItems = videoData.items
                        model.totalItems = videoData.totalItems
                    }
                    continuation.resume(returning: model)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Smart refetch for a history item. Returns a model built from local data if URL is healthy,
    /// otherwise fetches fresh info from the API, updates Core Data, and returns the new model.
    func refreshHistoryItem(_ item: HistoryItem, context: NSManagedObjectContext) async throws -> InstagramVideoModel? {
        // If we don't have a URL at all, skip health check and go straight to refetch.
        let existingUrl = item.originalUrl ?? ""
        if !existingUrl.isEmpty {
            let isHealthy = await checkVideoUrlStatus(url: existingUrl)
            if isHealthy {
                // Use local data only, no API call.
                return makeVideoModel(from: item)
            }
        }
        
        // URL is missing or dead -> refetch from API using canonical Instagram URL built from the ID.
        let reconstructedUrl = "https://www.instagram.com/reel/\(item.id)/"
        let freshModel = try await fetchVideoModel(url: reconstructedUrl)
        
        // Update Core Data on the context's queue for thread safety.
        let updatedModel = try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SavedVideo> = SavedVideo.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", item.id)
                    let results = try context.fetch(fetchRequest)
                    if let savedVideo = results.first {
                        savedVideo.originalUrl = freshModel.downloadLink
                        savedVideo.originCover = freshModel.thumbnailUrl
                        savedVideo.date = Date()
                        if let isPhoto = freshModel.isPhoto {
                            savedVideo.type = isPhoto ? "photo" : "video"
                        }
                    }
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: freshModel)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        return updatedModel
    }
}
