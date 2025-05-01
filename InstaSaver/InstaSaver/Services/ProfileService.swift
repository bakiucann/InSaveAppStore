import Foundation

class ProfileService {
    static let shared = ProfileService()
    // Update baseURL to the correct endpoint for POST
    private let baseURL = "http://localhost:3001/api/profile" // Removed trailing slash and username placeholder

    // Store the last response posts data for later use
    var lastResponsePosts: PostsData?

    private init() {}

    enum ProfileError: Error {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case apiError(String)
        case requestBodyEncodingError
        case noData
        case profileNotFound
    }

    struct ProfileRequestBody: Codable {
        let url: String
    }

    // Posts data structures
    struct PostsData: Codable {
        let count: Int?
        let items: [PostItem]?
        let user: PostsUser?
    }

    struct PostsUser: Codable {
        let id: String?
        let username: String?
        let fullName: String?
        let profilePicUrl: String?
        let isPrivate: Bool?
        let isVerified: Bool?
        
        enum CodingKeys: String, CodingKey {
            case id
            case username
            case fullName = "full_name"
            case profilePicUrl = "profile_pic_url"
            case isPrivate = "is_private"
            case isVerified = "is_verified"
        }
    }

    struct PostItem: Codable {
        let id: String?
        let code: String?
        let mediaType: Int?
        let thumbnailUrl: String?
        let isVideo: Bool?
        let takenAt: Int?
        
        enum CodingKeys: String, CodingKey {
            case id
            case code
            case mediaType = "media_type"
            case thumbnailUrl = "thumbnail_url"
            case isVideo = "is_video"
            case takenAt = "taken_at"
        }
    }

    func fetchProfile(username: String) async throws -> InstagramProfileModel {
        guard let url = URL(string: baseURL) else {
            throw ProfileError.invalidURL
        }

        // Create a request with POST method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create and encode the request body
        let requestBody = ProfileRequestBody(url: username)

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw ProfileError.requestBodyEncodingError
        }

        print("📱 Fetching profile for username: \(username)")
        print("🔗 Request URL: \(url.absoluteString) (Using POST)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Print HTTP status code for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Profile Service HTTP Status Code: \(httpResponse.statusCode)")
            }

            // Print raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON Response:")
                print(jsonString)
            }

            // Decode the response
            let profileResponse = try JSONDecoder().decode(InstagramProfileResponse.self, from: data)

            // Check if data is available
            guard let profileData = profileResponse.profileInfo?.data else {
                throw ProfileError.profileNotFound // Profile data key not found or null in response
            }

            // Also decode and store posts data for later use
            if let postsDataJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let postsDict = postsDataJson["posts"] as? [String: Any],
               let postsData = try? JSONSerialization.data(withJSONObject: postsDict["data"] ?? [:]) {
                self.lastResponsePosts = try? JSONDecoder().decode(PostsData.self, from: postsData)
            }

            return profileData
        } catch let decodingError as DecodingError {
            print("❌ Decoding Error: \(decodingError)")
            throw ProfileError.decodingError(decodingError)
        } catch {
            print("❌ Network Error: \(error)")
            throw ProfileError.networkError(error)
        }
    }
} 

