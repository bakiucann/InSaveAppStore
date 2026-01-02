// InterstitialAd.swift
import SwiftUI
import GoogleMobileAds

class InterstitialAd: NSObject, GADFullScreenContentDelegate, ObservableObject {
    @Published var interstitial: GADInterstitialAd?
    @Published var isLoadingAd: Bool = false // Loading state for UI
    @Published var isLoadingAdForFirstSearch: Bool = false // İlk aramada reklam yükleniyor mu?
    
    let adUnitID: String = "ca-app-pub-9288291055014999/6789517081"
    var rootViewController: UIViewController?
    var completion: (() -> Void)?
    
    // State Management for Ad Display Safety
    private var dailyAdCount: Int {
        get {
            let key = "interstitial_daily_ad_count"
            let dateKey = "interstitial_daily_ad_count_date"
            let defaults = UserDefaults.standard
            
            // Check if we need to reset (new day)
            if let lastDate = defaults.object(forKey: dateKey) as? Date {
                if !Calendar.current.isDateInToday(lastDate) {
                    // New day, reset count
                    defaults.set(0, forKey: key)
                    defaults.set(Date(), forKey: dateKey)
                    return 0
                }
            } else {
                // First time, initialize
                defaults.set(0, forKey: key)
                defaults.set(Date(), forKey: dateKey)
                return 0
            }
            
            return defaults.integer(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "interstitial_daily_ad_count")
            UserDefaults.standard.set(Date(), forKey: "interstitial_daily_ad_count_date")
        }
    }
    
