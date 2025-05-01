//
//  SearchSectionView.swift
//  InstaSaver
//
//  Created by Baki Uçan on 6.01.2025.
//

import SwiftUI

struct SearchSectionView: View {
    @Binding var inputText: String
    @Binding var showPasteButton: Bool
    @Binding var isUrlSearch: Bool
    @Binding var isLoading: Bool
    @Binding var showPreview: Bool
    @Binding var showCustomAlert: Bool
    
    @State private var searchCount = 0
    @State private var isHovering = false
    @State private var showTutorial = false
    @State private var animateGradient = false
    @State private var currentPage = 0
    @State private var showStoryView = false
    @State private var stories: [InstagramStoryModel] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchMode: SearchMode = .url
    @StateObject private var configManager = ConfigManager.shared
    
    // State variables for Profile View Navigation
    @State private var showUserProfileView = false // Controls the NavigationLink
    @State private var selectedUsername: String? = nil // Holds the username for the profile view
    
    @ObservedObject var subscriptionManager: SubscriptionManager
    let interstitial: InterstitialAd
    @ObservedObject var videoViewModel: VideoViewModel
    
    private let instagramGradient: LinearGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    enum SearchMode: String, CaseIterable {
        case url = "URL"
        case username = "username"
        
        var displayName: String {
            switch self {
            case .url:
                return "URL"
            case .username:
                return NSLocalizedString("Username", comment: "")
            }
        }
        
        var emptyInputError: String {
            switch self {
            case .url:
                return NSLocalizedString("Please enter a valid Instagram URL", comment: "")
            case .username:
                return NSLocalizedString("Please enter an Instagram username", comment: "")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // NavigationLink for navigating to UserProfileView
            // It's activated programmatically by changing showUserProfileView
            if let username = selectedUsername {
                NavigationLink(destination: UserProfileView(username: username),
                               isActive: $showUserProfileView) {
                    EmptyView() // Invisible link
                }
            }
            
            // Animated Header Section
            VStack(spacing: 12) {
                ZStack {
                    // Background circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("igPurple"),
                                    Color("igPink"),
                                    Color("igOrange")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    // Download icon
                    Image(systemName: "arrow.down")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(animateGradient ? 360 : 0))
                        .animation(
                            Animation
                                .spring(response: 1, dampingFraction: 1)
                                .repeatForever(autoreverses: false),
                            value: animateGradient
                        )
                }
                .onAppear { animateGradient = true }
                
                Text(NSLocalizedString("InSave for Instagram", comment: ""))
                    .font(.system(size: 26, weight: .bold))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color("igPurple"),
                                Color("igPink"),
                                Color("igOrange")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .mask(
                        Text(NSLocalizedString("InSave for Instagram", comment: ""))
                            .font(.system(size: 26, weight: .bold))
                    )
                
                Text(NSLocalizedString("Download Reels, Stories & Video Posts", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            
            // URL Input Section
            VStack(spacing: 15) {
                // Custom Segmented control
                if Locale.current.languageCode != "en" || configManager.showDownloadButtons {
                    CustomSegmentedControl(
                        selectedOption: $searchMode,
                        options: SearchMode.allCases
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .onChange(of: searchMode) { _ in
                        // Segmentler arası geçişte textfield'ı temizle
                        inputText = ""
                        showPasteButton = true
                        isHovering = false
                    }
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color("igPurple"),
                                            Color("igPink"),
                                            Color("igOrange")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: isHovering ? 2 : 1
                                )
                        )
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    HStack {
                        Image(systemName: searchMode == .url ? "link" : "person")
                            .foregroundColor(Color("igPink"))
                            .font(.system(size: 18))
                            .padding(.leading, 20)
                        
                        TextField(
                            searchMode == .url 
                                ? NSLocalizedString("Paste Instagram URL here...", comment: "")
                                : NSLocalizedString("Enter Instagram username...", comment: ""), 
                            text: $inputText
                        )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 15)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: inputText) { newValue in
                                showPasteButton = newValue.isEmpty
                                withAnimation {
                                    isHovering = !newValue.isEmpty
                                }
                            }
                        
                        // Clear button (X)
                        if !inputText.isEmpty {
                            Button(action: {
                                inputText = "" // Clear the text field
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color("igPink"))
                                    .font(.system(size: 18))
                                    .padding(.trailing, 20)
                            }
                        }
                        
                        if showPasteButton {
                            Button(action: {
                                if let clipboardText = UIPasteboard.general.string {
                                    withAnimation {
                                        inputText = clipboardText
                                    }
                                }
                            }) {
                                Text(NSLocalizedString("Paste", comment: ""))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color("igPurple"),
                                                Color("igPink")
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 15)
                        }
                    }
                }
                .frame(height: 55)
                
                // Download Button
                Button(action: {
                    guard !inputText.isEmpty else {
                        errorMessage = searchMode.emptyInputError
                        showError = true
                        return
                    }
                    
                    // Extract username or determine action based on input type
                    let cleanedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let potentialUsername = extractPotentialUsername(from: cleanedInput)

                    // Reset state for new search
                    videoViewModel.clearVideoData()
                    isUrlSearch = false // Reset this, specific logic will set it if needed
                    isLoading = true
                    showPreview = false
                    showUserProfileView = false // Reset navigation state
                    selectedUsername = nil

                    // --- Input Handling Logic ---
                    if searchMode == .username {
                        // If username mode is selected, directly treat input as username
                        if isPotentialURL(cleanedInput) {
                            // If user entered URL in username mode, show error
                            errorMessage = NSLocalizedString("Please enter only the username, not a URL.", comment: "Error when URL is entered in username field")
                            showError = true
                            isLoading = false
                        } else {
                            // Check if it looks like a story URL anyway (e.g., pasted by mistake)
                            if isStoryURL(cleanedInput) {
                                handleStoryURL(input: cleanedInput) // Process as story
                            } else {
                                // Assume it's a profile username
                                navigateToUserProfile(username: cleanedInput)
                            }
                        }
                    } else { // URL Mode
                        // First, check if it's a valid URL structure
                         guard let url = URL(string: cleanedInput), url.host?.contains("instagram.com") == true else {
                            errorMessage = NSLocalizedString("Please enter a valid Instagram URL.", comment: "Error for invalid URL structure")
                            showError = true
                            isLoading = false
                            return
                        }

                        // Check specific URL types
                        if isStoryURL(cleanedInput) {
                            handleStoryURL(input: cleanedInput)
                        } else if isProfileURL(cleanedInput) {
                            // If it's a simple profile URL (e.g., instagram.com/username)
                            if let username = potentialUsername {
                                 navigateToUserProfile(username: username)
                            } else {
                                 // Fallback or error if username extraction fails from profile URL
                                 errorMessage = NSLocalizedString("Could not extract username from profile URL.", comment: "Error extracting username from profile URL")
                                 showError = true
                                 isLoading = false
                            }
                        } else {
                            // Assume it's a Post/Reel URL
                            isUrlSearch = true // Set for VideoViewModel
                            if !subscriptionManager.isUserSubscribed {
                                interstitial.showAd(
                                    from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
                                ) {
                                    performSearch()
                                }
                            } else {
                                performSearch()
                            }
                        }
                    }
                    // --- End Input Handling Logic ---
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 20))
                        Text(NSLocalizedString("Download Now", comment: ""))
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        LinearGradient(
                            colors: [
                                Color("igPurple"),
                                Color("igPink"),
                                Color("igOrange")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color("igPink").opacity(0.3), radius: 10, x: 0, y: 5)
                    .scaleEffect(isHovering ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3), value: isHovering)
                }
            }
            .padding(.horizontal)
            
            // Tutorial Section
            VStack(spacing: 0) {
                // Tutorial Pages with Step Numbers
                TabView(selection: $currentPage) {
                    // Step 1: Copy Link
                    CompactStepView(
                        number: "1",
                        icon: "square.and.arrow.up",
                        title: NSLocalizedString("Copy Link", comment: ""),
                        description: NSLocalizedString("Open Instagram and copy video/story link", comment: "")
                    )
                    .tag(0)
                    
                    // Step 2: Paste
                    CompactStepView(
                        number: "2",
                        icon: "doc.on.clipboard",
                        title: NSLocalizedString("Paste URL/Username", comment: ""),
                        description: NSLocalizedString("Paste the link or enter username in the box", comment: "")
                    )
                    .tag(1)
                    
                    // Step 3: Download
                    CompactStepView(
                        number: "3",
                        icon: "arrow.down.circle",
                        title: NSLocalizedString("Download", comment: ""),
                        description: NSLocalizedString("Click download and save to your gallery", comment: "")
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 120)
                .overlay(
                    // Custom Page Control
                    CompactPageControl(numberOfPages: 3, currentPage: $currentPage)
                        .padding(.bottom, -5),
                    alignment: .bottom
                )
            }
            .background(Color.white)
            .padding(.bottom, 15)
        }
        .padding(.vertical)
        .background(Color.white)
        .fullScreenCover(isPresented: $showStoryView) {
            NavigationView {
                StoryView(stories: stories, isFromHistory: false)
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // ConfigManager zaten init sırasında yükleniyor, burada çağrılmasına gerek yok
            // configManager.reloadConfig()
        }
        .onChange(of: configManager.showDownloadButtons) { newValue in
            // Segmented control gizlenecekse ve dil İngilizce ise
            if !newValue && Locale.current.languageCode == "en" {
                // Default olarak URL mode'unu ayarla
                searchMode = .url
            }
        }
    }
    
    // MARK: - Helper Functions for URL/Username Detection

    private func isPotentialURL(_ text: String) -> Bool {
        // Basic check if the string contains elements typical of a URL
        return text.contains("/") || text.contains(".") || text.contains("http")
    }

    private func isProfileURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) else { return false }
        // Check if host is instagram.com
        guard url.host?.lowercased().contains("instagram.com") == true else { return false }
        // Check path components: Should be 1 (the username) or 0 if just domain
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        // Allow only domain or domain/username
        return pathComponents.count <= 1 && !pathComponents.contains("stories") && !pathComponents.contains("p") && !pathComponents.contains("reel")
    }

    private func extractPotentialUsername(from input: String) -> String? {
        let cleanedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it's not a URL-like structure, assume it's a username
        if !isPotentialURL(cleanedInput) {
            return cleanedInput
        }

        // Try extracting from URL
        guard let url = URL(string: cleanedInput.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) else { return nil }
        guard url.host?.lowercased().contains("instagram.com") == true else { return nil }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // If there's exactly one path component, it's likely the username
        if pathComponents.count == 1 && !["stories", "p", "reel", "explore", "accounts", "s"].contains(pathComponents.first?.lowercased()) {
            return pathComponents.first
        }

        return nil // Cannot determine username from this input
    }

    private func isStoryURL(_ url: String) -> Bool {
        // Keep existing story/highlight detection
        return url.contains("/stories/") || StoryService.shared.isHighlightURL(url)
    }

    // Renamed and accepting input parameter
    private func handleStoryURL(input: String) {
        // Extract username specifically for stories/highlights
        if let username = extractStoryUsername(from: input) {
            print("🔍 Extracted story username: \(username)")
            Task {
                if !subscriptionManager.isUserSubscribed {
                    await MainActor.run {
                        interstitial.showAd(
                            from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
                        ) {
                            Task {
                                await loadStories(username: username)
                            }
                        }
                    }
                } else {
                    await loadStories(username: username)
                }
            }
        } else {
            print("❌ Failed to extract username from story URL: \(input)")
            errorMessage = NSLocalizedString("Invalid story or highlight URL format", comment: "Error for invalid story URL")
            showError = true
            isLoading = false
        }
    }

    // Helper to extract username specifically from story/highlight URLs
    private func extractStoryUsername(from url: String) -> String? {
        if StoryService.shared.isHighlightURL(url) {
            return url // Pass the full highlight URL to the service
        }
        // Original story URL extraction logic
        if url.contains("instagram.com/stories/") {
             let components = url.components(separatedBy: "/")
             if let storiesIndex = components.firstIndex(of: "stories"), storiesIndex + 1 < components.count {
                 let username = components[storiesIndex + 1]
                 // Ensure it's not trying to get highlights this way
                 if storiesIndex + 2 < components.count, components[storiesIndex + 2] == "highlights" {
                     return nil // Let highlight logic handle this
                 }
                 return username.isEmpty ? nil : username
             }
         }
         return nil
    }

    // Extracted story loading logic
    private func loadStories(username: String) async {
        videoViewModel.isLoading = true
        
        do {
            stories = try await StoryService.shared.fetchStories(username: username)
            
            if stories.isEmpty {
                errorMessage = NSLocalizedString("No active stories found for this user or the account is private", comment: "")
                showError = true
                print("⚠️ No stories found for username: \(username)")
            } else {
                print("✅ Found \(stories.count) stories for username: \(username)")
                withAnimation {
                    showStoryView = true
                }
            }
        } catch {
            print("❌ Error fetching stories: \(error.localizedDescription)")
            errorMessage = NSLocalizedString("Failed to fetch stories. Please try again.", comment: "")
            showError = true
        }
        
        videoViewModel.isLoading = false
        isLoading = false
        isUrlSearch = false
    }

    // Renamed for clarity
    private func performPostReelSearch() {
        // Ensure inputText is used for Post/Reel search
        videoViewModel.fetchVideoInfo(url: inputText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // Function to trigger navigation to the profile view
    private func navigateToUserProfile(username: String) {
        print("Navigating to profile for: \(username)")
        // Simulate ad display logic if needed, similar to stories/posts
        if !subscriptionManager.isUserSubscribed {
             interstitial.showAd(
                 from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
             ) {
                 // Set state variables AFTER ad potentially dismisses
                 self.selectedUsername = username
                 self.showUserProfileView = true
                 self.isLoading = false // Stop loading indicator
             }
         } else {
             // Premium user, navigate directly
             self.selectedUsername = username
             self.showUserProfileView = true
             self.isLoading = false // Stop loading indicator
         }
    }

    // Renamed performSearch to be more specific
    private func performSearch() {
        // This now specifically handles Post/Reel searches
        videoViewModel.fetchVideoInfo(url: inputText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// Kompakt Adım Görünümü
struct CompactStepView: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 5) {
            // Step numarası
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("igPurple"),
                                Color("igPink")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 20)
                
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("igPink"))
                .padding(.vertical, 2)
            
            // Başlık
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            // Açıklama
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 26)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 5)
    }
}

