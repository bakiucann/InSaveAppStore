// InterstitialAd.swift
import SwiftUI
import GoogleMobileAds

class InterstitialAd: NSObject, GADFullScreenContentDelegate, ObservableObject {
    @Published var interstitial: GADInterstitialAd?
    @Published var isLoadingAd: Bool = false // Loading state for UI
    
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
    private let retryInterval: TimeInterval = 0.5
    
    // Timeout management
    private var timeoutWorkItem: DispatchWorkItem?
    private let adTimeout: TimeInterval = 5.0 // 5 seconds timeout
    
    override init() {
        super.init()
        loadInterstitial()
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
                }
                return
            }
            
            print("Interstitial ad loaded successfully")
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            self.loadAttempts = 0
            print("Ad is now available.")
        }
    }
    
    func showAd(from rootViewController: UIViewController, completion: @escaping () -> Void) {
        self.completion = completion
        self.rootViewController = rootViewController
        
        // MARK: - Safety Checks
        
        // Check 1: Subscription Status
        if SubscriptionManager.shared.isUserSubscribed {
            print("⚠️ User is subscribed, skipping ad display")
            completion()
            return
        }
        
        // Check 2: Cooldown (2 minutes = 120 seconds)
        if let lastShowTime = lastAdShowTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastShowTime)
            if timeSinceLastAd < 120 {
                let remainingTime = Int(120 - timeSinceLastAd)
                print("⚠️ Ad cooldown active. Please wait \(remainingTime) more seconds. Skipping ad.")
                completion()
                return
            }
        }
        
        // Check 3: Daily Limit (15 ads per day)
        if dailyAdCount >= 15 {
            print("⚠️ Daily ad limit reached (15). Skipping ad.")
            completion()
            return
        }
        
        // All checks passed, proceed with ad display
        print("✅ All safety checks passed. Proceeding with ad display.")
        isLoadingAd = true
        
        // Cancel any existing timeout
        timeoutWorkItem?.cancel()
        
        // Set up timeout (5 seconds)
        let timeoutItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isLoadingAd {
                print("⏱️ Ad timeout reached (5 seconds). Unblocking user.")
                self.isLoadingAd = false
                self.completion?()
                self.completion = nil
            }
        }
        timeoutWorkItem = timeoutItem
        DispatchQueue.main.asyncAfter(deadline: .now() + adTimeout, execute: timeoutItem)
        
        // Try to present ad
        if interstitial == nil {
            // Ad not ready, try to load
            loadInterstitial()
            // Wait a bit and try to present
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.tryPresentAd()
            }
        } else {
            // Ad is ready, present immediately
            tryPresentAd()
        }
    }
    
    private func tryPresentAd() {
        guard let interstitial = interstitial,
              let rootViewController = rootViewController else {
            print("⚠️ No ad available to show or no root view controller, completing immediately")
            isLoadingAd = false
            timeoutWorkItem?.cancel()
            completion?()
            completion = nil
            loadInterstitial() // Try to load for next time
            return
        }
        
        // Cancel timeout since we're presenting
        timeoutWorkItem?.cancel()
        
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

