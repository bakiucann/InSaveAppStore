import SwiftUI
import Kingfisher // Using Kingfisher for async image loading

struct UserProfileView: View {
    // ViewModel to manage profile data fetching and state
    @StateObject private var viewModel = UserProfileViewModel()
    // The username for which to fetch the profile
    let username: String
    // State for segment control
    @State private var selectedTab: ProfileTab = .posts

    // Environment variable to dismiss the view
    @Environment(\.presentationMode) var presentationMode

    // Predefined gradient for aesthetic consistency
    private let instagramGradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Enum for segment control tabs
    enum ProfileTab {
        case posts
        case reels
    }

    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential future navigation
            ZStack {
                // Background color
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)

                // Content area
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "xmark.octagon.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text("Error")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else if let profile = viewModel.profile {
                        // Main profile content
                        profileContent(profile: profile)
                    } else {
                        // Empty state or initial state (should ideally be covered by loading)
                        Spacer()
                        Text("No profile data available.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle(viewModel.profile?.username ?? username) // Show username in title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Use the custom BackButton if available and styled
                     Button {
                         presentationMode.wrappedValue.dismiss()
                     } label: {
                         Image(systemName: "chevron.left")
                             .foregroundColor(Color("igPink")) // Match app's accent
                     }
                }
            }
            .onAppear {
                // Fetch profile data when the view appears
                Task {
                    await viewModel.fetchProfile(username: username)
                }
            }
        }
    }

    // MARK: - Profile Content View
    @ViewBuilder
    private func profileContent(profile: InstagramProfileModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Top Section: Profile Pic & Stats
                profileHeader(profile: profile)

                // Info Section: Name, Category, Bio, Link
                profileInfo(profile: profile)

                // Segment Control and Media Grid
                mediaTabView()

            }
            .padding(.horizontal)
            .padding(.top, 5)
        }
    }

    // MARK: - Profile Header (Pic & Stats)
    private func profileHeader(profile: InstagramProfileModel) -> some View {
        HStack(spacing: 20) {
            // Profile Picture using Kingfisher
            KFImage(profile.bestProfilePicUrl)
                .placeholder { // Optional: Placeholder while loading
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))

            Spacer()

            // Stats
            HStack(spacing: 25) {
                profileStat(value: profile.mediaCount, label: "Posts")
                profileStat(value: profile.followerCount, label: "Followers")
                profileStat(value: profile.followingCount, label: "Following")
            }
            Spacer()
        }
    }

    // Helper for stats columns
    private func profileStat(value: Int?, label: String) -> some View {
        VStack(spacing: 2) {
            Text(formatCount(value ?? 0))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            Text(NSLocalizedString(label, comment: "Profile stat label"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Profile Info (Name, Bio, Link)
    private func profileInfo(profile: InstagramProfileModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Full Name
            if let fullName = profile.fullName, !fullName.isEmpty {
                Text(fullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }

            // Category (Optional)
            if let category = profile.category, !category.isEmpty {
                Text(category)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Biography
            if let bio = profile.biography, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(.top, 2)
            }

            // Bio Link (Primary)
            if let externalUrl = profile.externalUrl, let url = URL(string: externalUrl) {
                Link(destination: url) {
                    Text(url.host ?? externalUrl) // Show host or full URL
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue) // Standard link color
                }
                .padding(.top, 2)
            }

            // You could iterate over profile.bioLinks here if you need to show multiple links
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure text aligns left
    }

    // MARK: - Media Tab View (Posts and Reels)
    private func mediaTabView() -> some View {
        VStack(spacing: 0) {
            // Segment Control
            HStack(spacing: 0) {
                segmentButton(title: "Posts", tab: .posts, iconName: "square.grid.2x2")
                segmentButton(title: "Reels", tab: .reels, iconName: "play.rectangle")
            }
            .padding(.top, 15)
            
            Divider()
                .padding(.top, 8)
            
            // Media Grid based on selected tab
            if viewModel.isLoadingPosts {
                ProgressView()
                    .padding(.top, 30)
            } else if let posts = viewModel.posts, !posts.isEmpty {
                postsGridView(posts: posts)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: selectedTab == .posts ? "photo.on.rectangle" : "play.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                    
                    Text(selectedTab == .posts ? "No Posts Yet" : "No Reels Yet")
                        .font(.headline)
                    
                    Text("When \(viewModel.profile?.username ?? "this user") shares \(selectedTab == .posts ? "posts" : "reels"), you'll see them here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 30)
            }
        }
    }
    
    // Segment control button
    private func segmentButton(title: String, tab: ProfileTab, iconName: String) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
                
                // Indicator bar for selected tab
                Rectangle()
                    .fill(selectedTab == tab ? Color("igPink") : Color.clear)
                    .frame(height: 1)
            }
        }
        .foregroundColor(selectedTab == tab ? .primary : .secondary)
        .frame(maxWidth: .infinity)
    }
    
    // Posts grid view
    private func postsGridView(posts: [ProfileService.PostItem]) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2)
        ]
        
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts, id: \.id) { post in
                postThumbnail(post: post)
            }
        }
        .padding(.top, 2)
    }
    
    // Individual post thumbnail
    private func postThumbnail(post: ProfileService.PostItem) -> some View {
        let thumbnailUrl = URL(string: post.thumbnailUrl ?? "")
        
        return KFImage(thumbnailUrl)
            .placeholder { // Optional: Placeholder while loading
                Rectangle().fill(Color.gray.opacity(0.15))
            }
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()
            .overlay(
                Group {
                    if post.isVideo ?? false {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                                    .padding(4)
                            }
                        }
                    }
                }
            )
    }
    
    // MARK: - Helper Functions
    // Formats large numbers (e.g., 12345 -> 12.3K, 1234567 -> 1.2M)
    private func formatCount(_ count: Int) -> String {
        if count < 1000 {
            return "\(count)"
        } else if count < 1_000_000 {
            let num = Double(count) / 1_000.0
            return String(format: "%.1fK", num).replacingOccurrences(of: ".0", with: "")
        } else {
            let num = Double(count) / 1_000_000.0
            return String(format: "%.1fM", num).replacingOccurrences(of: ".0", with: "")
        }
    }
}

// MARK: - Preview Provider
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a username for the preview
        // Note: This will use the mock data if username is "mrbeast" 
        // and mock data file exists.
        UserProfileView(username: "mrbeast")
    }
}

// MARK: - Post Item Model (REMOVED - Definition moved/consolidated in ProfileService)
// struct PostItem: Identifiable { ... }


