// PreviewView.swift

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
    
    // MARK: - Initializer - public erişim için açıkça tanımlandı
    init(video: InstagramVideoModel) {
        self.video = video
    }
    
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
                // Custom NavBar (butonlar ile birlikte)
                HStack {
                    // Back button
                    backButton
                    
                    Spacer()
                    
                    // Title
                    toolbarTitle
                    
                    Spacer()
                    
                    // Bookmark button
                    bookmarkButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .zIndex(1) // Navigation bar'ın diğer elemanların üzerinde olmasını sağlar
                
                // ScrollView ve içindeki elemanlar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Video Preview Card
                        videoPreviewCard
                        
                        // Carousel Controls
                        if let isCarousel = video.isCarousel, isCarousel, video.totalItems ?? 0 > 1 {
                            carouselControlsView
                        }
                        
                        // Video Info Card
                        videoInfoCard
                        
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
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
            }
            
            // Overlay Views - SuccessMessage ve LoadingOverlay tüm ekranı kaplamalı
            if isLoading { 
                loadingOverlay 
            }
            
            if showSuccessMessage { 
                successMessage 
            }
            
            if collectionSuccessMessage { 
                collectionSuccessMessageView 
            }
            
            // Ad Loading Overlay - Reklam yüklenirken tüm ekranı kaplar
            if interstitialAd.isLoadingAd {
                AdLoadingOverlayView()
                    .zIndex(999)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true) // Navigation bar'ı gizle çünkü kendi custom bar'ımızı kullanacağız
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
            // Paywall kapatıldığında loading state'i temizle
            if !isShowing && isLoading {
                stopLoading()
            }
        }
        .onChange(of: showPaywallView) { isShowing in
            // Paywall kapatıldığında loading state'i temizle
            if !isShowing && isLoading {
                stopLoading()
            }
        }
    }
    
    private func checkContentType() {
        // Bu içerik bir resim veya video olabilir. Şu kriterlere göre kontrol edelim:
        // 1. API yanıtından gelen isPhoto değeri true ise bu bir fotoğraftır
        // 2. allVideoVersions boş ise ve downloadLink bir resim formatı içeriyorsa (jpg, jpeg, png) bu bir fotoğraftır
        
        // API isPhoto değeri
        let isPhotoFromAPI = video.isPhoto ?? false
        
        // downloadLink içinde resim formatı var mı kontrol et
        let imageExtensions = [".jpg", ".jpeg", ".png"]
        let downloadLinkHasImageExt = imageExtensions.contains { video.downloadLink.lowercased().contains($0) }
        
        // allVideoVersions boş mu kontrol et
        let hasNoVideoVersions = video.allVideoVersions.isEmpty
        
        // Kriterlere göre içerik türünü belirle
        isPhotoContent = isPhotoFromAPI || hasNoVideoVersions || downloadLinkHasImageExt
        
        print("📸 İçerik türü: \(isPhotoContent ? "Fotoğraf" : "Video")")
        print("📸 API isPhoto değeri: \(isPhotoFromAPI)")
        print("📸 Boş video versiyonları: \(hasNoVideoVersions)")
        print("📸 İndirme linki resim içeriyor: \(downloadLinkHasImageExt)")
        print("📸 İndirme linki: \(video.downloadLink)")
        
        // Carousel kontrolünü göster
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
                    // Ana görüntü
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
                        // Kaydırma için gesture ekle
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    // Sola kaydırma -> Sonraki öğe
                                    if value.translation.width < 0 {
                                        nextCarouselItem()
                                    }
                                    // Sağa kaydırma -> Önceki öğe
                                    else if value.translation.width > 0 {
                                        previousCarouselItem()
                                    }
                                }
                        )
                    
                    // Alt kısımda page control göster (carousel varsa)
                    if let isCarousel = video.isCarousel, isCarousel, let totalItems = video.totalItems, totalItems > 1 {
                        pageControl
                            .padding(.bottom, 16)
                    }
                }
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
                        Image(systemName: isPhotoContent ? "photo.fill" : "play.circle.fill")
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
            // Download HD Button
            ActionButton(
                title: NSLocalizedString("Download HD", comment: ""),
                icon: "arrow.down.circle.fill",
                gradient: [Color("igPurple"), Color("igPink")],
                action: {
                    if subscriptionManager.isUserSubscribed {
                        startLoading()
                        
                        // Carousel içeriği ise şu anki öğeyi kullan
                        if let isCarousel = video.isCarousel, isCarousel, 
                           let currentItem = getCurrentCarouselItem() {
                            // Fotoğraf mı yoksa video mu kontrolü
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
                            // Normal içerik için orijinal davranış
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
            ActionButton(
                title: NSLocalizedString("Download", comment: ""),
                icon: "arrow.down.circle",
                gradient: [Color("igPurple").opacity(0.8), Color("igPink").opacity(0.8)],
                action: {
                    // ÖNCE indirme limiti kontrolü yap (startLoading'dan önce)
                    if !subscriptionManager.isUserSubscribed {
                        if !CoreDataManager.shared.canDownloadMore() {
                            showPaywall = true
                            return // Limit dolmuş, paywall göster ve çık
                        }
                    }
                    
                    // Limit kontrolü geçti, indirme işlemini başlat
                    startLoading()
                    
                    // Carousel içeriği ise şu anki öğeyi kullan
                    if let isCarousel = video.isCarousel, isCarousel, 
                       let currentItem = getCurrentCarouselItem() {
                        // Fotoğraf mı yoksa video mu kontrolü
                        if currentItem.isPhoto {
                            downloadAndSaveContent(urlString: currentItem.downloadLink)
                        } else if let lowVersion = currentItem.allVideoVersions.first(where: { $0.type == 103 }) ?? currentItem.allVideoVersions.first {
                            downloadAndSaveContent(urlString: lowVersion.url)
                        } else {
                            downloadAndSaveContent(urlString: currentItem.downloadLink)
                        }
                    } else {
                        // Normal içerik için orijinal davranış
                        if isPhotoContent {
                            downloadAndSaveContent(urlString: video.downloadLink)
                        } else if let lowVersion = video.allVideoVersions.first(where: { $0.type == 103 }) ?? video.allVideoVersions.first {
                            downloadAndSaveContent(urlString: lowVersion.url)
                        }
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
            
            VStack(spacing: 12) {
                ProgressView(value: downloadProgress)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("igPurple")))
                    .scaleEffect(1.5)
                    .padding(.bottom, 8)
                
                Text("Downloading")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("igPurple"))
                
                Text("\(Int(downloadProgress * 100))%")
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
    
    private var successMessage: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            Text(isPhotoContent ? "Photo saved successfully!" : "Video saved successfully!")
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
    
    private var collectionSuccessMessageView: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            Text(isPhotoContent ? "Photo successfully added to the collection!" : "Video successfully added to the collection!")
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                collectionSuccessMessage = false
            }
        }
    }
    
    private var collectionsSheet: some View {
        NavigationView {
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
    
    // Yeni birleştirilmiş fonksiyon: Hem video hem fotoğraf indirme (Alamofire ile)
    private func downloadAndSaveContent(urlString: String) {
        // NOT: Limit kontrolü artık buton action'ında yapılıyor (startLoading'dan önce)
        // Burada sadece indirme işlemini başlatıyoruz
        
        // İndirme işlemini başlat (startLoading zaten çağrılmış olmalı)
        
        // İçerik türünü belirle (Carousel içeriği veya normal içerik için)
        var isCurrentItemPhoto = isPhotoContent
        if let isCarousel = video.isCarousel, isCarousel, let currentItem = getCurrentCarouselItem() {
            isCurrentItemPhoto = currentItem.isPhoto
        }
        
        // Alamofire ile indirme işlemi
        downloadManager.downloadContent(
            urlString: urlString,
            isPhoto: isCurrentItemPhoto
        ) { progress in
            // İlerleme güncellemesi
            DispatchQueue.main.async {
                self.downloadProgress = progress
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
                    
                    if isCurrentItemPhoto {
                        self.saveImageToGallery(from: fileURL)
                    } else {
                        self.saveVideoToGallery(from: fileURL)
                    }
                    
                case .failure(let error):
                    // Hata durumu
                    print("❌ İndirme hatası: \(error.localizedDescription)")
                    self.showAlert = true
                    
                    // Kullanıcıya daha iyi geri bildirim
                    self.presentErrorAlert(with: error)
                }
            }
        }
    }
    
    // Hata durumu için daha iyi geri bildirim
    private func presentErrorAlert(with error: Error) {
        // DownloadManager'daki yardımcı metodu kullan
        alertMessage = downloadManager.getErrorMessage(from: error)
        alertTitle = "Download Error"
        
        // Uyarı mesajını göster
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
    // Fotoğrafları galeriye kaydetme
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
        
        // Success message'ı göster, sonra reklam göster (POST-action)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Success message göründükten 0.8 saniye sonra reklam göster
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                interstitialAd.showAd(from: rootViewController) {
                    print("✅ Ad shown after successful download")
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
            // Check if a review request has been shown today
            let calendar = Calendar.current
            if !calendar.isDateInToday(lastReviewRequestDate) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                    lastReviewRequestDateDouble = Date().timeIntervalSince1970 // Update last request date
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
        if let url = URL(string: video.thumbnailUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageData = data
                    }
                }
            }.resume()
        }
        
        // Carousel içeriği ise güncel öğe için ön yükleme yap
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
    
    // MARK: - Subscription Observer
    
    // MARK: - Carousel İşlevleri
    
    // Yeni kompakt page control
    private var pageControl: some View {
        HStack(spacing: 8) {
            ForEach(0..<(video.totalItems ?? 0), id: \.self) { index in
                Circle()
                    .fill(currentCarouselIndex == index ? Color("igPurple") : Color.gray.opacity(0.3))
                    .frame(width: currentCarouselIndex == index ? 10 : 8, height: currentCarouselIndex == index ? 10 : 8)
                    .animation(.spring(), value: currentCarouselIndex)
                    .onTapGesture {
                        currentCarouselIndex = index
                        updatePreviewForCarouselItem()
                    }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // Eski carouselControlsView yerine bu fonksiyon kullanılacak
    private var carouselControlsView: some View {
        // Boş bir view dönüyoruz çünkü page control artık videoPreviewCard içinde
        EmptyView()
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
        
        // Önizleme resmi yeniden yükle
        if let url = URL(string: item.thumbnailUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageData = data
                    }
                }
            }.resume()
        }
        
        // İçerik tipini güncelle
        isPhotoContent = item.isPhoto
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




