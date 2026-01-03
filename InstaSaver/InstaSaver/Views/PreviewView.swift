// PreviewView.swift
// Glassmorphic UI Design - HomeView ile uyumlu

import SwiftUI
import Photos
import StoreKit
import Alamofire

struct PreviewView: View {
    // MARK: - Properties
    let video: InstagramVideoModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var collectionsViewModel = CollectionsViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    private let interstitialAd = InterstitialAd()
    // State variables
    @State private var imageData: Data?
    @State private var isBookmarked = false
    @State private var showCollectionsSheet = false
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var showPaywallView = false
    @State private var showAlert = false
    @State private var alertTitle = "Download Error"
    @State private var alertMessage = "An error occurred during download."
    @State private var loadingTimer: Timer?
    @State private var showPaywall = false
    @State private var isPhotoContent: Bool = false
    @AppStorage("lastReviewRequestDate") private var lastReviewRequestDateDouble: Double = Date.distantPast.timeIntervalSince1970
    @State private var collectionSuccessMessage = false
    @StateObject private var configManager = ConfigManager.shared
    @State private var selectedCollectionID: String?
    @State private var isCollectionSaveSuccess = false
    @State private var isShowingSuccess = false
    @State private var currentCarouselIndex: Int = 0
    @State private var showCarouselControls: Bool = false
    @State private var downloadProgress: Double = 0
    @StateObject private var downloadManager = DownloadManager.shared
    
    // MARK: - Initializer
    init(video: InstagramVideoModel) {
        self.video = video
    }
    
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
                
                // ScrollView ve içindeki elemanlar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Video Preview Card
                        videoPreviewCard
                        
                        // Carousel Controls
                        if let isCarousel = video.isCarousel, isCarousel, video.totalItems ?? 0 > 1 {
                            carouselControlsView
                        }
                        
