import SwiftUI
import Photos

struct StoryView: View {
    let stories: [InstagramStoryModel]
    let isFromHistory: Bool
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager()
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
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.white,
                    Color("igPurple").opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Story Preview Card
                    TabView(selection: $currentPage) {
                        ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                            StoryPreviewCard(story: story)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                    .customPageIndicator(numberOfPages: stories.count, currentPage: $currentPage)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if !isFromHistory {
                            if subscriptionManager.isUserSubscribed {
                                ActionButton(
                                    title: NSLocalizedString("Download Bulk", comment: ""),
                                    icon: "square.and.arrow.down.fill",
                                    gradient: [Color("igPurple"), Color("igPink")],
                                    action: {
                                        downloadAllStories()
                                    }
                                )
                            } else {
                                ActionButton(
                                    title: NSLocalizedString("Download Bulk", comment: ""),
                                    icon: "square.and.arrow.down.fill",
                                    gradient: [Color("igPurple"), Color("igPink")],
                                    action: {
                                        showPaywallView = true
                                    }
                                )
                            }
                        }
                        
                        ActionButton(
                            title: NSLocalizedString("Download", comment: ""),
                            icon: "arrow.down.circle",
                            gradient: [Color("igPurple").opacity(0.8), Color("igPink").opacity(0.8)],
                            action: {
                                if let story = stories[safe: currentPage] {
                                    downloadStory(story)
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    if !subscriptionManager.isUserSubscribed {
                        BannerAdView()
                            .frame(height: 50)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            
            // Overlay Views
            if isLoading {
                if showingBulkProgress {
                    bulkDownloadLoadingOverlay
                } else {
                    loadingOverlay
                }
            }
            if showSuccessMessage { successMessage }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            ToolbarItem(placement: .principal) {
                toolbarTitle
            }
        }
        .fullScreenCover(isPresented: $showPaywallView) {
            PaywallView()
        }
    }
    
    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("igPurple"))
            }
        }
    }
    
    private var toolbarTitle: some View {
        Text(NSLocalizedString("Stories", comment: ""))
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.black.opacity(0.9))
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.white.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .accentColor(.white)
                    .foregroundColor(.white)
                
                Text("Downloading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
    
    private var bulkDownloadLoadingOverlay: some View {
        ZStack {
            Color.white.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .accentColor(.white)
                    .foregroundColor(.white)
                
                Text("Downloading Stories...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(downloadProgress.current)/\(downloadProgress.total)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
    
    private var successMessage: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            Text("Story saved successfully!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color("igPurple"), Color("igPink")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .transition(.opacity)
    }
    
    private func startLoading() {
        isLoading = true
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
        
        startLoading()
        downloadAndSaveVideo(from: story.url, isBulkDownload: false)
        CoreDataManager.shared.saveStoryInfo(story: story)
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
                // Her story için indirme işlemi
                await withCheckedContinuation { continuation in
                    guard let url = URL(string: story.url) else {
                        continuation.resume()
                        return
                    }
                    
                    URLSession.shared.downloadTask(with: url) { location, response, error in
                        if let error = error {
                            print("Error downloading: \(error.localizedDescription)")
                            continuation.resume()
                            return
                        }
                        
                        guard let location = location else {
                            print("No file location returned from server.")
                            continuation.resume()
                            return
                        }
                        
                        do {
                            let isVideo = story.type == "video"
                            let fileExtension = isVideo ? "mp4" : "jpg"
                            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent("downloadedStory_\(index).\(fileExtension)")
                            
                            if FileManager.default.fileExists(atPath: tmpUrl.path) {
                                try FileManager.default.removeItem(at: tmpUrl)
                            }
                            try FileManager.default.moveItem(at: location, to: tmpUrl)
                            
                            // Gallery'ye kaydet
                            Task {
                                if isVideo {
                                    await self.saveVideoToGalleryAsync(from: tmpUrl)
                                } else {
                                    await self.saveImageToGalleryAsync(from: tmpUrl)
                                }
                                CoreDataManager.shared.saveStoryInfo(story: story)
                                
                                DispatchQueue.main.async {
                                    self.downloadProgress.current = index + 1
                                }
                                continuation.resume()
                            }
                        } catch {
                            print("File handling error: \(error.localizedDescription)")
                            continuation.resume()
                        }
                    }.resume()
                }
                
                // Her indirme arasında kısa bir bekleme
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
    
    private func downloadAndSaveVideo(from urlString: String, isBulkDownload: Bool = false) {
        guard let url = URL(string: urlString) else {
            stopLoading()
            return
        }
        
        URLSession.shared.downloadTask(with: url) { location, response, error in
            if let error = error {
                print("Error downloading: \(error.localizedDescription)")
                DispatchQueue.main.async { stopLoading() }
                return
            }
            
            guard let location = location else {
                print("No file location returned from server.")
                DispatchQueue.main.async { stopLoading() }
                return
            }
            
            do {
                let isVideo = stories[currentPage].type == "video"
                let fileExtension = isVideo ? "mp4" : "jpg"
                let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent("downloadedStory.\(fileExtension)")
                
                if FileManager.default.fileExists(atPath: tmpUrl.path) {
                    try FileManager.default.removeItem(at: tmpUrl)
                }
                try FileManager.default.moveItem(at: location, to: tmpUrl)
                
                DispatchQueue.main.async {
                    if !isBulkDownload {
                        stopLoading()
                    }
                    if !subscriptionManager.isUserSubscribed {
                        CoreDataManager.shared.incrementDailyDownloadCount()
                    }
                    if isVideo {
                        saveVideoToGallery(from: tmpUrl, isBulkDownload: isBulkDownload)
                    } else {
                        saveImageToGallery(from: tmpUrl, isBulkDownload: isBulkDownload)
                    }
                }
            } catch {
                print("File handling error: \(error.localizedDescription)")
                DispatchQueue.main.async { stopLoading() }
            }
        }.resume()
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
                            showSuccessMessage = true
                            
                            // Success message'ı 2 saniye göster, sonra reklamı göster
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                
                                // Success message kapandıktan 0.5 saniye sonra reklamı göster
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if !subscriptionManager.isUserSubscribed {
                                        if let windowScene = UIApplication.shared.windows.first?.rootViewController {
                                            let presenter = windowScene.presentedViewController ?? windowScene
                                            if presenter.presentedViewController == nil {
                                                interstitialAd.showAd(from: presenter) {
                                                    print("Ad shown successfully")
                                                }
                                            }
                                        }
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
                            showSuccessMessage = true
                            
                            // Success message'ı 2 saniye göster, sonra reklamı göster
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                
                                // Success message kapandıktan 0.5 saniye sonra reklamı göster
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if !subscriptionManager.isUserSubscribed {
                                        if let windowScene = UIApplication.shared.windows.first?.rootViewController {
                                            let presenter = windowScene.presentedViewController ?? windowScene
                                            if presenter.presentedViewController == nil {
                                                interstitialAd.showAd(from: presenter) {
                                                    print("Ad shown successfully")
                                                }
                                            }
                                        }
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
}

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

// Customize TabView's page indicator
struct CustomPageIndicator: UIViewRepresentable {
    var numberOfPages: Int
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfPages
        control.currentPage = currentPage
        
        // Customize colors
        control.currentPageIndicatorTintColor = UIColor(Color("igPink"))
        control.pageIndicatorTintColor = UIColor(Color("igPurple").opacity(0.3))
        
        return control
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.currentPage = currentPage
    }
}

// Add this modifier to the TabView
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