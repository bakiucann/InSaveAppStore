import Foundation
import SwiftUI
import RevenueCat
import Combine

class SpecialOfferViewModel: ObservableObject {
    @Published var isPresented = false {
        didSet {
            if isPresented {
                defaults.initializeSpecialOfferTime()
                startTimer()
                updateTimer()
                // Fetch packages when view is about to be shown
                fetchPackagesIfNeeded()
            }
        }
    }
    @Published var packages: [Package] = []
    @Published var selectedPackage: Package?
    @Published var showLoading = false
    @Published var timerString: String = "12:00:00"
    
    // Alert için değişkenler
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    let defaults = UserDefaults.standard
    private var timer: AnyCancellable?
    
    // SubscriptionManager nesnesi
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    init() {
        // ❌ REMOVED: fetchSpecialOfferPackages() from init
        // Packages will be fetched on-demand when needed
    }
    
    /// Fetch packages when actually needed (e.g., when showing special offer)
    func fetchPackagesIfNeeded() {
        guard packages.isEmpty else { return } // Already fetched
        fetchSpecialOfferPackages()
    }
    
    func checkSpecialOffer() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                let isPro = customerInfo.entitlements["pro"]?.isActive ?? false
                
                if !isPro {
                    let shouldShow = defaults.shouldShowSpecialOffer()
                    DispatchQueue.main.async {
                        self.isPresented = shouldShow
                    }
                    print("Check Special Offer called. shouldShow: \(shouldShow), isPro: \(isPro)")
                } else {
                    DispatchQueue.main.async {
                        self.isPresented = false
                    }
                    print("User is PRO, special offer will not be shown")
                }
            } catch {
                print("Error checking subscription status: \(error.localizedDescription)")
            }
        }
    }
    
    func dismissOffer() {
        if Date() >= defaults.specialOfferEndTime ?? Date() {
            defaults.specialOfferDismissedDate = Date()
        }
        defaults.specialOfferShown = true
        isPresented = false
        print("Dismiss Offer called. isPresented: \(isPresented)")
        timer?.cancel()
    }
    
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    private func updateTimer() {
        print("UpdateTimer called")
        if defaults.specialOfferEndTime == nil {
            print("No end time found, initializing special offer time")
            defaults.initializeSpecialOfferTime()
        }
        
        guard let endTime = defaults.specialOfferEndTime else {
            print("Still no end time found after initialization")
            return
        }
        
        let currentTime = Date()
        if currentTime >= endTime {
            print("Timer expired, dismissing offer")
            dismissOffer()
            return
        }
        
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: currentTime, to: endTime)
        
        print("End Time: \(endTime)")
        print("Current Time: \(currentTime)")
        print("Time Components: \(components)")
        
        if let hours = components.hour,
           let minutes = components.minute,
           let seconds = components.second {
            let newTimerString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            if timerString != newTimerString {
                timerString = newTimerString
            }
        }
    }
    
    func acceptOffer() {
        guard let package = selectedPackage else { return }
        showLoading = true
        
        Purchases.shared.purchase(package: package) { [weak self] (transaction, customerInfo, error, userCancelled) in
            DispatchQueue.main.async {
                self?.showLoading = false
                if let error = error {
                    print("Error purchasing package: \(error.localizedDescription)")
                    self?.alertTitle = NSLocalizedString("Purchase Failed", comment: "")
                    self?.alertMessage = NSLocalizedString("Failed to complete the purchase. Please try again later.", comment: "")
                    self?.showAlert = true
                } else if customerInfo?.entitlements["pro"]?.isActive == true {
                    self?.alertTitle = NSLocalizedString("Success", comment: "")
                    self?.alertMessage = NSLocalizedString("Thank you for your purchase!", comment: "")
                    self?.showAlert = true
                    
                    // Abonelik durumunu güncelle
                    self?.subscriptionManager.isUserSubscribed = true
                    
                    // Abonelik değişikliğini bildir
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"), object: nil)
                    
                    // Tamamlandığında kapat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.defaults.specialOfferShown = true
                        self?.isPresented = false
                    }
                } else if userCancelled {
                    print("User cancelled the purchase.")
                }
            }
        }
    }
    
    func restorePurchases(completion: ((Bool) -> Void)? = nil) {
        showLoading = true
        Purchases.shared.restorePurchases { [weak self] (customerInfo, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showLoading = false
                
                if let error = error {
                    print("Error restoring purchases: \(error.localizedDescription)")
                    self.alertTitle = NSLocalizedString("Restore Failed", comment: "")
                    self.alertMessage = NSLocalizedString("Failed to restore purchases. Please try again later.", comment: "")
                    self.showAlert = true
                    completion?(false)
                } else if let customerInfo = customerInfo,
                          customerInfo.entitlements["pro"]?.isActive == true {
                    // Başarılı restore
                    self.alertTitle = NSLocalizedString("Success", comment: "")
                    self.alertMessage = NSLocalizedString("Your purchases have been successfully restored!", comment: "")
                    self.showAlert = true
                    
                    // Abonelik durumunu güncelle
                    self.subscriptionManager.isUserSubscribed = true
                    
                    // Abonelik değişikliğini bildir
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"), object: nil)
                    
                    // Kapat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.defaults.specialOfferShown = true
                        self.isPresented = false
                    }
                    completion?(true)
                } else {
                    // Restore edilecek satın alım bulunamadı
                    print("No active entitlement found during restore.")
                    self.alertTitle = NSLocalizedString("No Purchases Found", comment: "")
                    self.alertMessage = NSLocalizedString("No previous purchases were found to restore.", comment: "")
                    self.showAlert = true
                    completion?(false)
                }
            }
        }
    }
    
    func fetchSpecialOfferPackages() {
        // Use background task with timeout
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            await withTaskGroup(of: Void.self) { group in
                // Start the actual operation
                group.addTask {
                    do {
                        let offerings = try await Purchases.shared.offerings()
                        if let discountOffering = offerings.offering(identifier: "discount") {
                            let fetchedPackages = discountOffering.availablePackages
                            await MainActor.run {
                                self.packages = fetchedPackages
                                if let annualPackage = fetchedPackages.first(where: { 
                                    $0.storeProduct.subscriptionPeriod?.unit == .year 
                                }) {
                                    self.selectedPackage = annualPackage
                                } else {
                                    self.selectedPackage = fetchedPackages.first
                                }
                            }
                        }
                    } catch {
                        print("⚠️ Error fetching special offer packages: \(error.localizedDescription)")
                        // Fail silently - packages remain empty
                    }
                }
                
                // Add timeout task (3 seconds)
                group.addTask {
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                    print("⏱️ Special offer packages fetch timeout - using empty packages")
                }
                
                // Wait for first completion
                _ = await group.next()
                group.cancelAll()
            }
        }
    }
    
    func shouldShowSpecialOffer() -> Bool {
        if let dismissedDate = defaults.specialOfferDismissedDate {
            let daysElapsed = Calendar.current.dateComponents([.day], from: dismissedDate, to: Date()).day ?? 0
            if daysElapsed < 7 {
                return false
            }
        }
        
        if let endTime = defaults.specialOfferEndTime, Date() < endTime {
            return true
        }
        
        return true
    }
    
    deinit {
        timer?.cancel()
    }
} 
