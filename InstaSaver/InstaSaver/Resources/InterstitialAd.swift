// InterstitialAd.swift
import SwiftUI
import GoogleMobileAds

class InterstitialAd: NSObject, GADFullScreenContentDelegate, ObservableObject {
    @Published var interstitial: GADInterstitialAd?
    let adUnitID: String = "ca-app-pub-9288291055014999/6789517081"
    var rootViewController: UIViewController?
    var completion: (() -> Void)?
    
    private var isLoading = false
    private var loadAttempts = 0
    private let maxAttempts = 5
    private let retryInterval: TimeInterval = 0.5
    
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
        
        if interstitial == nil {
            loadInterstitial() // If no ad is available, load one
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.tryPresentAd()
            }
        } else {
            tryPresentAd()
        }
    }
    
    private func tryPresentAd() {
        guard let interstitial = interstitial,
              let rootViewController = rootViewController else {
            print("No ad available to show or no root view controller, completing immediately")
            completion?()
            loadInterstitial() // Try to load for next time
            return
        }
        
        // İyileştirilmiş sunum kontrolü
        if rootViewController.presentedViewController != nil {
            print("View controller is already presenting, trying to find top-most controller...")
            
            // En üst controller'ı bulmaya çalış
            var topVC = rootViewController
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            
            // En üst controller üzerinden reklamı göster
            print("Presenting ad from top-most controller")
            interstitial.present(fromRootViewController: topVC)
            print("Ad is being presented from top controller.")
            return
        }
        
        print("Showing interstitial ad")
        interstitial.present(fromRootViewController: rootViewController)
        print("Ad is being presented.")
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Interstitial ad dismissed")
        self.interstitial = nil
        completion?()
        loadInterstitial() // Preload next ad
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial ad failed to present: \(error.localizedDescription)")
        self.interstitial = nil
        completion?()
        loadInterstitial() // Try to load again
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

