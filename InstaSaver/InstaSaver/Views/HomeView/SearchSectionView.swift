//
//  SearchSectionView.swift
//  InstaSaver
//
//  Glassmorphic UI Design - Compact Version - iOS 14+ Compatible
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
    @State private var isInputFocused = false
    @State private var animateGradient = false
    @State private var currentPage = 0
    @State private var showStoryView = false
    @State private var stories: [InstagramStoryModel] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchMode: SearchMode = .url
    @State private var pulseAnimation = false
    @State private var floatingIconOffset: CGFloat = 0
    @StateObject private var configManager = ConfigManager.shared
    
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    let interstitial: InterstitialAd
    @ObservedObject var videoViewModel: VideoViewModel
    
    // Instagram Gradient
    private let instagramGradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    enum SearchMode: String, CaseIterable {
        case url = "URL"
        case username = "username"
        
        var displayName: String {
            switch self {
            case .url: return "URL"
            case .username: return NSLocalizedString("Username", comment: "")
            }
        }
        
        var emptyInputError: String {
            switch self {
            case .url: return NSLocalizedString("Please enter a valid Instagram URL", comment: "")
            case .username: return NSLocalizedString("Please enter an Instagram username", comment: "")
            }
        }
        
        var icon: String {
            switch self {
            case .url: return "link"
            case .username: return "at"
            }
        }
        
        var placeholder: String {
            switch self {
            case .url: return NSLocalizedString("Paste Instagram URL here...", comment: "")
            case .username: return NSLocalizedString("Enter Instagram username...", comment: "")
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // MARK: - Compact Hero Section
                heroSection
                
                // MARK: - Glassmorphic Search Card
                glassmorphicSearchCard
                
                // MARK: - Compact Tutorial Cards
                tutorialCarousel
            }
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
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    floatingIconOffset = 6
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
            .onChange(of: configManager.shouldShowDownloadButtons) { newValue in
                if !newValue {
                    searchMode = .url
                }
            }
            
            // Ad Loading Overlay
            if interstitial.isLoadingAd {
                AdLoadingOverlayView()
                    .zIndex(999)
            }
        }
    }
    
    // MARK: - Compact Hero Section
    private var heroSection: some View {
        VStack(spacing: 10) {
            // Compact floating download icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("igPink").opacity(0.35),
                                Color("igPurple").opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 18,
                            endRadius: 52
                        )
                    )
                    .frame(width: 105, height: 105)
                    .scaleEffect(pulseAnimation ? 1.08 : 0.92)
                
                // Main icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.8), Color("igPink").opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color("igPink").opacity(0.25), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "arrow.down.to.line.compact")
                        .font(.system(size: 28, weight: .bold))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
                }
                .offset(y: floatingIconOffset)
            }
            
            // Compact title
            VStack(spacing: 4) {
                Text(NSLocalizedString("InSave for Instagram", comment: ""))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
                
                Text(NSLocalizedString("Download Reels, Stories & Video Posts", comment: ""))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Compact Glassmorphic Search Card
    private var glassmorphicSearchCard: some View {
        VStack(spacing: 14) {
            // Search Mode Selector
            if configManager.shouldShowDownloadButtons {
                GlassmorphicSegmentedControl(
                    selectedMode: $searchMode,
                    modes: SearchMode.allCases
                )
                .onChange(of: searchMode) { _ in
                    inputText = ""
                    showPasteButton = true
                    isInputFocused = false
                }
            }
            
            // Compact Input Field
            glassmorphicInputField
            
            // Compact Download Button
            downloadButton
        }
        .padding(16)
        .background(glassmorphicCardBackground)
    }
    
    // MARK: - Glassmorphic Card Background
    private var glassmorphicCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.88), Color.white.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("igPurple").opacity(0.03),
                            Color("igPink").opacity(0.02),
                            Color("igOrange").opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.15), Color.white.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color("igPurple").opacity(0.06), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Compact Glassmorphic Input Field
    private var glassmorphicInputField: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("igPurple").opacity(0.1), Color("igPink").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: searchMode.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            }
            
            // Text Field
            TextField(searchMode.placeholder, text: $inputText)
                .font(.system(size: 15, weight: .medium))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: inputText) { newValue in
                    showPasteButton = newValue.isEmpty
                    withAnimation(.spring(response: 0.3)) {
                        isInputFocused = !newValue.isEmpty
                    }
                }
            
            // Clear / Paste Button
            if !inputText.isEmpty {
                Button(action: { inputText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                pasteButton
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isInputFocused
                                ? LinearGradient(
                                    colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                            lineWidth: isInputFocused ? 1.5 : 1
                        )
                )
        )
        .animation(.spring(response: 0.3), value: isInputFocused)
    }
    
    // MARK: - Compact Paste Button
    private var pasteButton: some View {
        Button(action: {
            if let clipboardText = UIPasteboard.general.string {
                withAnimation(.spring()) {
                    inputText = clipboardText
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 11, weight: .semibold))
                Text(NSLocalizedString("Paste", comment: ""))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(instagramGradient)
            )
            .shadow(color: Color("igPink").opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Compact Download Button
    private var downloadButton: some View {
        Button(action: handleDownloadAction) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(NSLocalizedString("Download Now", comment: ""))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(instagramGradient)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color("igPurple").opacity(0.25), radius: 10, x: 0, y: 5)
            .shadow(color: Color("igPink").opacity(0.15), radius: 6, x: 0, y: 3)
            .scaleEffect(isInputFocused ? 1.01 : 1.0)
            .animation(.spring(response: 0.3), value: isInputFocused)
        }
    }
    
    // MARK: - Compact Tutorial Carousel
    private var tutorialCarousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $currentPage) {
                ForEach(0..<3) { index in
                    CompactTutorialCard(
                        step: index + 1,
                        icon: tutorialIcons[index],
                        title: tutorialTitles[index],
                        description: tutorialDescriptions[index]
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 100)
            
            // Compact page indicator
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(currentPage == index ? Color("igPink") : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
        }
    }
    
    // Tutorial Data
    private let tutorialIcons = ["square.and.arrow.up.fill", "doc.on.clipboard.fill", "arrow.down.circle.fill"]
    private let tutorialTitles = [
        NSLocalizedString("Copy Link", comment: ""),
        NSLocalizedString("Paste URL/Username", comment: ""),
        NSLocalizedString("Download", comment: "")
    ]
    private let tutorialDescriptions = [
        NSLocalizedString("Open Instagram and copy video/story link", comment: ""),
        NSLocalizedString("Paste the link or enter username in the box", comment: ""),
        NSLocalizedString("Click download and save to your gallery", comment: "")
    ]
    
    // MARK: - Actions
    private func handleDownloadAction() {
        guard !inputText.isEmpty else {
            errorMessage = searchMode.emptyInputError
            showError = true
            return
        }
        
        withAnimation {
            searchCount += 1
            videoViewModel.clearVideoData()
            isUrlSearch = true
            isLoading = true
        }
        
        switch searchMode {
        case .username:
            if inputText.contains("instagram.com") || inputText.contains("http") || inputText.contains("/") {
                errorMessage = NSLocalizedString("Please enter only the username without URL", comment: "")
                showError = true
                isLoading = false
                isUrlSearch = false
                return
            }
            handleStoryURL()
            
        case .url:
            if !inputText.contains("instagram.com") {
                errorMessage = NSLocalizedString("Please enter a valid Instagram URL", comment: "")
                showError = true
                isLoading = false
                isUrlSearch = false
                return
            }
            
            if !inputText.hasPrefix("http://") && !inputText.hasPrefix("https://") {
                inputText = "https://www." + inputText
            }
            
            if isStoryURL(inputText) {
                handleStoryURL()
            } else if let profileUsername = extractProfileUsername(from: inputText) {
                print("🔍 Detected profile URL for username: \(profileUsername)")
                Task {
                    await loadStories(username: profileUsername)
                }
            } else {
                performSearch()
            }
        }
    }
    
    private func isStoryURL(_ url: String) -> Bool {
        return url.contains("instagram.com/stories/") || StoryService.shared.isHighlightURL(url)
    }
    
    private func extractProfileUsername(from url: String) -> String? {
        guard url.contains("instagram.com") else { return nil }
        guard !url.contains("/p/") && !url.contains("/reel/") && !url.contains("/reels/") && !url.contains("/tv/") && !url.contains("/stories/") && !url.contains("/s/") else {
            return nil
        }
        
        let components = url.components(separatedBy: "instagram.com/")
        guard components.count > 1 else { return nil }
        
        let pathPart = components[1]
        let usernamePart = pathPart.components(separatedBy: CharacterSet(charactersIn: "/?")).first ?? pathPart
        
        return usernamePart.isEmpty ? nil : usernamePart.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractUsername(from url: String) -> String? {
        if StoryService.shared.isHighlightURL(url) {
            return url
        }
        
        if searchMode == .username {
            return url.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if !url.contains("/") && !url.contains(".") {
            return url.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if url.contains("instagram.com/stories/") && !url.contains("/highlights/") {
            let components = url.components(separatedBy: "/")
            if let storiesIndex = components.firstIndex(of: "stories"),
               storiesIndex + 1 < components.count {
                let username = components[storiesIndex + 1]
                return username.isEmpty ? nil : username
            }
        }
        
        return nil
    }
    
    private func handleStoryURL() {
        if let username = extractUsername(from: inputText) {
            print("🔍 Extracted username: \(username)")
            Task {
                await loadStories(username: username)
            }
        } else {
            print("❌ Failed to extract username from: \(inputText)")
            errorMessage = NSLocalizedString("Invalid username format", comment: "")
            showError = true
            videoViewModel.isLoading = false
            isLoading = false
            isUrlSearch = false
        }
    }
    
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
                
                await MainActor.run {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                            self.interstitial.showAd(from: rootViewController) {
                                print("✅ Ad shown after successful story load")
                            }
                        }
                    }
                }
                
                withAnimation {
                    showStoryView = true
                }
            }
        } catch {
            print("❌ Error fetching stories: \(error.localizedDescription)")
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost:
                    errorMessage = NSLocalizedString("error_connection_timeout", comment: "")
                default:
                    errorMessage = NSLocalizedString("error_private_or_server", comment: "")
                }
            } else {
                errorMessage = NSLocalizedString("error_private_or_server", comment: "")
            }
            
            showError = true
        }
        
        videoViewModel.isLoading = false
        isLoading = false
        isUrlSearch = false
    }
    
    private func performSearch() {
        videoViewModel.fetchVideoInfo(url: inputText)
    }
}

