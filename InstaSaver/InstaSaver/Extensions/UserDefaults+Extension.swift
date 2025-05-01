import Foundation

extension UserDefaults {
    private enum Keys {
        static let specialOfferDismissedDate = "specialOfferDismissedDate"
        static let specialOfferShown = "specialOfferShown"
        static let specialOfferStartTime = "specialOfferStartTime"
        static let specialOfferEndTime = "specialOfferEndTime"
    }
    
    var specialOfferDismissedDate: Date? {
        get {
            return object(forKey: Keys.specialOfferDismissedDate) as? Date
        }
        set {
            set(newValue, forKey: Keys.specialOfferDismissedDate)
        }
    }
    
    var specialOfferStartTime: Date? {
        get {
            return object(forKey: Keys.specialOfferStartTime) as? Date
        }
        set {
            set(newValue, forKey: Keys.specialOfferStartTime)
        }
    }
    
    var specialOfferEndTime: Date? {
        get {
            let endTime = object(forKey: Keys.specialOfferEndTime) as? Date
            return endTime
        }
        set {
            set(newValue, forKey: Keys.specialOfferEndTime)
        }
    }
    
    var specialOfferShown: Bool {
        get {
            return bool(forKey: Keys.specialOfferShown)
        }
        set {
            set(newValue, forKey: Keys.specialOfferShown)
        }
    }
    
    func shouldShowSpecialOffer() -> Bool {
        // Eğer son gösterim tarihi varsa ve üzerinden 1 hafta geçmediyse gösterme
        if let dismissedDate = specialOfferDismissedDate {
            let daysElapsed = Calendar.current.dateComponents([.day], from: dismissedDate, to: Date()).day ?? 0
            if daysElapsed < 7 {
                return false
            }
        }
        
        // Eğer aktif bir teklif varsa göster
        if let endTime = specialOfferEndTime, Date() < endTime {
            return true
        }
        
        // Eğer hiç teklif başlatılmamışsa veya süresi dolmuşsa, yeni teklif göster
        return true
    }
    
    func getRemainingTime() -> Int {
        guard let endTime = specialOfferEndTime else {
            return 43200
        }
        let remaining = Int(endTime.timeIntervalSince(Date()))
        return max(0, remaining)
    }
    
    func initializeSpecialOfferTime() {
        if specialOfferEndTime == nil || (specialOfferEndTime ?? Date()) < Date() {
            let startTime = Date()
            let endTime = startTime.addingTimeInterval(43200) // 12 saat
            specialOfferStartTime = startTime
            specialOfferEndTime = endTime
        }
    }
} 