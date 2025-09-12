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
            
            // Ana içerik
            VStack(spacing: 0) {
                // Custom NavBar
                HStack {
                    // Back button
                    backButton
                    
                    Spacer()
                    
                    // Title
                    toolbarTitle
                    
                    Spacer()
                    
                    // Sağ tarafa boşluk bırakmak için
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .zIndex(1)
                
                // Scroll View ve içindeki elemanlar
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
                            if Locale.current.languageCode != "en" || configManager.shouldShowDownloadButtons {
                                if !isFromHistory {
                                    // Bulk Download Button
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
                                
                                // Download Button
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
                            
                            if !subscriptionManager.isUserSubscribed {
                                BannerAdView()
                                    .frame(height: 50)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
            }
            
            // Overlay Views - Tüm ekranı kaplamalı
            if isLoading {
                if showingBulkProgress {
                    bulkDownloadLoadingOverlay
                } else {
                    loadingOverlay
                }
            }
            if showSuccessMessage { successMessage }
        }
        .navigationBarHidden(true) // Navigation bar'ı gizle
        .fullScreenCover(isPresented: $showPaywallView) {
            PaywallView()
        }
        .onAppear {
            configManager.reloadConfig()
        }
        .onDisappear {
            // İndirmeleri iptal et
            downloadManager.cancelAllDownloads()
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
            
            VStack(spacing: 12) {
                ProgressView(value: singleDownloadProgress)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("igPurple")))
                    .scaleEffect(1.5)
                    .padding(.bottom, 8)
                
                Text("Downloading")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("igPurple"))
                
                Text("\(Int(singleDownloadProgress * 100))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color("igPurple"))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    private var bulkDownloadLoadingOverlay: some View {
        ZStack {
            Color.white.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView(value: Double(downloadProgress.current) / Double(downloadProgress.total))
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("igPurple")))
                    .scaleEffect(1.5)
                    .padding(.bottom, 8)
                
                Text("Downloading Stories...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("igPurple"))
                
                Text("\(downloadProgress.current)/\(downloadProgress.total)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("igPurple"))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
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
            
            // Premium kullanıcı değilse, içerik ne olursa olsun reklam göster
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                interstitialAd.showAd(from: rootViewController) {
                    // Reklam gösterildikten sonra indirme işlemine başla
                    startDownloadProcess(story)
                }
            }
        } else {
            // Premium kullanıcı ise direkt indirme başlat
            startDownloadProcess(story)
        }
    }
    
    private func startDownloadProcess(_ story: InstagramStoryModel) {
        startLoading()
        
        // DownloadManager'ı kullanarak indirme işlemi
        let isPhoto = story.type != "video"
        downloadManager.downloadContent(
            urlString: story.url,
            isPhoto: isPhoto
        ) { progress in
            // İlerleme güncellemesi
            DispatchQueue.main.async {
                self.singleDownloadProgress = progress
            }
        } completion: { result in
            DispatchQueue.main.async {
                self.stopLoading()
                
                switch result {
                case .success(let fileURL):
                    // İndirme başarılı, galeriye kaydet
                    if !self.subscriptionManager.isUserSubscribed {
                        CoreDataManager.shared.incrementDailyDownloadCount()
                    }
                    
                    if isPhoto {
                        self.saveImageToGallery(from: fileURL)
                    } else {
                        self.saveVideoToGallery(from: fileURL)
                    }
                    
                    // Story bilgilerini Core Data'ya kaydet
                    CoreDataManager.shared.saveStoryInfo(story: story)
                    
                case .failure(let error):
                    // Hata durumu
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
        
        // Toplu indirme işlemi
        Task {
            for (index, story) in stories.enumerated() {
                await withCheckedContinuation { continuation in
                    let isPhoto = story.type != "video"
                    
                    downloadManager.downloadContent(
                        urlString: story.url,
                        isPhoto: isPhoto
                    ) { progress in
                        // Tek dosya indirme ilerlemesi - göstermiyoruz
                    } completion: { result in
                        DispatchQueue.main.async {
                            // İndirilen dosya sayısını artır
                            self.downloadProgress.current = index + 1
                            
                            switch result {
                            case .success(let fileURL):
                                // Story bilgilerini kaydet
                                CoreDataManager.shared.saveStoryInfo(story: story)
                                
                                // Galeriye kaydet
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
                            // İndirme sayacını artır
                            self.downloadCount += 1
                            
                            showSuccessMessage = true
                            // Check if a review request has been shown today
                            let calendar = Calendar.current
                            if !calendar.isDateInToday(self.lastReviewRequestDate) {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    SKStoreReviewController.requestReview(in: windowScene)
                                    self.lastReviewRequestDateDouble = Date().timeIntervalSince1970 // Update last request date
                                }
                            }
                            // Success message'ı 2 saniye göster, sonra reklamı göster
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                // Success message kapandıktan 0.5 saniye sonra reklamı göster
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if !subscriptionManager.isUserSubscribed && self.downloadCount % 2 == 0 {
                                        // Doğrudan güncel ve görünür view controller'ı bul
                                        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                                            let topVC = self.findTopViewController(rootVC)
                                            self.interstitialAd.showAd(from: topVC) {
                                                print("Ad shown successfully from video")
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
                            // İndirme sayacını artır
                            self.downloadCount += 1
                            
                            showSuccessMessage = true
                            
                            // Success message'ı 2 saniye göster, sonra reklamı göster
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                
                                // Success message kapandıktan 0.5 saniye sonra reklamı göster
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if !subscriptionManager.isUserSubscribed && self.downloadCount % 2 == 0 {
                                        // Doğrudan güncel ve görünür view controller'ı bul
                                        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                                            let topVC = self.findTopViewController(rootVC)
                                            self.interstitialAd.showAd(from: topVC) {
                                                print("Ad shown successfully from image")
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
    
    // En üst görünür view controller'ı bulan yardımcı fonksiyon
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
    
    // MARK: - Subscription Observer
    
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
 
