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

@main
struct InstaSaverApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var interstitialAd = InterstitialAd()
    @Environment(\.screenSize) var screenSize
    @State private var isConnected = false
    @AppStorage("appLaunchCount") private var appLaunchCount = 0
    @AppStorage("lastReviewRequest") private var lastReviewRequest = Date.distantPast.timeIntervalSince1970
    @AppStorage("reviewRequestCount") private var reviewRequestCount = 0
    @AppStorage("hasReviewedApp") private var hasReviewedApp = false
    
    // MARK: - Paywall ile ilgili yeni state'ler
    @State private var showPaywall: Bool = false
    @State private var hasScheduledPaywall: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if isConnected {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(subscriptionManager)
                    .preferredColorScheme(.light)
                    .environment(\.screenSize, UIScreen.main.bounds.size)
                
                    .onAppear {
                        // App launch count'u artır
                        appLaunchCount += 1
                        
                        // ATT izni iste
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            requestTrackingAuthorization()
                        }
                        
                        // Review request kontrolü
                        checkAndRequestReview()
                        
                        // Eğer kullanıcı Pro değilse paywall göster
                        guard !subscriptionManager.isUserSubscribed else { return }
                        
                        // Sadece bir defaya mahsus 3 saniye bekleyerek paywall'ı tetiklemek istiyoruz
                        if !hasScheduledPaywall {
                            hasScheduledPaywall = true
                            
                            // 3 saniye bekleme
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showPaywall = true
                            }
                        }
                    }
                // Paywall'ı tam ekran kaplama olarak açıyoruz
                    .fullScreenCover(isPresented: $showPaywall) {
                        PaywallView()
                    }
                // Opsiyonel: .sheet isPresented da kullanabilirsiniz
                /*
                 .sheet(isPresented: $showPaywall) {
                 PaywallView()
                 }
                 */
                
                // Reklamla ilgili mevcut kodlarınız
                    .onAppear {
                        if !subscriptionManager.isUserSubscribed {
                            NotificationCenter.default.addObserver(
                                forName: UIApplication.didBecomeActiveNotification,
                                object: nil,
                                queue: .main
                            ) { _ in
                                // Paywall açıkken reklam göstermeyi engelle
                                guard !showPaywall else { return }
                                
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
                    }
            } else {
                SplashView(isConnected: $isConnected)
            }
        }
    }
    
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_JLkyCPgqxTiOUDAJFOrIOsrEIoy")
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    // MARK: - App Store Review
    private func checkAndRequestReview() {
        // Son review request'ten bu yana en az 7 gün geçmiş olmalı
        let daysSinceLastRequest = Date().timeIntervalSince1970 - lastReviewRequest
        let minimumDaysBetweenRequests: TimeInterval = 7 * 24 * 60 * 60 // 7 gün
        
        // Review request koşulları:
        // 1. Uygulama en az 3 kez açılmış VEYA
        // 2. Son review request'ten bu yana en az 7 gün geçmiş olmalı
        if appLaunchCount >= 3 || daysSinceLastRequest >= minimumDaysBetweenRequests {
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                    // Review request tarihini güncelle
                    lastReviewRequest = Date().timeIntervalSince1970
                    // Launch count'u sıfırla
                    appLaunchCount = 0
                }
            }
        }
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
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
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
