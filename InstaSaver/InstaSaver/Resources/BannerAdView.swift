// BannerAdView.swift

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-9288291055014999/6065013809"
    //    private let adUnitID = "ca-app-pub-3940256099942544/9214589741"
    //test unitID
    let adSize: GADAdSize = GADAdSizeBanner
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.delegate = context.coordinator // Delegate ataması
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // Gerekirse güncelleme işlemleri burada yapılabilir
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad yüklenemedi: \(error.localizedDescription)")
        }
        
        // İsteğe bağlı: Reklam başarıyla yüklendiğinde tetiklenir
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Banner ad başarıyla yüklendi.")
        }
    }
}
