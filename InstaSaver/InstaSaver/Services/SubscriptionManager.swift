//
//  SubscriptionManager.swift
//  
//
//  Created by Baki Uçan on 12.09.2024.
//

import Foundation
import RevenueCat

final class SubscriptionManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = SubscriptionManager()
    
    @Published var isUserSubscribed: Bool = false
    
    private let subscriptionStatusKey = "cached_subscription_status"
    private let subscriptionStatusDateKey = "cached_subscription_status_date"
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour cache
    
    private override init() {
        super.init()
        Purchases.shared.delegate = self
        
        // Load cached value immediately (non-blocking)
        loadCachedSubscriptionStatus()
        
        // Fetch fresh status in background (non-blocking)
        Task.detached(priority: .utility) { [weak self] in
            await self?.checkSubscriptionStatus()
        }
    }
    
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateSubscriptionStatus(with: customerInfo)
    }
    
    /// Load cached subscription status immediately (synchronous, fast)
    private func loadCachedSubscriptionStatus() {
        let defaults = UserDefaults.standard
        
        // Check if cache is still valid
        if let cachedDate = defaults.object(forKey: subscriptionStatusDateKey) as? Date {
            let cacheAge = Date().timeIntervalSince(cachedDate)
            if cacheAge < cacheValidityDuration {
                // Cache is valid, use it
                let cachedStatus = defaults.bool(forKey: subscriptionStatusKey)
                DispatchQueue.main.async { [weak self] in
                    self?.isUserSubscribed = cachedStatus
                    print("📦 Loaded cached subscription status: \(cachedStatus)")
                }
                return
            }
        }
        
        // No valid cache, default to false (non-subscribed)
        // This allows app to load immediately without waiting for network
        print("📦 No valid cache, using default: false")
    }
    
    /// Check subscription status with timeout (background task)
    private func checkSubscriptionStatus() async {
        await withTaskGroup(of: Void.self) { group in
            // Start the actual operation
            group.addTask {
                do {
                    let customerInfo = try await Purchases.shared.customerInfo()
                    await MainActor.run {
                        self.updateSubscriptionStatus(with: customerInfo)
                    }
                } catch {
                    print("⚠️ Error fetching customer info: \(error.localizedDescription)")
                    // Fail silently - keep cached/default value
                }
            }
            
            // Add timeout task (3 seconds)
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                print("⏱️ Subscription check timeout after 3 seconds - using cached/default value")
            }
            
            // Wait for first completion (either success or timeout)
            _ = await group.next()
            group.cancelAll()
        }
    }
    
    private func updateSubscriptionStatus(with customerInfo: CustomerInfo) {
        let isSubscribed = customerInfo.entitlements.active.keys.contains("pro")
        
        // Cache the status
        let defaults = UserDefaults.standard
        defaults.set(isSubscribed, forKey: subscriptionStatusKey)
        defaults.set(Date(), forKey: subscriptionStatusDateKey)
        
        // Update published property on main thread
        if self.isUserSubscribed != isSubscribed {
            self.isUserSubscribed = isSubscribed
            print("✅ Subscription status updated: \(isSubscribed)")
        }
    }
}