// MARK: - Gradient Foreground Extension (iOS 14 Compatible)
extension View {
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .mask(self)
    }
}

// MARK: - Compact Glassmorphic Segmented Control
struct GlassmorphicSegmentedControl: View {
    @Binding var selectedMode: SearchSectionView.SearchMode
    let modes: [SearchSectionView.SearchMode]
    
    var body: some View {
        GeometryReader { geometry in
            let width = (geometry.size.width - 6) / CGFloat(modes.count)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width - 4)
                    .padding(3)
                    .offset(x: CGFloat(modes.firstIndex(of: selectedMode) ?? 0) * width)
                    .shadow(color: Color("igPink").opacity(0.25), radius: 6, x: 0, y: 3)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedMode)
                
                HStack(spacing: 0) {
                    ForEach(modes, id: \.self) { mode in
                        Button(action: { selectedMode = mode }) {
                            HStack(spacing: 6) {
                                Image(systemName: mode == .url ? "link.circle.fill" : "at.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(mode.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(selectedMode == mode ? .white : .gray)
                            .frame(width: width, height: 40)
                        }
                    }
                }
            }
        }
        .frame(height: 44)
    }
}

// MARK: - Compact Tutorial Card
struct CompactTutorialCard: View {
    let step: Int
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 14) {
            // Compact step icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igPink").opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white, Color("igPink").opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color("igPink").opacity(0.15), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 1) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                    
                    Text("\(step)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color("igPink"))
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black.opacity(0.85))
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), Color.white.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.8), Color("igPink").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 4)
    }
}
