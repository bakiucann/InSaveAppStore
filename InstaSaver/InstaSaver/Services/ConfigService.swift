import Foundation

// API'den gelecek yanıt için model
struct FeatureConfig: Codable {
    let x5t9: Bool
    let version: String
    let lastUpdated: String
}

// Config yönetimi için ObservableObject
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    @Published var showDownloadButtons: Bool = false
    
    private let baseURL = "https://instagramcoms.vercel.app/api/config"
    private let minimumFetchInterval: TimeInterval = 3600 // 1 saat (saniye cinsinden)
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults için anahtarlar
    private enum UserDefaultsKeys {
        static let showDownloadButtons = "config_showDownloadButtons"
        static let configVersion = "config_version"
        static let lastUpdated = "config_lastUpdated"
        static let lastFetchTime = "config_lastFetchTime"
    }
    
    private init() {
        // Kayıtlı değerleri yükle
        loadSavedConfig()
        
        // İlk başlangıçta config'i direkt olarak API'den yükle
        fetchConfig()
    }
    
    // Kaydedilmiş config değerlerini yükle
    private func loadSavedConfig() {
        showDownloadButtons = userDefaults.bool(forKey: UserDefaultsKeys.showDownloadButtons)
        print("📱 Loaded from cache: x5t9 = \(showDownloadButtons)")
    }
    
    // Config değerlerini kaydet
    private func saveConfig(config: FeatureConfig) {
        userDefaults.set(config.x5t9, forKey: UserDefaultsKeys.showDownloadButtons)
        userDefaults.set(config.version, forKey: UserDefaultsKeys.configVersion)
        userDefaults.set(config.lastUpdated, forKey: UserDefaultsKeys.lastUpdated)
        userDefaults.set(Date().timeIntervalSince1970, forKey: UserDefaultsKeys.lastFetchTime)
        
        print("💾 Config saved to UserDefaults")
    }
    
    // Gerekirse config'i yeniden yükle
    private func fetchConfigIfNeeded() {
        let lastFetchTime = userDefaults.double(forKey: UserDefaultsKeys.lastFetchTime)
        let currentTime = Date().timeIntervalSince1970
        
        // Son yüklemeden beri yeterli süre geçtiyse yeniden yükle
        if currentTime - lastFetchTime > minimumFetchInterval {
            print("🕒 Fetch interval exceeded, fetching new config...")
            fetchConfig()
        } else {
            print("⏱️ Using cached config, next fetch available in \(Int(minimumFetchInterval - (currentTime - lastFetchTime))) seconds")
        }
    }
    
    func fetchConfig() {
        guard let url = URL(string: baseURL) else { 
            print("❌ Invalid URL: \(baseURL)")
            return 
        }
        
        print("🔗 Starting config fetch from: \(baseURL)")
        
        Task {
            do {
                print("📡 Making network request...")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    
                    // HTTP hata kodlarını kontrol et
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ HTTP Error: \(httpResponse.statusCode)")
                        print("⚠️ Using cached values instead")
                        return
                    }
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let config = try decoder.decode(FeatureConfig.self, from: data)
                
                print("🔧 Config decoded successfully")
                print("📱 x5t9: \(config.x5t9)")
                print("📦 Version: \(config.version)")
                print("🕒 Last Updated: \(config.lastUpdated)")
                
                await MainActor.run {
                    self.showDownloadButtons = config.x5t9
                    self.objectWillChange.send()
                    self.saveConfig(config: config)
                }
            } catch {
                print("❌ Config error:", error)
                print("⚠️ Using cached values instead")
                
                if let decodingError = error as? DecodingError {
                    print("🔍 Decoding error details:", decodingError)
                }
                
                // URLError detayları
                if let urlError = error as? URLError {
                    print("🌐 URL Error Code:", urlError.code)
                    print("🌐 URL Error Description:", urlError.localizedDescription)
                }
            }
        }
    }
    
    // Config'i yeniden yükleme fonksiyonu - artık minimum süre kontrolü yapıyor
    func reloadConfig() {
        print("🔄 Reload config requested...")
        fetchConfigIfNeeded()
    }
    
    // Hemen yükleme yapmaya zorlayan fonksiyon (gerekirse)
    func forceReloadConfig() {
        print("⚠️ Force reload config...")
        fetchConfig()
    }
}