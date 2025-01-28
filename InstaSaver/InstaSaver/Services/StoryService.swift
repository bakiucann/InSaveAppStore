import Foundation

class StoryService {
    static let shared = StoryService()
    private let baseURL = "https://instagramcoms.vercel.app/api/stories/"
    
    private init() {}
    
    func fetchStories(username: String) async throws -> [InstagramStoryModel] {
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: baseURL + encodedUsername) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let storyResponse = try decoder.decode(InstagramStoryResponse.self, from: data)
        
        guard storyResponse.success else {
            throw NSError(domain: "StoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch stories"])
        }
        
        return storyResponse.stories
    }
} 