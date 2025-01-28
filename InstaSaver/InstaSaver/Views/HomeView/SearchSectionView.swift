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
    
    var body: some View {
        VStack(spacing: 15) {
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
                    .foregroundColor(.black)
                
                Text(NSLocalizedString("Download Reels, Stories & Video Posts", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            
            // URL Input Section
            VStack(spacing: 15) {
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
                        Image(systemName: "link")
                            .foregroundColor(Color("igPink"))
                            .font(.system(size: 18))
                            .padding(.leading, 20)
                        
                        TextField(NSLocalizedString("Paste Instagram URL here...", comment: ""), text: $inputText)
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
                                if !newValue.contains("http") {
                                    inputText = newValue.lowercased()
                                } else {
                                    inputText = newValue
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
                        showCustomAlert = true
                        return
                    }
                    
                    withAnimation {
                        searchCount += 1
                        videoViewModel.clearVideoData()
                        isUrlSearch = true
                        isLoading = true
                    }
                    
                    if isStoryURL(inputText) {
                        handleStoryURL()
                    } else {
                        if !subscriptionManager.isUserSubscribed && searchCount % 2 == 0 {
                            interstitial.showAd(
                                from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
                            ) {
                                performSearch()
                            }
                        } else {
                            performSearch()
                        }
                    }
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
            VStack(spacing: 10) {
                // Tutorial Pages with Step Numbers
                TabView(selection: $currentPage) {
                    // Step 1: Copy Link
                    StepCardView(
                        stepNumber: "1",
                        icon: "square.and.arrow.up",
                        title: NSLocalizedString("Copy Link", comment: ""),
                        description: NSLocalizedString("Open Instagram and copy video/story link", comment: "")
                    )
                    .tag(0)
                    
                    // Step 2: Paste
                    StepCardView(
                        stepNumber: "2",
                        icon: "doc.on.clipboard",
                        title: NSLocalizedString("Paste URL", comment: ""),
                        description: NSLocalizedString("Paste the link in the input box", comment: "")
                    )
                    .tag(1)
                    
                    // Step 3: Download
                    StepCardView(
                        stepNumber: "3",
                        icon: "arrow.down.circle",
                        title: NSLocalizedString("Download", comment: ""),
                        description: NSLocalizedString("Click download and save video", comment: "")
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 160)
                
                // Custom Page Control
                CustomPageControl(numberOfPages: 3, currentPage: $currentPage)
            }
            .padding(.top, 5)
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
    }
    
    private func isStoryURL(_ url: String) -> Bool {
        return url.contains("instagram.com/stories/")
    }
    
    private func extractUsername(from url: String) -> String? {
        // Instagram story URL pattern: https://www.instagram.com/stories/USERNAME/
        let components = url.components(separatedBy: "/")
        if let storiesIndex = components.firstIndex(of: "stories"),
           storiesIndex + 1 < components.count {
            let username = components[storiesIndex + 1]
            return username.isEmpty ? nil : username
        }
        // Handle direct username input with @ prefix
        if url.hasPrefix("@") {
            let username = String(url.dropFirst())
            return username.isEmpty ? nil : username
        }
        return nil
    }
    
    private func handleStoryURL() {
        if let username = extractUsername(from: inputText) {
            Task {
                do {
                    videoViewModel.isLoading = true  // Set loading state
                    stories = try await StoryService.shared.fetchStories(username: username)
                    if stories.isEmpty {
                        errorMessage = NSLocalizedString("No stories found for this user", comment: "")
                        showError = true
                    } else {
                        withAnimation {
                            showStoryView = true
                        }
                    }
                } catch {
                    errorMessage = NSLocalizedString("Failed to fetch stories", comment: "")
                    showError = true
                }
                videoViewModel.isLoading = false  // Reset loading state
                isLoading = false
                isUrlSearch = false
            }
        } else {
            errorMessage = NSLocalizedString("Invalid story URL or username", comment: "")
            showError = true
            videoViewModel.isLoading = false  // Reset loading state
            isLoading = false
            isUrlSearch = false
        }
    }
    
    private func performSearch() {
        videoViewModel.fetchVideoInfo(url: inputText)
    }
}

struct StepCardView: View {
    let stepNumber: String
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Step number with gradient background
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
                    .frame(width: 24, height: 24)
                
                Text(stepNumber)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(Color("igPink"))
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 180)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

struct CustomPageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                if page == currentPage {
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 16, height: 6)
                } else {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}
