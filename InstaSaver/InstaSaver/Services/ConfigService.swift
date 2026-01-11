import Foundation

// API'den gelecek yanıt için model
struct FeatureConfig: Codable {
    let x5t9: Bool?
    let hiBuFVer: Bool? // Eski alan (1.0.7 için)
    let hFor1_0_8: Bool? // 1.0.8 için
    let hFor1_0_9: Bool? // 1.0.9 için
    let version: String?
    let lastUpdated: String?
    let settings: SubscriptionConfig?
    
    enum CodingKeys: String, CodingKey {
        case x5t9
        case hiBuFVer
        case hFor1_0_8
        case hFor1_0_9
        case version
        case lastUpdated = "last_updated"
        case settings
    }
}

// Subscription configuration model
struct SubscriptionConfig: Codable {
    let offeringId: String
    let fallbackOfferingId: String?
    let showAnnual: Bool
    let showMonthly: Bool
    let showWeekly: Bool
    let preferredPackage: String // "annual", "monthly", "weekly"
    
    enum CodingKeys: String, CodingKey {
        case offeringId = "offering_id"
        case fallbackOfferingId = "fallback_offering_id"
        case showAnnual = "show_annual"
        case showMonthly = "show_monthly"
        case showWeekly = "show_weekly"
        case preferredPackage = "preferred_package"
    }
    
    // Default değerler
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        offeringId = try container.decode(String.self, forKey: .offeringId)
        fallbackOfferingId = try container.decodeIfPresent(String.self, forKey: .fallbackOfferingId)
        showAnnual = try container.decodeIfPresent(Bool.self, forKey: .showAnnual) ?? true
        showMonthly = try container.decodeIfPresent(Bool.self, forKey: .showMonthly) ?? true
        showWeekly = try container.decodeIfPresent(Bool.self, forKey: .showWeekly) ?? true
        preferredPackage = try container.decodeIfPresent(String.self, forKey: .preferredPackage) ?? "annual"
    }
}