                        // Video Info Card - sadece başlık varsa göster
                        if !video.videoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            videoInfoCard
                        }
                        
                        // Action Buttons
                        if configManager.shouldShowDownloadButtons {
                            actionButtons
                        }
                        
                        if !subscriptionManager.isUserSubscribed {
                            BannerAdView()
                                .frame(height: 50)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            
            // Overlay Views
            if isLoading { 
                loadingOverlay 
            }
            
            if showSuccessMessage { 
                successMessage 
            }
            
            if collectionSuccessMessage { 
                collectionSuccessMessageView 
            }
            
            if interstitialAd.isLoadingAd {
                AdLoadingOverlayView()
                    .zIndex(999)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .sheet(isPresented: $showCollectionsSheet) {
            collectionsSheet
        }
        .fullScreenCover(isPresented: $showPaywallView) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            isBookmarked = CoreDataManager.shared.isBookmarked(videoID: video.id)
            loadCoverImage()
            checkContentType()
        }
        .onDisappear {
            downloadManager.cancelAllDownloads()
        }
        .onChange(of: showPaywall) { isShowing in
            if !isShowing && isLoading {
                stopLoading()
            }
        }
        .onChange(of: showPaywallView) { isShowing in
            if !isShowing && isLoading {
                stopLoading()
            }
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
            Text(NSLocalizedString("Preview", comment: ""))
                .font(.system(size: 17, weight: .bold))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            
            Spacer()
            
            // Bookmark button
            bookmarkButton
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
    
    private func checkContentType() {
        let isPhotoFromAPI = video.isPhoto ?? false
        let imageExtensions = [".jpg", ".jpeg", ".png"]
        let downloadLinkHasImageExt = imageExtensions.contains { video.downloadLink.lowercased().contains($0) }
        let hasNoVideoVersions = video.allVideoVersions.isEmpty
        
        isPhotoContent = isPhotoFromAPI || hasNoVideoVersions || downloadLinkHasImageExt
        
        print("📸 İçerik türü: \(isPhotoContent ? "Fotoğraf" : "Video")")
        
        if let isCarousel = video.isCarousel, isCarousel {
            showCarouselControls = true
            print("🎠 Carousel içeriği: \(video.totalItems ?? 0) öğe içeriyor")
        }
    }
    
    // MARK: - UI Components
    
    private var videoPreviewCard: some View {
        VStack(spacing: 0) {
            if let data = imageData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .bottom) {
                    // Ana görüntü - aspect ratio korunarak tam genişlik
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: UIScreen.main.bounds.width - 32)
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
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
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    if value.translation.width < 0 {
                                        nextCarouselItem()
                                    } else if value.translation.width > 0 {
                                        previousCarouselItem()
                                    }
                                }
                        )
                    
                    // Page control (carousel varsa)
                    if let isCarousel = video.isCarousel, isCarousel, let totalItems = video.totalItems, totalItems > 1 {
                        pageControl
                            .padding(.bottom, 12)
                    }
                }
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
                    .frame(height: 300)
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
    }
    
    private var videoInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                // Content type icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("igPurple").opacity(0.1), Color("igPink").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isPhotoContent ? "photo.fill" : "play.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.videoTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.85))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Download HD Button
            GlassmorphicActionButton(
                title: NSLocalizedString("Download HD", comment: ""),
                icon: "arrow.down.circle.fill",
                isPrimary: true,
                action: {
                    if subscriptionManager.isUserSubscribed {
                        startLoading()
                        
                        if let isCarousel = video.isCarousel, isCarousel, 
                           let currentItem = getCurrentCarouselItem() {
                            if currentItem.isPhoto {
                                downloadAndSaveContent(urlString: currentItem.downloadLink)
                            } else if let hdVersion = currentItem.allVideoVersions.first(where: { $0.type == 101 }) {
                                downloadAndSaveContent(urlString: hdVersion.url)
                            } else if let firstVersion = currentItem.allVideoVersions.first {
                                downloadAndSaveContent(urlString: firstVersion.url)
                            } else {
                                downloadAndSaveContent(urlString: currentItem.downloadLink)
                            }
                        } else {
                            if isPhotoContent {
                                downloadAndSaveContent(urlString: video.downloadLink)
                            } else if let hdVersion = video.allVideoVersions.first(where: { $0.type == 101 }) {
                                downloadAndSaveContent(urlString: hdVersion.url)
                            }
                        }
                    } else {
                        showPaywallView = true
                    }
                }
            )
            
            // Download Button
            GlassmorphicActionButton(
                title: NSLocalizedString("Download", comment: ""),
                icon: "arrow.down.circle",
                isPrimary: false,
                action: {
                    if !subscriptionManager.isUserSubscribed {
                        if !CoreDataManager.shared.canDownloadMore() {
                            showPaywall = true
                            return
                        }
                    }
                    
                    startLoading()
                    
                    if let isCarousel = video.isCarousel, isCarousel, 
                       let currentItem = getCurrentCarouselItem() {
                        if currentItem.isPhoto {
                            downloadAndSaveContent(urlString: currentItem.downloadLink)
                        } else if let lowVersion = currentItem.allVideoVersions.first(where: { $0.type == 103 }) ?? currentItem.allVideoVersions.first {
                            downloadAndSaveContent(urlString: lowVersion.url)
                        } else {
                            downloadAndSaveContent(urlString: currentItem.downloadLink)
                        }
                    } else {
                        if isPhotoContent {
                            downloadAndSaveContent(urlString: video.downloadLink)
                        } else if let lowVersion = video.allVideoVersions.first(where: { $0.type == 103 }) ?? video.allVideoVersions.first {
                            downloadAndSaveContent(urlString: lowVersion.url)
                        }
                    }
                }
            )
        }
        .padding(.horizontal, 16)
    }
    
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
    
    private var bookmarkButton: some View {
        Button(action: { showCollectionsSheet.toggle() }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
            }
        }
    }
    
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
                        .trim(from: 0, to: downloadProgress)
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
                    
                    Text("\(Int(downloadProgress * 100))%")
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
    
    private var successMessage: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(isPhotoContent ? NSLocalizedString("Photo saved!", comment: "") : NSLocalizedString("Video saved!", comment: ""))
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
    
    private var collectionSuccessMessageView: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            HStack(spacing: 12) {
                Image(systemName: "folder.fill.badge.plus")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Text(NSLocalizedString("Added to collection!", comment: ""))
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                collectionSuccessMessage = false
            }
        }
    }
    
    private var collectionsSheet: some View {
        NavigationView {
            ZStack {
                CollectionsView(
                    viewModel: collectionsViewModel,
                    onCollectionSelected: { collection in
                        saveToCollection(collection: collection)
                        showCollectionsSheet = false
                        isBookmarked = true
                        collectionSuccessMessage = true
                    },
                    isPresentedModally: true
                )
                .navigationBarTitle("Collections", displayMode: .inline)
                
                // Collections Alert Overlay - + butonuna basıldığında gösterilir
                CollectionsAlertOverlay(viewModel: collectionsViewModel)
            }
        }
    }
    
    // Page control
    private var pageControl: some View {
        HStack(spacing: 6) {
            ForEach(0..<(video.totalItems ?? 0), id: \.self) { index in
                Capsule()
                    .fill(currentCarouselIndex == index ? Color("igPink") : Color.white.opacity(0.6))
                    .frame(width: currentCarouselIndex == index ? 16 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: currentCarouselIndex)
                    .onTapGesture {
                        currentCarouselIndex = index
                        updatePreviewForCarouselItem()
                    }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
        )
    }
    
    private var carouselControlsView: some View {
        EmptyView()
    }
    
    // MARK: - Helper Functions (unchanged)
    
    private func startLoading() {
        isLoading = true
        downloadProgress = 0
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
    
    private func downloadAndSaveContent(urlString: String) {
        var isCurrentItemPhoto = isPhotoContent
        if let isCarousel = video.isCarousel, isCarousel, let currentItem = getCurrentCarouselItem() {
            isCurrentItemPhoto = currentItem.isPhoto
        }
        
        downloadManager.downloadContent(
            urlString: urlString,
            isPhoto: isCurrentItemPhoto
        ) { progress in
            DispatchQueue.main.async {
                self.downloadProgress = progress
            }
        } completion: { result in
            DispatchQueue.main.async {
                self.stopLoading()
                
                switch result {
                case .success(let fileURL):
                    if !self.subscriptionManager.isUserSubscribed {
                        CoreDataManager.shared.incrementDailyDownloadCount()
                    }
                    
                    if isCurrentItemPhoto {
                        self.saveImageToGallery(from: fileURL)
                    } else {
                        self.saveVideoToGallery(from: fileURL)
                    }
                    
                case .failure(let error):
                    print("❌ İndirme hatası: \(error.localizedDescription)")
                    self.showAlert = true
                    self.presentErrorAlert(with: error)
                }
            }
        }
    }
    
    private func presentErrorAlert(with error: Error) {
        alertMessage = downloadManager.getErrorMessage(from: error)
        alertTitle = "Download Error"
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
    private func saveImageToGallery(from fileURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: fileURL, options: nil)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.handleContentSaveSuccess()
                    } else if let error = error {
                        print("Error saving image: \(error)")
                    }
                }
            }
        }
    }
    
    private func saveVideoToGallery(from fileURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL: fileURL, options: nil)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.handleContentSaveSuccess()
                    } else {
                        if let error = error {
                            print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func handleContentSaveSuccess() {
        showSuccessMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                interstitialAd.showAd(from: rootViewController) {
                    print("✅ Ad shown after successful download")
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
            let calendar = Calendar.current
            if !calendar.isDateInToday(lastReviewRequestDate) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                    lastReviewRequestDateDouble = Date().timeIntervalSince1970
                }
            }
        }
        saveVideoInfoToCoreData(video: video)
        NotificationCenter.default.post(name: NSNotification.Name("NewVideoSaved"), object: nil)
    }
    
    private func saveVideoInfoToCoreData(video: InstagramVideoModel) {
        CoreDataManager.shared.saveVideoInfo(
            videoID: video.id,
            uniqueId: video.videoTitle,
            originCover: video.thumbnailUrl,
            downloadLink: video.downloadLink,
            date: Date(),
            type: (video.isPhoto ?? false) ? "photo" : "video"
        )
    }
    
    private func saveToCollection(collection: CollectionModel) {
        let context = CoreDataManager.shared.context
        let bookmark = BookmarkedVideo(context: context)
        bookmark.id = video.id
        bookmark.dateAdded = Date()
        bookmark.authorID = "instagram_user_id"
        
        if let coverUrl = URL(string: video.thumbnailUrl) {
            URLSession.shared.dataTask(with: coverUrl) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        bookmark.coverImageData = data
                        collection.addToVideos(bookmark)
                        do {
                            try context.save()
                            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
                        } catch {
                            print("CoreData error: \(error)")
                        }
                    }
                }
            }.resume()
        }
    }
    
    private func loadCoverImage() {
        if let url = URL(string: video.thumbnailUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageData = data
                    }
                }
            }.resume()
        }
        
        if let isCarousel = video.isCarousel, isCarousel,
           let currentItem = getCurrentCarouselItem() {
            if let url = URL(string: currentItem.thumbnailUrl) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data {
                        DispatchQueue.main.async {
                            self.imageData = data
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func getCurrentCarouselItem() -> CarouselItem? {
        guard let carouselItems = video.carouselItems,
              currentCarouselIndex < carouselItems.count else {
            return nil
        }
        return carouselItems[currentCarouselIndex]
    }
    
    private func previousCarouselItem() {
        if currentCarouselIndex > 0 {
            currentCarouselIndex -= 1
            updatePreviewForCarouselItem()
        }
    }
    
    private func nextCarouselItem() {
        if let totalItems = video.totalItems, currentCarouselIndex < totalItems - 1 {
            currentCarouselIndex += 1
            updatePreviewForCarouselItem()
        }
    }
    
    private func updatePreviewForCarouselItem() {
        guard let item = getCurrentCarouselItem() else { return }
        
        if let url = URL(string: item.thumbnailUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageData = data
                    }
                }
            }.resume()
        }
        
        isPhotoContent = item.isPhoto
    }
}

// MARK: - Glassmorphic Action Button
struct GlassmorphicActionButton: View {
    let title: String
    let icon: String
    let isPrimary: Bool
    let action: () -> Void
    
    private let instagramGradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    if isPrimary {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(instagramGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color("igPurple").opacity(0.8), Color("igPink").opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05), Color.clear],
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
            .shadow(color: Color("igPurple").opacity(isPrimary ? 0.3 : 0.2), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - ActionButton (kept for compatibility)
struct ActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
            )
            .shadow(color: gradient[0].opacity(0.3), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .pressEvents { isPressed in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isPressed = isPressed
            }
        }
    }
}

extension View {
    func pressEvents(onPress: @escaping (Bool) -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress(true) }
                .onEnded { _ in onPress(false) }
        )
    }
}
