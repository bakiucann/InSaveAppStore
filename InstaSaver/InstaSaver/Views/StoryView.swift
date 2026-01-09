import SwiftUI
import Photos
import StoreKit

struct StoryView: View {
    let stories: [InstagramStoryModel]
    let isFromHistory: Bool
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    private let interstitialAd = InterstitialAd()
    
    // State variables
    @State private var currentPage = 0
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var showPaywallView = false
    @State private var showAlert = false
    @State private var loadingTimer: Timer?
    @State private var downloadProgress = (current: 0, total: 0)
    @State private var showingBulkProgress = false
    @State private var downloadCount = 0
    @StateObject private var configManager = ConfigManager.shared
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var singleDownloadProgress: Double = 0
    @AppStorage("lastReviewRequestDate") private var lastReviewRequestDateDouble: Double = Date.distantPast.timeIntervalSince1970
    
    private var lastReviewRequestDate: Date {
        get { Date(timeIntervalSince1970: lastReviewRequestDateDouble) }
        set { lastReviewRequestDateDouble = newValue.timeIntervalSince1970 }
    }
    
    var body: some View {
        ZStack {
            // MARK: - Animated Background
            animatedBackground
            
            // Ana içerik
            VStack(spacing: 0) {
                // Custom Glassmorphic NavBar
                glassmorphicNavBar
                
                // Scroll View ve içindeki elemanlar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Story Preview Card
                        TabView(selection: $currentPage) {
                            ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                                GlassmorphicStoryPreviewCard(story: story)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                        
                        // Page Indicator
                        storyPageIndicator
                        
                        // Action Buttons
                        VStack(spacing: 10) {
                            if configManager.shouldShowDownloadButtons {
                                if !isFromHistory {
                                    // Bulk Download Button
                                    if subscriptionManager.isUserSubscribed {
                                        GlassmorphicActionButton(
                                            title: NSLocalizedString("Download Bulk", comment: ""),
                                            icon: "square.and.arrow.down.fill",
                                            isPrimary: true,
                                            action: {
                                                downloadAllStories()
                                            }
                                        )
                                    } else {
                                        GlassmorphicActionButton(
                                            title: NSLocalizedString("Download Bulk", comment: ""),
                                            icon: "square.and.arrow.down.fill",
                                            isPrimary: true,
                                            action: {
                                                showPaywallView = true
                                            }
                                        )
                                    }
                                }
                                
                                // Download Button
                                GlassmorphicActionButton(
                                    title: NSLocalizedString("Download", comment: ""),
                                    icon: "arrow.down.circle",
                                    isPrimary: false,
                                    action: {
                                        if let story = stories[safe: currentPage] {
                                            downloadStory(story)
                                        }
                                    }
                                )
                            }
                            
                            if !subscriptionManager.isUserSubscribed {
                                BannerAdView()
                                    .frame(height: 50)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            
            // Overlay Views
            if isLoading {
                if showingBulkProgress {
                    bulkDownloadLoadingOverlay
                } else {
                    loadingOverlay
                }
            }
            
            if showSuccessMessage { 
                successMessage 
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showPaywallView) {
            PaywallView()
        }
        .onAppear {
            configManager.reloadConfig()
        }
        .onDisappear {
            downloadManager.cancelAllDownloads()
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color("igPurple").opacity(0.02),
                    Color("igPink").opacity(0.03),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle orbs
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igPurple").opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: 100)
                    .blur(radius: 40)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igOrange").opacity(0.06), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .offset(x: geometry.size.width - 80, y: geometry.size.height - 200)
                    .blur(radius: 50)
            }
        }
    }
    
    // MARK: - Glassmorphic NavBar
    private var glassmorphicNavBar: some View {
        HStack {
            // Back button
            backButton
            
            Spacer()
            
            // Title with gradient
            Text(NSLocalizedString("Stories", comment: ""))
                .font(.system(size: 17, weight: .bold))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            
            Spacer()
            
            // Placeholder for symmetry
            Circle()
                .fill(Color.clear)
                .frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("igPurple").opacity(0.03),
                                Color("igPink").opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color("igPink").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
            }
        }
    }
    
    // MARK: - Story Page Indicator
    private var storyPageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<stories.count, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? Color("igPink") : Color.gray.opacity(0.3))
                    .frame(width: currentPage == index ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: currentPage)
                    .onTapGesture {
                        currentPage = index
                    }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.white.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: singleDownloadProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color("igPurple"), Color("igPink")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                
                    Text("\(Int(singleDownloadProgress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                }
                
                Text(NSLocalizedString("Downloading...", comment: ""))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
        }
    }
    
    // MARK: - Bulk Download Loading Overlay
    private var bulkDownloadLoadingOverlay: some View {
        ZStack {
            Color.white.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: Double(downloadProgress.current) / Double(max(downloadProgress.total, 1)))
                        .stroke(
                            LinearGradient(
                                colors: [Color("igPurple"), Color("igPink")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(downloadProgress.current)")
                            .font(.system(size: 16, weight: .bold))
                            .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                        Text("/\(downloadProgress.total)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(NSLocalizedString("Downloading Stories...", comment: ""))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
        }
    }
    
    // MARK: - Success Message
    private var successMessage: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(NSLocalizedString("Story saved!", comment: ""))
                    .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color("igPurple"), Color("igPink")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            .shadow(color: Color("igPink").opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Helper Functions (unchanged)
    
    private func startLoading() {
        isLoading = true
        singleDownloadProgress = 0
        loadingTimer?.invalidate()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
            if isLoading {
                showAlert = true
                isLoading = false
            }
        }
    }
    
    private func stopLoading() {
        isLoading = false
        loadingTimer?.invalidate()
    }
    
    private func downloadStory(_ story: InstagramStoryModel) {
        if !subscriptionManager.isUserSubscribed {
            if !CoreDataManager.shared.canDownloadMore() {
                showPaywallView = true
                return
            }
        }
        
        startDownloadProcess(story)
    }
    
    private func startDownloadProcess(_ story: InstagramStoryModel) {
        startLoading()
        
        let isPhoto = story.type != "video"
        downloadManager.downloadContent(
            urlString: story.url,
            isPhoto: isPhoto
        ) { progress in
            DispatchQueue.main.async {
                self.singleDownloadProgress = progress
            }
        } completion: { result in
            DispatchQueue.main.async {
                self.stopLoading()
                
                switch result {
                case .success(let fileURL):
                    if !self.subscriptionManager.isUserSubscribed {
                        CoreDataManager.shared.incrementDailyDownloadCount()
                    }
                    
                    if isPhoto {
                        self.saveImageToGallery(from: fileURL)
                    } else {
                        self.saveVideoToGallery(from: fileURL)
                    }
                    
                    CoreDataManager.shared.saveStoryInfo(story: story)
                    
                case .failure(let error):
                    print("❌ İndirme hatası: \(error.localizedDescription)")
                    self.showAlert = true
                }
            }
        }
    }
    
    private func downloadAllStories() {
        guard subscriptionManager.isUserSubscribed else {
            showPaywallView = true
            return
        }
        
        startLoading()
        showingBulkProgress = true
        downloadProgress = (0, stories.count)
        
        Task {
            for (index, story) in stories.enumerated() {
                await withCheckedContinuation { continuation in
                    let isPhoto = story.type != "video"
                    
                    downloadManager.downloadContent(
                        urlString: story.url,
                        isPhoto: isPhoto
                    ) { progress in
                        // Single file progress - not shown
                    } completion: { result in
                        DispatchQueue.main.async {
                            self.downloadProgress.current = index + 1
                            
                            switch result {
                            case .success(let fileURL):
                                CoreDataManager.shared.saveStoryInfo(story: story)
                                
                                Task {
                                    if isPhoto {
                                        await self.saveImageToGalleryAsync(from: fileURL)
                                    } else {
                                        await self.saveVideoToGalleryAsync(from: fileURL)
                                    }
                                    continuation.resume()
                                }
                                
                            case .failure(let error):
                                print("❌ Bulk indirme hatası: \(error.localizedDescription)")
                                continuation.resume()
                            }
                        }
                    }
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            
            DispatchQueue.main.async {
                stopLoading()
                showingBulkProgress = false
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessMessage = false
                }
            }
        }
    }
    
    private func saveVideoToGallery(from fileURL: URL, isBulkDownload: Bool = false) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL: fileURL, options: nil)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        if !isBulkDownload {
                            self.downloadCount += 1
                            showSuccessMessage = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                                    let topVC = self.findTopViewController(rootVC)
                                    self.interstitialAd.showAd(from: topVC) {
                                        print("✅ Ad shown after successful video download")
                                    }
                                }
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                
                                let calendar = Calendar.current
                                if !calendar.isDateInToday(self.lastReviewRequestDate) {
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        SKStoreReviewController.requestReview(in: windowScene)
                                        self.lastReviewRequestDateDouble = Date().timeIntervalSince1970
                                    }
                                }
                            }
                        }
                    } else {
                        if let error = error {
                            print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func saveImageToGallery(from fileURL: URL, isBulkDownload: Bool = false) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, fileURL: fileURL, options: nil)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        if !isBulkDownload {
                            self.downloadCount += 1
                            showSuccessMessage = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                                    let topVC = self.findTopViewController(rootVC)
                                    self.interstitialAd.showAd(from: topVC) {
                                        print("✅ Ad shown after successful image download")
                                    }
                                }
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                            }
                        }
                    } else {
                        if let error = error {
                            print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func saveVideoToGalleryAsync(from fileURL: URL) async {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    continuation.resume()
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: fileURL, options: nil)
                }) { success, error in
                    if !success {
                        print("Error saving to gallery: \(String(describing: error))")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func saveImageToGalleryAsync(from fileURL: URL) async {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    continuation.resume()
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, fileURL: fileURL, options: nil)
                }) { success, error in
                    if !success {
                        print("Error saving to gallery: \(String(describing: error))")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func findTopViewController(_ viewController: UIViewController) -> UIViewController {
        if let presentedVC = viewController.presentedViewController {
            return findTopViewController(presentedVC)
        }
        
        if let navigationController = viewController as? UINavigationController {
            if let visibleVC = navigationController.visibleViewController {
                return findTopViewController(visibleVC)
            }
            return viewController
        }
        
        if let tabBarController = viewController as? UITabBarController {
            if let selectedVC = tabBarController.selectedViewController {
                return findTopViewController(selectedVC)
            }
            return viewController
        }
        
        return viewController
    }
    
    private func setupSubscriptionObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SubscriptionChanged"),
            object: nil,
            queue: .main
        ) { _ in
            print("Abonelik durumu değişti, StoryView SubscriptionManager'ı güncelliyorum")
        }
    }
}