// Custom Segmented Control
struct CustomSegmentedControl: View {
    @Binding var selectedOption: SearchSectionView.SearchMode
    let options: [SearchSectionView.SearchMode]
    @State private var xOffset: CGFloat = 0
    @State private var buttonWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Arka plan
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // Seçili buton için arkaplan (kayar dikdörtgen)
            if buttonWidth > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("igPurple"),
                                Color("igPink"),
                                Color("igOrange")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: buttonWidth)
                    .offset(x: xOffset)
                    .padding(2)
                    .shadow(color: Color("igPink").opacity(0.3), radius: 5, x: 0, y: 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: xOffset)
            }
            
            // Butonlar
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    Button(action: {
                        selectedOption = option
                        withAnimation {
                            xOffset = CGFloat(index) * buttonWidth
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: option == .url ? "link.circle.fill" : "person.crop.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(option.displayName)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(selectedOption == option ? .white : Color.gray.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .contentShape(Rectangle())
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    // Her butonun genişliğini hesapla
                                    let width = geo.size.width
                                    if buttonWidth == 0 {
                                        buttonWidth = width
                                        
                                        // İlk yükleme için seçili butonun konumunu ayarla
                                        if let selectedIndex = options.firstIndex(of: selectedOption) {
                                            xOffset = CGFloat(selectedIndex) * width
                                        }
                                    }
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 0)
    }
}

// Kompakt Page Control
struct CompactPageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                if page == currentPage {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color("igPurple"), Color("igPink")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 12, height: 4)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}
