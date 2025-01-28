//
//  SubscriptionManager.swift
//  
//
//  Created by Baki Uçan on 12.09.2024.
//

import Foundation
import RevenueCat

class SubscriptionManager: ObservableObject {
    @Published var isUserSubscribed: Bool = false
    
    init() {
        checkSubscriptionStatus()
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            if let customerInfo = customerInfo {
                // Abonelik durumu kontrolü ve terminale yazdırma
                if customerInfo.entitlements.active["pro"] != nil {
                    self?.isUserSubscribed = true
                    print("Kullanıcı pro abonelik aktif: \(self?.isUserSubscribed ?? false)")
                } else {
                    self?.isUserSubscribed = false 
                    print("Kullanıcı pro abonelik yok: \(self?.isUserSubscribed ?? false)")
                }
            } else {
                print("Abonelik durumu alınırken hata oluştu: \(String(describing: error))")
            }
        }
    }
}
