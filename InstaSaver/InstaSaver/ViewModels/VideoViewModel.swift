// VideoViewModel.swift
import Foundation
import Combine

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
        
        // Check for reel
        if let reelIndex = pathComponents.firstIndex(of: "reel"), reelIndex + 1 < pathComponents.count {
            return pathComponents[reelIndex + 1]
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
                    self?.errorMessage = error.localizedDescription
                    print("Error fetching video info: \(error.localizedDescription)")
                    
                    // Check for specific error from API response
                    switch error {
                    case InstagramServiceError.decodingError:
                        self?.errorMessage = NSLocalizedString("Failed to decode the response. Please check the URL or account privacy settings.", comment: "")
                    case InstagramServiceError.serverError(let message) where message.contains("Not found"):
                        self?.errorMessage = NSLocalizedString("This content is not available because the account is private.", comment: "")
                    default:
                        self?.errorMessage = error.localizedDescription
                    }
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
}
