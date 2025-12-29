//
//  InstaSaverApp.swift
//  InstaSaver
//
//  Created by Baki Uçan on 5.01.2025.
//

import SwiftUI
import RevenueCat
import GoogleMobileAds
import OneSignalFramework
import StoreKit
import AppTrackingTransparency
import UserMessagingPlatform

// Define a notification name for UMP completion
extension Notification.Name {
    static let umpFlowDidComplete = Notification.Name("umpFlowDidComplete")
}

@main
struct InstaSaverApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var interstitialAd = InterstitialAd()
    @Environment(\.screenSize) var screenSize
    @State private var isConnected = false
    @AppStorage("appLaunchCount") private var appLaunchCount = 0
    @AppStorage("lastReviewRequest") private var lastReviewRequest = Date.distantPast.timeIntervalSince1970
    @AppStorage("reviewRequestCount") private var reviewRequestCount = 0
    @AppStorage("hasReviewedApp") private var hasReviewedApp = false
    @StateObject private var configManager = ConfigManager.shared
    
    // MARK: - Paywall ile ilgili yeni state'ler
    @State private var showPaywall: Bool = false
    @State private var hasScheduledPaywall: Bool = false
    
    @State private var isAppInBackground = false // Uygulamanın arka planda olup olmadığını kontrol etmek için bir bayrak
    
    @StateObject private var specialOfferViewModel = SpecialOfferViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(
                        \.managedObjectContext,
                        persistenceController.container.viewContext
                    )
                    .environmentObject(subscriptionManager)
                    .preferredColorScheme(.light)
                    .environment(
                        \.screenSize,
                        UIScreen.main.bounds.size
                    )
                
                // Ad Loading Overlay - Reklam yüklenirken tüm uygulamayı kaplar
                if interstitialAd.isLoadingAd {
                    AdLoadingOverlayView()
                        .zIndex(999)
                }
            }
                .onAppear {
                    // Config'i yükleme artık ConfigManager init içinde yapılıyor
                    // configManager.reloadConfig()
                    // App launch count'u artır
                    appLaunchCount += 1
                    // ATT izni iste
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                        requestTrackingAuthorization()
                    }
                    // Review request kontrolü
                    checkAndRequestReview()
                    
                    // Listen for UMP completion notification
                    NotificationCenter.default.addObserver(forName: .umpFlowDidComplete, object: nil, queue: .main) { _ in
                        print("UMP flow completed notification received.")
                        // PRO kullanıcı kontrolü - Paywall ve Special Offer gösterme mantığını UMP tamamlandıktan sonra çalıştır
                    if !subscriptionManager.isUserSubscribed {
                        // Sadece ücretsiz kullanıcılar için paywall göster
                            if !hasScheduledPaywall { // Avoid scheduling multiple times
                            hasScheduledPaywall = true
                                // Schedule Paywall presentation (e.g., after 2 seconds)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                // Double-check subscription status before showing
                                if !subscriptionManager.isUserSubscribed {
                                    showPaywall = true
                                }
                            }
                        }
                    } else {
                            // PRO user, ensure paywall and special offer are hidden
                        showPaywall = false
                        specialOfferViewModel.isPresented = false
                        }
                    }
                    
                    // Uygulama açıldığında bildirimleri dinle
                    NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
                        isAppInBackground = true // Uygulama arka plana alındı
                    }
                    NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                        isAppInBackground = false // Uygulama ön plana alındı
                        // Uygulama geri döndüğünde config'i güncelle
                        configManager.fetchConfig()
                        
                        // Kısa bir gecikme ile abonelik durumunun güncellenmesini bekle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Güncellenmiş abonelik durumuna göre reklam kontrolü yap
                            if !subscriptionManager.isUserSubscribed {
                                showAdIfNeeded()
                            } else {
                                print("✅ Kullanıcı premium üye, reklam gösterilmiyor")
                            }
                        }
                    }
                    NotificationCenter.default.addObserver(forName: Notification.Name("ShowSpecialOffer"), object: nil, queue: .main) { _ in
                        // Eğer 1 hafta geçmediyse gösterme
                        if !specialOfferViewModel.isPresented && 
                           specialOfferViewModel.shouldShowSpecialOffer() && 
                           configManager.shouldShowDownloadButtons &&
                           !subscriptionManager.isUserSubscribed { // PRO kullanıcı kontrolü ekledik
                            specialOfferViewModel.isPresented = true
                        } else {
                            print("Special offer cannot be shown yet - 1 week cooling period is active or user is PRO")
                        }
                    }
                }
                // .fullScreenCover(isPresented: $specialOfferViewModel.isPresented) {
                //     SpecialOfferView(viewModel: specialOfferViewModel)
                // }
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallView()
                        .onDisappear {
                            // Paywall kapandığında ve daha önce gösterilmediyse Special Offer'ı göster
                            // if !specialOfferViewModel.defaults.specialOfferShown &&
                            //    specialOfferViewModel.shouldShowSpecialOffer() &&
                            //    (Locale.current.languageCode != "en" || configManager.shouldShowDownloadButtons) &&
                            //    !subscriptionManager.isUserSubscribed { // PRO kullanıcı kontrolü ekledik
                            //     specialOfferViewModel.isPresented = true
                            // }
                        }
                }
        }
    }
    
    init() {
        // Localization swizzling'i başlat
        Bundle.swizzleLocalization()
        
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_JLkyCPgqxTiOUDAJFOrIOsrEIoy")
    }
    
    // MARK: - App Store Review
    private func checkAndRequestReview() {
        // Review request logic removed from app launch
    }
    
    // MARK: - App Tracking Transparency
    private func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("Tracking authorization granted.")
            case .denied:
                print("Tracking authorization denied.")
            case .notDetermined:
                print("Tracking authorization not determined.")
            case .restricted:
                print("Tracking authorization restricted.")
            @unknown default:
                print("Tracking authorization unknown.")
            }
        }
    }
    
    private func showAdIfNeeded() {
        // Eğer Paywall veya SpecialOfferView açıksa reklam gösterme
        if showPaywall || specialOfferViewModel.isPresented {
            return
        }
        
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            let presentingViewController = rootViewController.presentedViewController ?? rootViewController
            if presentingViewController.presentedViewController == nil {
                interstitialAd.showAd(from: presentingViewController) {
                    print("Reklam gösterildi.")
                }
            } else {
                print("Başka bir view controller zaten sunuluyor.")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // Helper function to initialize Mobile Ads SDK
    func initializeMobileAdsSDK() {
        // Initialize the Google Mobile Ads SDK.
        DispatchQueue.main.async {
             GADMobileAds.sharedInstance().start(completionHandler: nil)
             print("Google Mobile Ads SDK initialized after UMP.")
        }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // UMP Consent Request
        let parameters = UMPRequestParameters()
        // Optional: Set debug settings for testing
        // #if DEBUG
        // let debugSettings = UMPDebugSettings()
        // // Add your test device identifier found in the console output
        // debugSettings.testDeviceIdentifiers = ["360CB643-85EC-48A4-80F1-051C8B71517D"] // <--- UPDATED with console ID
        // // Force geography for testing (e.g., .EEA or .notEEA)
        // debugSettings.geography = .EEA
        // parameters.debugSettings = debugSettings
        // #endif

        // Request consent information update
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] requestError in
            guard let self = self else { return }

            if let error = requestError {
                print("UMP Error requesting consent info update: \(error)")
                // Handle error, possibly initialize SDK anyway for non-personalized ads
                self.initializeMobileAdsSDK() // Initialize even on error
                return
            }

            // Load and present consent form if required
            UMPConsentForm.loadAndPresentIfRequired(from: application.windows.first?.rootViewController) { [weak self] loadAndPresentError in
                 guard let self = self else { return }

                 if let error = loadAndPresentError {
                     print("UMP Error loading or presenting form: \(error)")
                     // Handle error, possibly initialize SDK anyway
                 }

                 // Consent process is complete (or form not required/error occurred).
                 // Initialize Google Mobile Ads SDK HERE.
                 self.initializeMobileAdsSDK()

                 // Post notification that UMP flow is complete
                 NotificationCenter.default.post(name: .umpFlowDidComplete, object: nil)
                 print("Posted umpFlowDidComplete notification.")
            }
        }
        // --- End of UMP Consent Request ---

        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        
        // (2) OneSignal Initialize
        // Dokümandaki gibi: OneSignal.initialize("YOUR_ONESIGNAL_APP_ID", withLaunchOptions: launchOptions)
        OneSignal.initialize(
            "6bb0dc63-2244-411d-9f2f-bbd51b4e7ef8", // <-- Kendi OneSignal App ID
            withLaunchOptions: launchOptions
        )
        
        // (3) Kullanıcıdan bildirim izni istemek (doküman: requestPermission)
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: true)
        return true
    }
}
