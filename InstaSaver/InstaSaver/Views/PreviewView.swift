// PreviewView.swift

import SwiftUI
import Photos

struct PreviewView: View {
    let video: InstagramVideoModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var collectionsViewModel = CollectionsViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    private let interstitialAd = InterstitialAd()
    // State variables
    @State private var imageData: Data?
    @State private var isBookmarked = false
    @State private var showCollectionsSheet = false
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var showPaywallView = false
    @State private var showAlert = false
    @State private var loadingTimer: Timer?
    @State private var showPaywall = false
    
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
                    // Video Preview Card
                    videoPreviewCard
                    
                    // Video Info Card
                    videoInfoCard
                    
                    // Action Buttons
                    actionButtons
                    
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
            if isLoading { loadingOverlay }
            if showSuccessMessage { successMessage }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                bookmarkButton
            }
            ToolbarItem(placement: .principal) {
                toolbarTitle
            }
        }
        .sheet(isPresented: $showCollectionsSheet) {
            collectionsSheet
        }
        .fullScreenCover(isPresented: $showPaywallView) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            isBookmarked = CoreDataManager.shared.isBookmarked(videoID: video.id)
            loadCoverImage()
        }
    }
    
    // MARK: - UI Components
    
    private var videoPreviewCard: some View {
        VStack(spacing: 0) {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.45)
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
                    .frame(height: UIScreen.main.bounds.height * 0.45)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var videoInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title Section
            HStack(spacing: 12) {
                Circle()
                    .fill(Color("igPink").opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("igPink"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.videoTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            

//            .padding(.leading, 52)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            //MARK: nglice
         
                ActionButton(
                    title: NSLocalizedString("Download HD", comment: ""),
                    icon: "arrow.down.circle.fill",
                    gradient: [Color("igPurple"), Color("igPink")],
                    action: {
                        if subscriptionManager.isUserSubscribed {
                            if let hdVersion = video.allVideoVersions.first(where: { $0.type == 101 }) {
                                startLoading()
                                downloadAndSaveVideo(urlString: hdVersion.url)
                            }
                        } else {
                            showPaywallView = true
                        }
                    }
                )
                
                ActionButton(
                    title: NSLocalizedString("Download", comment: ""),
                    icon: "arrow.down.circle",
                    gradient: [Color("igPurple").opacity(0.8), Color("igPink").opacity(0.8)],
                    action: {
                        if let lowVersion = video.allVideoVersions.first(where: { $0.type == 103 }) {
                            startLoading()
                            downloadAndSaveVideo(urlString: lowVersion.url)
                        }
                    }
                )
            }
        
        .padding(.horizontal, 20)
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
    
    private var bookmarkButton: some View {
        Button(action: { showCollectionsSheet.toggle() }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("igPurple"))
            }
        }
    }
    
    private var toolbarTitle: some View {
        Text(NSLocalizedString("Preview", comment: ""))
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
    
//        private func thisButtonsNotAccepted() -> Bool {
//        let currentLanguage = Locale.current.languageCode
//        return currentLanguage == "en"
//    }
    
    private var successMessage: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            Text("Video saved successfully!")
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
    
    private var collectionsSheet: some View {
        NavigationView {
            CollectionsView(
                viewModel: collectionsViewModel,
                onCollectionSelected: { collection in
                    saveToCollection(collection: collection)
                    showCollectionsSheet = false
                    isBookmarked = true
                },
                isPresentedModally: true
            )
            .navigationBarTitle("Collections", displayMode: .inline)
        }
    }
    
    // MARK: - Helper Views
    
    private func statsItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color("igPink"))
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Video Download & Gallery Save Operations
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
    
    private func downloadAndSaveVideo(urlString: String) {
        // Önce abonelik ve indirme limiti kontrolü
        if !subscriptionManager.isUserSubscribed {
            if !CoreDataManager.shared.canDownloadMore() {
                showPaywall = true
                return
            }
        }
        
        guard let url = URL(string: urlString) else {
            stopLoading()
            return
        }
        
        URLSession.shared.downloadTask(with: url) { location, response, error in
            if let error = error {
                print("Error downloading: \(error.localizedDescription)")
                DispatchQueue.main.async { self.stopLoading() }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status code: \(httpResponse.statusCode)")
            }
            let mimeType = response?.mimeType ?? "nil"
            print("MIME type: \(mimeType)")
            
            guard let location = location else {
                print("No file location returned from server.")
                DispatchQueue.main.async { self.stopLoading() }
                return
            }
            
            do {
                let data = try Data(contentsOf: location)
                print("Data size:", data.count)
                
                if mimeType.contains("video") && !data.isEmpty {
                    let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent("downloadedVideo.mp4")
                    if FileManager.default.fileExists(atPath: tmpUrl.path) {
                        try FileManager.default.removeItem(at: tmpUrl)
                    }
                    try FileManager.default.moveItem(at: location, to: tmpUrl)
                    
                    DispatchQueue.main.async {
                        self.stopLoading()
                        // İndirme başarılı olduğunda sayacı artır
                        if !self.subscriptionManager.isUserSubscribed {
                            CoreDataManager.shared.incrementDailyDownloadCount()
                        }
                        self.saveVideoToGallery(from: tmpUrl)
                    }
                } else {
                    print("Received data is not a valid video or is empty.")
                    DispatchQueue.main.async { self.stopLoading() }
                }
            } catch {
                print("File handling error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.stopLoading() }
            }
        }.resume()
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
                        self.handleVideoSaveSuccess()
                    } else {
                        if let error = error {
                            print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func handleVideoSaveSuccess() {
        showSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
            
            // Show interstitial ad for non-subscribed users after success message is dismissed
            if !subscriptionManager.isUserSubscribed {
                if let windowScene = UIApplication.shared.windows.first?.rootViewController {
                    let presenter = windowScene.presentedViewController ?? windowScene
                    if presenter.presentedViewController == nil {
                        self.interstitialAd.showAd(from: presenter) {
                            print("Ad shown successfully")
                        }
                    }
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
            date: Date()
        )
    }
    
    // MARK: - Collection Save Operations
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
    
    // MARK: - Image Loading
    private func loadCoverImage() {
        guard let url = URL(string: video.thumbnailUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    self.imageData = data
                }
            }
        }.resume()
    }
}

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