// MARK: - Glassmorphic Story Preview Card
struct GlassmorphicStoryPreviewCard: View {
    let story: InstagramStoryModel
    @State private var imageData: Data?
    
    var body: some View {
        VStack {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: UIScreen.main.bounds.width - 32)
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color("igPink").opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color("igPurple").opacity(0.15), radius: 20, x: 0, y: 10)
            } else {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.white.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("igPink")))
                            .scaleEffect(1.2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let url = URL(string: story.thumbnailUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    self.imageData = data
                }
            }
        }.resume()
    }
}

// MARK: - Legacy Components (kept for compatibility)

struct StoryPreviewCard: View {
    let story: InstagramStoryModel
    @State private var imageData: Data?
    
    var body: some View {
        VStack {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color("igPurple").opacity(0.3),
                                        Color("igPink").opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            } else {
                ProgressView()
                    .frame(height: UIScreen.main.bounds.height * 0.6)
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let url = URL(string: story.thumbnailUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    self.imageData = data
                }
            }
        }.resume()
    }
}

struct CustomPageIndicator: UIViewRepresentable {
    var numberOfPages: Int
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfPages
        control.currentPage = currentPage
        control.currentPageIndicatorTintColor = UIColor(Color("igPink"))
        control.pageIndicatorTintColor = UIColor(Color("igPurple").opacity(0.3))
        return control
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.currentPage = currentPage
    }
}

extension View {
    func customPageIndicator(numberOfPages: Int, currentPage: Binding<Int>) -> some View {
        self.overlay(
            CustomPageIndicator(numberOfPages: numberOfPages, currentPage: currentPage)
                .padding(.bottom, -25),
            alignment: .bottom
        )
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
