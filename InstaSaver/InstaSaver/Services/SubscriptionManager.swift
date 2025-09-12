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
    
    private override init() {
        super.init()
        Purchases.shared.delegate = self
        checkSubscriptionStatus()
    }
    
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateSubscriptionStatus(with: customerInfo)
    }
    
    private func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            if let customerInfo = customerInfo {
                self?.updateSubscriptionStatus(with: customerInfo)
            } else if let error = error {
                print("Error fetching customer info: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateSubscriptionStatus(with customerInfo: CustomerInfo) {
        let isSubscribed = customerInfo.entitlements.active.keys.contains("pro")
        
        if self.isUserSubscribed != isSubscribed {
            self.isUserSubscribed = isSubscribed
            print("Subscription status updated: \(isSubscribed)")
        }
    }
}
