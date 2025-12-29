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
    
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
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
        ZStack {
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
                if configManager.shouldShowDownloadButtons {
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
                    
                    withAnimation {
                        searchCount += 1
                        videoViewModel.clearVideoData()
                        isUrlSearch = true
                        isLoading = true
                    }

                    // Kullanıcı adı veya URL kontrolü
                    switch searchMode {
                    case .username:
                        // Username modunda URL kontrolü
                        if inputText.contains("instagram.com") || inputText.contains("http") || inputText.contains("/") {
                            errorMessage = NSLocalizedString("Please enter only the username without URL", comment: "")
                            showError = true
                            isLoading = false
                            isUrlSearch = false
                            return
                        }
                        handleStoryURL()
                        
                    case .url:
                        // URL kontrolü
                        if !inputText.contains("instagram.com") {
                            errorMessage = NSLocalizedString("Please enter a valid Instagram URL", comment: "")
                            showError = true
                            isLoading = false
                            isUrlSearch = false
                            return
                        }
                        
                        // URL formatını düzenle
                        if !inputText.hasPrefix("http://") && !inputText.hasPrefix("https://") {
                            inputText = "https://www." + inputText
                        }
                        
                        if isStoryURL(inputText) {
                            handleStoryURL()
                        } else if let profileUsername = extractProfileUsername(from: inputText) {
                            // It's a profile URL, load stories
                            print("🔍 Detected profile URL for username: \(profileUsername)")
                            // HEMEN story'leri yükle (reklam öncesi değil)
                            Task {
                                await loadStories(username: profileUsername)
                            }
                        } else {
                            // It's likely a post/reel URL
                            // HEMEN aramayı başlat (reklam öncesi değil)
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
        .onChange(of: configManager.shouldShowDownloadButtons) { newValue in
            // Segmented control gizlenecekse URL mode'unu ayarla
            if !newValue {
                // Default olarak URL mode'unu ayarla
                searchMode = .url
            }
        }
        
        // Ad Loading Overlay - Reklam yüklenirken tüm ekranı kaplar
        if interstitial.isLoadingAd {
            AdLoadingOverlayView()
                .zIndex(999)
        }
        }
    }
    
    private func isStoryURL(_ url: String) -> Bool {
        return url.contains("instagram.com/stories/") || StoryService.shared.isHighlightURL(url)
    }
    
    private func extractProfileUsername(from url: String) -> String? {
        // Ensure it's an instagram URL but not a story/highlight/post/reel
        guard url.contains("instagram.com") else { return nil }
        guard !url.contains("/p/") && !url.contains("/reel/") && !url.contains("/reels/") && !url.contains("/tv/") && !url.contains("/stories/") && !url.contains("/s/") else {
            return nil // It's likely a post, reel, story, or highlight share URL
        }

        // Pattern: instagram.com/username or instagram.com/username?params
        let components = url.components(separatedBy: "instagram.com/")
        guard components.count > 1 else { return nil }

        let pathPart = components[1]
        // Take the part before the first '/' or '?'
        let usernamePart = pathPart.components(separatedBy: CharacterSet(charactersIn: "/?")).first ?? pathPart

        return usernamePart.isEmpty ? nil : usernamePart.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractUsername(from url: String) -> String? {
        // Highlight URL kontrolü - bu durumda direkt URL'i döndür
        if StoryService.shared.isHighlightURL(url) {
            return url
        }
        
        // SearchMode.username seçildiğinde, direkt kullanıcı adını döndür
        if searchMode == .username {
            return url.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Direkt kullanıcı adı girişi
        if !url.contains("/") && !url.contains(".") {
            return url.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Instagram story URL pattern: https://www.instagram.com/stories/USERNAME/
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
            // HEMEN story'leri yükle (reklam öncesi değil)
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
    
    // Story'leri yükleyip gösteren yardımcı fonksiyon
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
                
                // Başarılı arama sonrası reklam göster (POST-action)
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
            
            // Map errors to user-friendly messages
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost:
                    errorMessage = NSLocalizedString("error_connection_timeout", comment: "")
                default:
                    // All other errors (including 4xx/5xx) map to private account message
                    errorMessage = NSLocalizedString("error_private_or_server", comment: "")
                }
            } else {
                // Non-URLError errors (decoding, etc.) - map to private account message
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
        
        // Başarılı arama sonrası reklam göster (POST-action)
        // VideoViewModel'de video set edildiğinde reklam gösterilecek
        // HomeView'da onChange ile yakalanacak
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
