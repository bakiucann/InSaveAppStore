import SwiftUI

@MainActor // Ensure UI updates happen on the main thread
class UserProfileViewModel: ObservableObject {
    @Published var profile: InstagramProfileModel? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Posts and related properties
    @Published var posts: [ProfileService.PostItem]? = nil
    @Published var isLoadingPosts: Bool = false

    func fetchProfile(username: String) async {
        // Don't fetch if already loading
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        profile = nil // Clear previous profile data
        posts = nil // Clear previous posts data

        do {
            let fetchedProfile = try await ProfileService.shared.fetchProfile(username: username)
            self.profile = fetchedProfile
            print("ViewModel: Profile loaded for \(username)")
            
            // After loading profile, process posts data from the response
            await processPostsData()
        } catch let error as ProfileService.ProfileError {
            switch error {
            case .invalidURL:
                self.errorMessage = "Internal error: Invalid URL constructed."
            case .networkError(let underlyingError):
                self.errorMessage = "Network error: \(underlyingError.localizedDescription)"
            case .decodingError(let underlyingError):
                self.errorMessage = "Failed to process profile data. \(underlyingError.localizedDescription)"
            case .apiError(let message):
                self.errorMessage = "API Error: \(message)"
            case .requestBodyEncodingError:
                self.errorMessage = "Internal error: Failed to prepare request."
            case .noData:
                self.errorMessage = "No profile data received."
            case .profileNotFound:
                self.errorMessage = "Profile not found for user \(username). The account might be private or does not exist."
            }
            print("ViewModel Error: \(self.errorMessage ?? "Unknown error")")
        } catch {
            // Catch any other unexpected errors
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("ViewModel Unexpected Error: \(error)")
        }

        isLoading = false
    }
    
    // Process posts data from the API response
    private func processPostsData() async {
        isLoadingPosts = true
        
        // Access posts data from ProfileService's cached response
        if let postsData = ProfileService.shared.lastResponsePosts {
            // Map the posts items to our PostItem model, explicitly using ProfileService.PostItem
            let mappedPosts: [ProfileService.PostItem] = postsData.items?.compactMap { item in 
                guard let id = item.id,
                      let code = item.code,
                      let thumbnailUrl = URL(string: item.thumbnailUrl ?? "") else {
                    return nil
                }
                
                // Create ProfileService.PostItem directly (no need for separate View Model struct)
                return ProfileService.PostItem(
                    id: id, 
                    code: code, 
                    mediaType: item.mediaType, 
                    thumbnailUrl: item.thumbnailUrl, 
                    isVideo: item.isVideo, 
                    takenAt: item.takenAt
                )
            } ?? []
            
            self.posts = mappedPosts
            print("ViewModel: Processed \(self.posts?.count ?? 0) posts")
        } else {
            print("ViewModel: No posts data available in the response")
        }
        
        isLoadingPosts = false
    }
} 

