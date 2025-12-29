import Foundation
import SwiftUI
import ObjectiveC

// Localization Manager - ConfigManager ile entegre olarak çalışır
class LocalizationManager {
    static let shared = LocalizationManager()
    private let configManager = ConfigManager.shared
    
    private init() {}
    
    // Ana localization fonksiyonu
    func localizedString(forKey key: String, comment: String) -> String {
        let originalString = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        
        // shouldShowDownloadButtons kontrolü
        if !configManager.shouldShowDownloadButtons {
            // Download ile ilgili kelimeleri değiştir
            let modifiedString = originalString
                .replacingOccurrences(of: "Download", with: "Bookmark")
                .replacingOccurrences(of: "download", with: "bookmark")
                .replacingOccurrences(of: "Save", with: "Bookmark")
                .replacingOccurrences(of: "save", with: "bookmark")
                .replacingOccurrences(of: "saved", with: "bookmarked")
                .replacingOccurrences(of: "Saved", with: "Bookmarked")
                .replacingOccurrences(of: "saving", with: "bookmarking")
                .replacingOccurrences(of: "Saving", with: "Bookmarking")
            
            return modifiedString
        }
        
        return originalString
    }
}

// NSLocalizedString için swizzling
extension Bundle {
    private static var swizzled = false
    
    static func swizzleLocalization() {
        if swizzled {
            return
        }
        
        swizzled = true
        
        let originalSelector = #selector(Bundle.localizedString(forKey:value:table:))
        let swizzledSelector = #selector(Bundle.swizzledLocalizedString(forKey:value:table:))
        
        guard let originalMethod = class_getInstanceMethod(Bundle.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(Bundle.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc private func swizzledLocalizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let string = self.swizzledLocalizedString(forKey: key, value: value, table: tableName)
        
        // Sadece ana bundle için uygula
        if self == Bundle.main {
            // shouldShowDownloadButtons kontrolü
            if !ConfigManager.shared.shouldShowDownloadButtons {
                return string
                    .replacingOccurrences(of: "Download", with: "Bookmark")
                    .replacingOccurrences(of: "download", with: "bookmark")
                    .replacingOccurrences(of: "Save", with: "Bookmark")
                    .replacingOccurrences(of: "save", with: "bookmark")
                    .replacingOccurrences(of: "saved", with: "bookmarked")
                    .replacingOccurrences(of: "Saved", with: "Bookmarked")
                    .replacingOccurrences(of: "saving", with: "bookmarking")
                    .replacingOccurrences(of: "Saving", with: "Bookmarking")
            }
        }
        
        return string
    }
}

// Alternatif yaklaşım: String extension kullanarak daha kısa bir yol
extension String {
    var localized: String {
        let originalString = NSLocalizedString(self, comment: "")
        
        // shouldShowDownloadButtons kontrolü
        if !ConfigManager.shared.shouldShowDownloadButtons {
            return originalString
                .replacingOccurrences(of: "Download", with: "Bookmark")
                .replacingOccurrences(of: "download", with: "bookmark")
                .replacingOccurrences(of: "Save", with: "Bookmark")
                .replacingOccurrences(of: "save", with: "bookmark")
                .replacingOccurrences(of: "saved", with: "bookmarked")
                .replacingOccurrences(of: "Saved", with: "Bookmarked")
                .replacingOccurrences(of: "saving", with: "bookmarking")
                .replacingOccurrences(of: "Saving", with: "Bookmarking")
        }
        
        return originalString
    }
}

// NSLocalizedString fonksiyonu için genel bir alternatif
func AppLocalizedString(_ key: String, comment: String = "") -> String {
    return LocalizationManager.shared.localizedString(forKey: key, comment: comment)
} 