    private var lastAdShowTime: Date? {
        get {
            return UserDefaults.standard.object(forKey: "interstitial_last_ad_show_time") as? Date
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date, forKey: "interstitial_last_ad_show_time")
            } else {
                UserDefaults.standard.removeObject(forKey: "interstitial_last_ad_show_time")
            }
        }
    }
    
    // Ad loading state (internal)
    private var isLoading = false
    private var loadAttempts = 0
    private let maxAttempts = 5
    private let retryInterval: TimeInterval = 0.3 // Daha hızlı retry için 0.3 saniye
    
    // Pending show request flag - when ad is requested but not yet loaded
    // rootViewController and completion are already stored as class properties
    private var hasPendingShowRequest = false
    private var skipCooldownForPending = false // İlk aramada cooldown'u atla
    private var isFirstSearchRequest = false // İlk aramada reklam zorunlu
    
    // Timeout management
    private var timeoutWorkItem: DispatchWorkItem?
    private let adTimeout: TimeInterval = 2.0 // 2 seconds timeout (reduced from 5)
    private let firstSearchAdTimeout: TimeInterval = 8.0 // İlk aramada reklam için 8 saniye timeout
    
    override init() {
        super.init()
        // ❌ REMOVED: loadInterstitial() from init
        // Ad will be loaded lazily when needed (optimistic loading)
    }
    
    func loadInterstitial() {
        guard !isLoading && loadAttempts < maxAttempts else { return }
        
        isLoading = true
        loadAttempts += 1
        
        let request = GADRequest()
        print("Loading interstitial ad, attempt: \(loadAttempts)")
        
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                print("Interstitial ad failed to load: \(error.localizedDescription)")
                print("Ad is not available.")
                
                // Always retry if we haven't reached max attempts
                if self.loadAttempts < self.maxAttempts {
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.retryInterval) {
                        self.loadInterstitial()
                    }
                } else {
                    // Reset attempts after reaching max
                    self.loadAttempts = 0
                    // If there was a pending request and we failed to load
                    if self.hasPendingShowRequest {
                        // İlk aramada reklam zorunlu ise, timeout beklesin
                        // Değilse hemen completion çağır
                        if !self.isFirstSearchRequest {
                            print("❌ Failed to load ad after max attempts, completing pending request")
                            self.hasPendingShowRequest = false
                            self.skipCooldownForPending = false
                            let savedCompletion = self.completion
                            self.completion = nil
                            DispatchQueue.main.async {
                                savedCompletion?()
                            }
                        } else {
                            print("⏱️ First search ad failed to load, waiting for timeout...")
                            // Timeout zaten ayarlanmış, o bekleyecek
                        }
                    }
                }
                return
            }
            
            print("Interstitial ad loaded successfully")
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            self.loadAttempts = 0
            print("Ad is now available.")
            
            // If there's a pending show request, automatically show the ad
            if self.hasPendingShowRequest {
                print("🔄 Pending show request found, automatically showing ad after load")
                // Timeout'u iptal et çünkü reklam yüklendi
                self.timeoutWorkItem?.cancel()
                DispatchQueue.main.async {
                    self.isLoadingAdForFirstSearch = false // Loading overlay'i gizle
                }
                self.hasPendingShowRequest = false
                // rootViewController and completion are already set from showAd call
                // Run safety checks again before showing
                self.tryShowAdAfterLoad()
            }
        }
    }
    
    private func tryShowAdAfterLoad() {
        // Re-run safety checks
        if SubscriptionManager.shared.isUserSubscribed {
            print("⚠️ User is subscribed, skipping ad display (pending request)")
            timeoutWorkItem?.cancel()
            hasPendingShowRequest = false
            skipCooldownForPending = false
            isFirstSearchRequest = false
            let savedCompletion = self.completion
            self.completion = nil
            savedCompletion?()
            return
        }
        
        // Cooldown kontrolü - eğer skipCooldownForPending true ise atla
        if !skipCooldownForPending {
            if let lastShowTime = lastAdShowTime {
                let timeSinceLastAd = Date().timeIntervalSince(lastShowTime)
                if timeSinceLastAd < 60 {
                    let remainingTime = Int(60 - timeSinceLastAd)
                    print("⚠️ Ad cooldown active. Please wait \(remainingTime) more seconds. Skipping ad (pending request).")
                    timeoutWorkItem?.cancel()
                    hasPendingShowRequest = false
                    skipCooldownForPending = false
                    isFirstSearchRequest = false
                    let savedCompletion = self.completion
                    self.completion = nil
                    savedCompletion?()
                    return
                }
            }
        } else {
            print("🔄 Skipping cooldown check for pending request (first search)")
        }
        
        if dailyAdCount >= 15 {
            print("⚠️ Daily ad limit reached (15). Skipping ad (pending request).")
            timeoutWorkItem?.cancel()
            hasPendingShowRequest = false
            skipCooldownForPending = false
            isFirstSearchRequest = false
            let savedCompletion = self.completion
            self.completion = nil
            savedCompletion?()
            return
        }
        
        // All checks passed, show the ad
        print("✅ All safety checks passed for pending request. Showing ad.")
        timeoutWorkItem?.cancel() // Timeout'u iptal et çünkü reklam gösterilecek
        skipCooldownForPending = false // Reset flag
        isFirstSearchRequest = false
        tryPresentAd() // This will clear hasPendingShowRequest flag
    }
    
    func showAd(from rootViewController: UIViewController, completion: @escaping () -> Void, skipCooldown: Bool = false) {
        self.completion = completion
        self.rootViewController = rootViewController
        
        // MARK: - Safety Checks
        
        // Check 1: Subscription Status
        if SubscriptionManager.shared.isUserSubscribed {
            print("⚠️ User is subscribed, skipping ad display")
            completion()
            return
        }
        
        // Check 2: Cooldown (1 minute = 60 seconds)
        // skipCooldown = true ise cooldown kontrolünü atla (ilk arama için)
        if !skipCooldown {
            if let lastShowTime = lastAdShowTime {
                let timeSinceLastAd = Date().timeIntervalSince(lastShowTime)
                if timeSinceLastAd < 60 {
                    let remainingTime = Int(60 - timeSinceLastAd)
                    print("⚠️ Ad cooldown active. Please wait \(remainingTime) more seconds. Skipping ad.")
                    completion()
                    return
                }
            }
        } else {
            print("🔄 Skipping cooldown check for first search - ad will be shown")
        }
        
        // Check 3: Daily Limit (15 ads per day)
        if dailyAdCount >= 15 {
            print("⚠️ Daily ad limit reached (15). Skipping ad.")
            completion()
            return
        }
        
        // All checks passed, proceed with ad display
        print("✅ All safety checks passed. Proceeding with ad display.")
        
        // Check if ad is ready BEFORE showing any loading indicator
        if interstitial != nil {
            // Ad is ready, present immediately (no loading overlay needed)
            tryPresentAd()
        } else {
            // Ad not ready - save the request and load the ad
            // When ad loads, it will automatically show
            print("⚠️ Ad not ready. Saving show request and loading ad...")
            hasPendingShowRequest = true
            skipCooldownForPending = skipCooldown // İlk aramada cooldown'u atla
            isFirstSearchRequest = skipCooldown // İlk aramada reklam zorunlu
            // rootViewController and completion are already stored as class properties
            
            // Start loading if not already loading
            if !isLoading {
                loadInterstitial()
            }
            
            // İlk aramada reklam yüklenemezse timeout ekle
            // Bu sayede kullanıcı sonsuz beklemeye düşmez
            if isFirstSearchRequest {
                print("⏱️ Setting timeout for first search ad loading (\(firstSearchAdTimeout) seconds)")
                DispatchQueue.main.async {
                    self.isLoadingAdForFirstSearch = true // Loading overlay'i göster
                }
                timeoutWorkItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    if self.hasPendingShowRequest {
                        print("⏱️ First search ad loading timeout - opening PreviewView anyway")
                        DispatchQueue.main.async {
                            self.isLoadingAdForFirstSearch = false // Loading overlay'i gizle
                        }
                        self.hasPendingShowRequest = false
                        self.skipCooldownForPending = false
                        self.isFirstSearchRequest = false
                        let savedCompletion = self.completion
                        self.completion = nil
                        savedCompletion?()
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + firstSearchAdTimeout, execute: timeoutWorkItem!)
            }
            
            // Don't call completion yet - wait for ad to load and show
            // Completion will be called when ad is shown or if it fails
        }
    }
    
    private func tryPresentAd() {
        guard let interstitial = interstitial,
              let rootViewController = rootViewController else {
            print("⚠️ No ad available to show or no root view controller, completing immediately")
            isLoadingAd = false
            timeoutWorkItem?.cancel()
            DispatchQueue.main.async {
                self.isLoadingAdForFirstSearch = false // Loading overlay'i gizle
            }
            hasPendingShowRequest = false // Clear pending request flag
            skipCooldownForPending = false
            isFirstSearchRequest = false
            let savedCompletion = completion
            completion = nil
            savedCompletion?() // Complete immediately - don't block user
            loadInterstitial() // Try to load for next time (background)
            return
        }
        
        // Clear pending request flags since we're showing the ad now
        timeoutWorkItem?.cancel() // Timeout'u iptal et
        DispatchQueue.main.async {
            self.isLoadingAdForFirstSearch = false // Loading overlay'i gizle
        }
        hasPendingShowRequest = false
        skipCooldownForPending = false
        isFirstSearchRequest = false
        
        // İyileştirilmiş sunum kontrolü
        if rootViewController.presentedViewController != nil {
            print("View controller is already presenting, trying to find top-most controller...")
            
            // En üst controller'ı bulmaya çalış
            var topVC = rootViewController
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            
            // En üst controller üzerinden reklamı göster
            print("✅ Presenting ad from top-most controller")
            interstitial.present(fromRootViewController: topVC)
            print("Ad is being presented from top controller.")
            return
        }
        
        print("✅ Showing interstitial ad")
        interstitial.present(fromRootViewController: rootViewController)
        print("Ad is being presented.")
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("✅ Interstitial ad dismissed successfully")
        
        // Cancel any pending timeout
        timeoutWorkItem?.cancel()
        
        // Update state: Increment daily count and update last show time
        dailyAdCount += 1
        lastAdShowTime = Date()
        
        print("📊 Ad stats updated - Daily count: \(dailyAdCount), Last show time: \(lastAdShowTime?.description ?? "nil")")
        
        // Reset loading state
        isLoadingAd = false
        
        // Clean up
        self.interstitial = nil
        let savedCompletion = completion
        completion = nil
        
        // Call completion to unblock user
        savedCompletion?()
        
        // Preload next ad
        loadInterstitial()
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Interstitial ad failed to present: \(error.localizedDescription)")
        
        // Cancel any pending timeout
        timeoutWorkItem?.cancel()
        
        // Clean up flags
        hasPendingShowRequest = false
        skipCooldownForPending = false
        isFirstSearchRequest = false
        
        // Reset loading state
        isLoadingAd = false
        
        // Clean up
        self.interstitial = nil
        let savedCompletion = completion
        completion = nil
        
        // Call completion to unblock user (don't increment count on failure)
        savedCompletion?()
        
        // Try to load again for next time
        loadInterstitial()
    }
}

struct InterstitialAdView: UIViewControllerRepresentable {
    var interstitial = InterstitialAd()
    
    @State private var isLoadingAd = true // Reklam yükleniyor göstergesi
    
    var onAdDismiss: (() -> Void)? // Reklam kapandıktan sonra yapılacak işlem
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            interstitial.showAd(from: viewController) {
                isLoadingAd = false
                onAdDismiss?()
            }
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject {
        var parent: InterstitialAdView
        
        init(parent: InterstitialAdView) {
            self.parent = parent
        }
    }
}

struct InterstitialAdLoadingView: View {
    @State private var isLoadingAd = true
    
    var body: some View {
        VStack {
            if isLoadingAd {
                ProgressView("Ad loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Text("Ad loaded.")
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isLoadingAd = false
            }
        }
    }
}