// Config yönetimi için ObservableObject
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    @Published var showDownloadButtons: Bool = false
    @Published var subscriptionConfig: SubscriptionConfig?
    
    private let baseURL = "https://instasaver-api-v2.vercel.app/api/config"
    private let subscriptionConfigURL = "https://instasaver-api-v2.vercel.app/api/subscription-config"
    private let userDefaults = UserDefaults.standard
    private let cacheDuration: TimeInterval = 600 // 10 minutes
    
    // UserDefaults için anahtarlar
    private enum UserDefaultsKeys {
        static let showDownloadButtons = "config_showDownloadButtons"
        static let hiBuFVer = "config_hiBuFVer" // Eski alan (1.0.7 için)
        static let hFor1_0_8 = "config_hFor1_0_8" // 1.0.8 için
        static let hFor1_0_9 = "config_hFor1_0_9" // 1.0.9 için
        static let configVersion = "config_version"
        static let lastUpdated = "config_lastUpdated"
        static let lastFetchTime = "config_lastFetchTime"
        static let subscriptionConfig = "config_subscriptionConfig"
    }
    
    private init() {
        // Kayıtlı değerleri yükle
        loadSavedConfig()
        
        // Her açılışta direkt API'den yükle
        fetchConfig()
        fetchSubscriptionConfig()
    }
    
    // Kaydedilmiş config değerlerini yükle
    private func loadSavedConfig() {
        showDownloadButtons = userDefaults.bool(forKey: UserDefaultsKeys.showDownloadButtons)
        print("📱 Loaded from cache: x5t9 = \(showDownloadButtons)")
        
        // Load subscription config from cache
        if let subscriptionData = userDefaults.data(forKey: UserDefaultsKeys.subscriptionConfig),
           let config = try? JSONDecoder().decode(SubscriptionConfig.self, from: subscriptionData) {
            subscriptionConfig = config
            print("💳 Loaded subscription config from cache: offering = \(config.offeringId)")
        } else {
            // Default değerler eğer cache yoksa
            print("⚠️ No cached subscription config, will fetch from API")
        }
    }
    
    // Config değerlerini kaydet
    private func saveConfig(config: FeatureConfig) {
        if let x5t9 = config.x5t9 {
            userDefaults.set(x5t9, forKey: UserDefaultsKeys.showDownloadButtons)
        }
        if let hiBuFVer = config.hiBuFVer {
            userDefaults.set(hiBuFVer, forKey: UserDefaultsKeys.hiBuFVer)
        }
        if let hFor1_0_8 = config.hFor1_0_8 {
            userDefaults.set(hFor1_0_8, forKey: UserDefaultsKeys.hFor1_0_8)
        }
        if let hFor1_0_9 = config.hFor1_0_9 {
            userDefaults.set(hFor1_0_9, forKey: UserDefaultsKeys.hFor1_0_9)
        }
        if let version = config.version {
            userDefaults.set(version, forKey: UserDefaultsKeys.configVersion)
        }
        if let lastUpdated = config.lastUpdated {
            userDefaults.set(lastUpdated, forKey: UserDefaultsKeys.lastUpdated)
        }
        
        print("💾 Feature config saved to UserDefaults")
    }
    
    // Versiyon kontrolü yapan fonksiyon
    private func isVersion1_0_8() -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return appVersion == "1.0.8"
    }
    
    private func isVersion1_0_9() -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return appVersion == "1.0.9"
    }
    
    // Computed property that triggers UI updates
    var shouldShowDownloadButtons: Bool {
        let hFor109 = userDefaults.bool(forKey: UserDefaultsKeys.hFor1_0_9) // 1.0.9 için
        let hFor108 = userDefaults.bool(forKey: UserDefaultsKeys.hFor1_0_8) // 1.0.8 için
        let hiBuFVer = userDefaults.bool(forKey: UserDefaultsKeys.hiBuFVer)
        
        // Eğer hFor1_0_9 true ise ve versiyon 1.0.9 ise, butonları gizle
        if hFor109 && isVersion1_0_9() {
            return false
        }

        // Eğer hFor1_0_8 true ise ve versiyon 1.0.8 ise, butonları gizle
        if hFor108 && isVersion1_0_8() {
            return false
        }
      
        // Eğer hiBuFVer true ise, butonları gizle (1.0.7 ve öncesi)
        if hiBuFVer {
            return false
        }

        // Normal x5t9 kontrolü
        return showDownloadButtons
    }
    
    func fetchConfig(force: Bool = false) {
        // Check cache validity unless forced
        if !force, let lastFetch = userDefaults.object(forKey: UserDefaultsKeys.lastFetchTime) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastFetch)
            if elapsedTime < cacheDuration {
                let remainingTime = cacheDuration - elapsedTime
                let minutes = Int(remainingTime / 60)
                let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
                print("⏱️ Feature Config cache is valid. Skipping network request.")
                print("   Cache expires in: \(minutes)m \(seconds)s")
                return
            }
        }
        
        guard let url = URL(string: baseURL) else { 
            print("❌ Invalid URL: \(baseURL)")
            return 
        }
        
        print("🔗 Starting config fetch from: \(baseURL)")
        
        Task {
            do {
                print("📡 Making network request to: \(baseURL)")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Feature Config HTTP Status Code: \(httpResponse.statusCode)")
                    
                    // HTTP hata kodlarını kontrol et
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ Feature Config HTTP Error: \(httpResponse.statusCode)")
                        print("⚠️ Using cached values instead")
                        return
                    }
                }
                
                print("📡 Received \(data.count) bytes from feature config API")
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let config = try decoder.decode(FeatureConfig.self, from: data)
                
                print("🔧 Feature Config decoded successfully")
                print("📱 x5t9: \(config.x5t9 ?? false)")
                print("🚫 hFor1_0_8: \(config.hFor1_0_8 ?? false)")
                print("🚫 hFor1_0_9: \(config.hFor1_0_9 ?? false)")
                if let version = config.version {
                    print("📦 Version: \(version)")
                }
                
                await MainActor.run {
                    if let x5t9 = config.x5t9 {
                        self.showDownloadButtons = x5t9
                    }
                    self.saveConfig(config: config)
                    // Update fetch timestamp on successful fetch
                    self.userDefaults.set(Date(), forKey: UserDefaultsKeys.lastFetchTime)
                    self.objectWillChange.send()
                    
                    // Final durumu logla
                    let buttonVisibility = self.shouldShowDownloadButtons
                    print("✅ Feature config updated | Buttons visible: \(buttonVisibility)")
                }
            } catch {
                print("❌ Feature config error: \(error.localizedDescription)")
                print("⚠️ Using cached values")
            }
        }
    }
    
    func fetchSubscriptionConfig(force: Bool = false) {
        // Check cache validity unless forced
        if !force, let lastFetch = userDefaults.object(forKey: UserDefaultsKeys.lastFetchTime) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastFetch)
            if elapsedTime < cacheDuration {
                let remainingTime = cacheDuration - elapsedTime
                let minutes = Int(remainingTime / 60)
                let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
                print("⏱️ Subscription Config cache is valid. Skipping network request.")
                print("   Cache expires in: \(minutes)m \(seconds)s")
                return
            }
        }
        
        guard let url = URL(string: subscriptionConfigURL) else { 
            print("❌ Invalid subscription config URL: \(subscriptionConfigURL)")
            return 
        }
        
        print("🔗 Starting subscription config fetch from: \(subscriptionConfigURL)")
        
        Task {
            do {
                print("📡 Making subscription config request to: \(subscriptionConfigURL)")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Subscription Config HTTP Status Code: \(httpResponse.statusCode)")
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ Subscription Config HTTP Error: \(httpResponse.statusCode)")
                        print("⚠️ Using cached subscription config instead")
                        return
                    }
                }
                
                print("📡 Received \(data.count) bytes from subscription config API")
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let config = try decoder.decode(FeatureConfig.self, from: data)
                
                print("🔧 Subscription config decoded successfully")
                if let subConfig = config.settings {
                    print("💳 Offering: \(subConfig.offeringId) | Fallback: \(subConfig.fallbackOfferingId ?? "none")")
                    
                    await MainActor.run {
                        self.subscriptionConfig = subConfig
                        // Subscription config'i kaydet
                        if let data = try? JSONEncoder().encode(subConfig) {
                            self.userDefaults.set(data, forKey: UserDefaultsKeys.subscriptionConfig)
                        }
                        self.objectWillChange.send()
                        print("✅ Subscription config updated")
                    }
                }
            } catch {
                print("❌ Subscription config error: \(error.localizedDescription)")
                print("⚠️ Using cached subscription config")
            }
        }
    }
    
    // Config'i yeniden yükleme fonksiyonu
    func reloadConfig() {
        print("🔄 Reload configs requested (Forced)...")
        fetchConfig(force: true)
        fetchSubscriptionConfig(force: true)
    }
}
