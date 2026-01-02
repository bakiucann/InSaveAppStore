// DownloadManager.swift
// InstaSaver uygulaması için indirme yöneticisi

import Foundation
import Alamofire
import UIKit
import CryptoKit

// String için MD5 hash extension
extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}

// Özel Retry Policy - Alamofire için tekrar deneme stratejisi
final class RetryPolicy: RequestInterceptor {
    // Maksimum tekrar deneme sayısı
    private let maxRetryCount = 3
    
    // Tekrar deneme zamanları (artan gecikmelerle)
    private let retryDelay: TimeInterval = 1
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // Mevcut deneme sayısı
        let retryCount = request.retryCount
        
        // Belirli hata tipleri için tekrar dene
        let shouldRetry = shouldRetryRequest(for: request, dueTo: error)

        // Maksimum deneme sayısını aşmadıysa ve hata tekrar denenebilir ise
        if retryCount < maxRetryCount && shouldRetry {
            // Artan gecikme ile tekrar dene (1s, 2s, 4s, ...)
            let delay = calculateDelay(for: retryCount)
            print("🔄 Ağ hatası nedeniyle tekrar deneniyor: \(retryCount + 1)/\(maxRetryCount) - \(error.localizedDescription)")
            completion(.retryWithDelay(delay))
        } else {
            print("❌ Maksimum tekrar deneme sayısına ulaşıldı veya tekrar denenebilir hata değil: \(error.localizedDescription)")
            completion(.doNotRetry)
        }
    }
    
    // Hangi hata tipleri için tekrar denenmeli?
    private func shouldRetryRequest(for request: Request, dueTo error: Error) -> Bool {
        // URLError hata kodları için kontrol
        let nsError = error as NSError
        
        if nsError.domain == NSURLErrorDomain {
            // Ağ hatalarını tekrar dene
            switch nsError.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorResourceUnavailable,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorInternationalRoamingOff,
                 NSURLErrorCallIsActive,
                 NSURLErrorDataNotAllowed,
                 NSURLErrorSecureConnectionFailed:
                return true
            default:
                return false
            }
        }
        
        // Özel HTTP cevap kodu kontrolleri
        if let response = request.response {
            // 5xx sunucu hataları için tekrar dene
            if (500...599).contains(response.statusCode) {
                return true
            }
            
            // Rate limit aşımı (429) veya geçici yönlendirme (3xx) için tekrar dene
            if response.statusCode == 429 || (300...399).contains(response.statusCode) {
                return true
            }
        }
        
        return false
    }
    
    // Exponential backoff algoritması ile gecikme hesapla
    private func calculateDelay(for retryCount: Int) -> TimeInterval {
        // 2^retryCount * retryDelay ile artan gecikme (1, 2, 4, 8, ...)
        return pow(2.0, Double(retryCount)) * retryDelay
    }
}

// MARK: - DownloadManager Sınıfı
class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadStatus] = [:]
    
    // Retry mekanizması için maksimum deneme sayısı
    private let maxRetryCount = 3
    
    struct DownloadStatus {
        var progress: Double
        var isCompleted: Bool
        var error: Error?
        var isPhoto: Bool
        var localURL: URL?
        var retryCount: Int = 0
    }
    
    // Arkaplan görevi yönetimi
    private var backgroundTasks: [String: UIBackgroundTaskIdentifier] = [:]
    
    private let sessionManager: Session = {
        let configuration = URLSessionConfiguration.default
        
        // Timeout sürelerini optimize et - yavaş internet için daha uzun süreler
        configuration.timeoutIntervalForRequest = 120 // Yavaş internet için 2 dakika
        configuration.timeoutIntervalForResource = 600 // Toplam indirme süresi 10 dakika (yavaş internet için)
        
        // Performans iyileştirmeleri
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 10 // Paralel bağlantı sayısını artır
        configuration.httpShouldUsePipelining = true // HTTP pipelining'i etkinleştir
        configuration.requestCachePolicy = .returnCacheDataElseLoad // Önbellek kullanımını etkinleştir
        
        // HTTP/2 protokolünü tercih et
        configuration.multipathServiceType = .handover // Daha iyi ağ kullanımı
        
        // Sıkıştırma kullanımını etkinleştir
        configuration.httpAdditionalHeaders = [
            "Accept-Encoding": "gzip, deflate, br",
            "Accept": "*/*"
        ]
        
        // Performans için öncelik belirle
        configuration.networkServiceType = .responsiveData // İndirmeler için öncelik ver
        
        // Arkaplan görevleri için yapılandırma
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        
        // SSL sertifika doğrulaması tamamen devre dışı - CustomServerTrustManager kullan
        return Session(
            configuration: configuration,
            serverTrustManager: CustomServerTrustManager()
        )
    }()
    
    private init() {
        // Singleton init
        print("🚀 DownloadManager initialized")
    }
    
    // Arkaplan görevi başlatma
    func beginBackgroundTask(for identifier: String) {
        let taskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask(for: identifier)
        }
        
        backgroundTasks[identifier] = taskID
        print("🔄 Arkaplan görevi başlatıldı: \(identifier)")
    }
    
    // Arkaplan görevini sonlandırma
    func endBackgroundTask(for identifier: String) {
        if let taskID = backgroundTasks[identifier], taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
            backgroundTasks.removeValue(forKey: identifier)
            print("✅ Arkaplan görevi sonlandırıldı: \(identifier)")
        }
    }
    
    // İçerik indirme fonksiyonu (fotoğraf veya video)
    func downloadContent(urlString: String, isPhoto: Bool, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "com.instasaver.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
            completion(.failure(error))
            return
        }
        
        // Arkaplan görevini başlat
        beginBackgroundTask(for: urlString)
        
        // İndirme durumunu başlat
        activeDownloads[urlString] = DownloadStatus(progress: 0, isCompleted: false, error: nil, isPhoto: isPhoto, localURL: nil)
        
        // Hedef dosya yolunu belirle ve önbelleği kontrol et
        let fileExtension = isPhoto ? "jpg" : "mp4"
        let fileName = "instasaver_\(Date().timeIntervalSince1970).\(fileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Önbellek kontrolü - aynı URL'den daha önce indirme yapıldı mı?
        let cacheKey = url.absoluteString.md5Hash
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedFile = cacheDir.appendingPathComponent("\(cacheKey).\(fileExtension)")
        
        // Önbellekte var mı kontrol et
        if FileManager.default.fileExists(atPath: cachedFile.path) {
            do {
                try FileManager.default.copyItem(at: cachedFile, to: fileURL)
                DispatchQueue.main.async {
                    print("🔄 Önbellekten yükleniyor: \(urlString)")
                    self.activeDownloads[urlString]?.isCompleted = true
                    self.activeDownloads[urlString]?.localURL = fileURL
                    self.activeDownloads[urlString]?.progress = 1.0
                    progressHandler(1.0)
                    completion(.success(fileURL))
                    self.endBackgroundTask(for: urlString)
                }
                return
            } catch {
                // Önbellekten kopyalama başarısız olursa indirmeye devam et
                print("⚠️ Önbellekten kopyalama başarısız: \(error.localizedDescription)")
            }
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            // Varolan dosyayı sil
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        print("🚀 İndirme başladı: \(urlString)")
        print("📷 İçerik türü: \(isPhoto ? "Fotoğraf" : "Video")")
        
        // İsteklere ek başlıklar ekle
        let headers: HTTPHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Accept-Language": "en-US,en;q=0.9,tr;q=0.8",
            "Connection": "keep-alive"
        ]
        
        // Alamofire ile indirme işlemini başlat
        sessionManager.download(url, method: .get, headers: headers, interceptor: RetryPolicy(), requestModifier: { request in
            // Çerezleri kabul et
            request.httpShouldHandleCookies = true
            // Önbelleği kullan
            request.cachePolicy = .returnCacheDataElseLoad
        }, to: destination)
        .downloadProgress { progress in
            DispatchQueue.main.async {
                let progressValue = progress.fractionCompleted
                self.activeDownloads[urlString]?.progress = progressValue
                progressHandler(progressValue)
                print("⏳ İndirme ilerlemesi: %\(Int(progressValue * 100))")
            }
        }
        .responseData { response in
            // İşlem tamamlandığında arkaplan görevini sonlandır
            self.endBackgroundTask(for: urlString)
            
            switch response.result {
            case .success:
                guard let fileURL = response.fileURL else {
                    let error = NSError(domain: "com.instasaver.error", code: -2, userInfo: [NSLocalizedDescriptionKey: "İndirme tamamlandı ancak dosya bulunamadı"])
                    DispatchQueue.main.async {
                        self.activeDownloads[urlString]?.error = error
                        completion(.failure(error))
                    }
                    return
                }
                
                // Başarıyla indirilen dosyayı önbelleğe kaydet
                do {
                    try FileManager.default.copyItem(at: fileURL, to: cachedFile)
                    print("✅ Dosya önbelleğe kaydedildi: \(cachedFile.path)")
                } catch {
                    print("⚠️ Önbelleğe kaydetme başarısız: \(error.localizedDescription)")
                }
                
                // İşlem başarılı
                DispatchQueue.main.async {
                    self.activeDownloads[urlString]?.isCompleted = true
                    self.activeDownloads[urlString]?.localURL = fileURL
                    print("✅ İndirme başarılı: \(fileURL.path)")
                    completion(.success(fileURL))
                }
                
            case .failure(let error):
                // Hata durumunda - yavaş internet için özel kontrol
                let nsError = error as NSError
                print("❌ İndirme hatası: \(error.localizedDescription), domain: \(nsError.domain), code: \(nsError.code)")
                
                // Yavaş internet durumunda timeout hatalarını tekrar dene
                // NSURLErrorTimedOut = -1001
                let isTimeoutError = nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut
                
                // Özel retry mekanizması
                let currentRetryCount = self.activeDownloads[urlString]?.retryCount ?? 0
                
                // Timeout hatalarında daha fazla retry yap
                let maxRetries = isTimeoutError ? (self.maxRetryCount + 2) : self.maxRetryCount
                
                if currentRetryCount < maxRetries {
                    // Retry count'u artır
                    self.activeDownloads[urlString]?.retryCount = currentRetryCount + 1
                    
                    print("🔄 Yeniden deneniyor (\(currentRetryCount + 1)/\(maxRetries))... \(isTimeoutError ? "(Timeout hatası)" : "")")
                    
                    // Timeout hatalarında daha uzun gecikme (yavaş internet için)
                    let delay = isTimeoutError ? 2.0 : 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // Mevcut indirmeyi kaldırmadan devam et (aynı download'u kullan)
                        self.downloadContent(urlString: urlString, isPhoto: isPhoto, progressHandler: progressHandler, completion: completion)
                    }
                } else {
                    // Gerçekten başarısız oldu
                    print("❌ Maksimum retry sayısına ulaşıldı, indirme başarısız")
                    DispatchQueue.main.async {
                        self.activeDownloads[urlString]?.error = error
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // İndirmeyi iptal etme
    func cancelDownload(for urlString: String) {
        sessionManager.session.getAllTasks { tasks in
            tasks.filter { task in
                if let originalRequest = task.originalRequest,
                   let url = originalRequest.url,
                   url.absoluteString == urlString {
                    return true
                }
                return false
            }.forEach { $0.cancel() }
        }
        
        // Arkaplan görevini sonlandır
        endBackgroundTask(for: urlString)
        activeDownloads.removeValue(forKey: urlString)
    }
    
    // Tüm indirmeleri iptal et
    func cancelAllDownloads() {
        sessionManager.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        
        // Tüm arkaplan görevlerini sonlandır
        for identifier in backgroundTasks.keys {
            endBackgroundTask(for: identifier)
        }
        activeDownloads.removeAll()
    }
    
    // Hata türleri için yardımcı metod
    func getErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        var errorMessage = "Download failed."
        
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut:
                errorMessage = "Connection timed out. Please try again."
            case NSURLErrorNetworkConnectionLost:
                errorMessage = "Network connection was lost. Please try again."
            case NSURLErrorNotConnectedToInternet:
                errorMessage = "No internet connection. Please check your connection and try again."
            case NSURLErrorCancelled:
                errorMessage = "Download was cancelled."
            default:
                errorMessage = "Download failed: \(nsError.localizedDescription)"
            }
        }
        
        return errorMessage
    }
    
    // MARK: - SSL Certificate Validation Disabled for Downloads
    
    // CustomServerTrustManager, tüm SSL sertifika doğrulamalarını devre dışı bırakan özel sınıf
    class CustomServerTrustManager: ServerTrustManager, @unchecked Sendable {
        init() {
            // Instagram ve Facebook CDN alanlarını içeren evaluator sözlüğü
            // SSL sertifika doğrulaması tamamen devre dışı
            let evaluators: [String: ServerTrustEvaluating] = [
                "instagram.com": DisabledTrustEvaluator(),
                "cdninstagram.com": DisabledTrustEvaluator(),
                "fbcdn.net": DisabledTrustEvaluator()
            ]
            
            // allHostsMustBeEvaluated: false - Tüm hostlar için evaluator gerekli değil
            super.init(allHostsMustBeEvaluated: false, evaluators: evaluators)
        }
        
        // Bu metodu override ederek, tüm Instagram/Facebook CDN sunucuları için SSL doğrulamasını devre dışı bırak
        override func serverTrustEvaluator(forHost host: String) -> ServerTrustEvaluating? {
            // Instagram ve Facebook CDN domainleri için SSL doğrulamasını devre dışı bırak
            if host.contains("instagram.com") || 
               host.contains("cdninstagram.com") || 
               host.contains("fbcdn.net") {
                print("🔓 SSL sertifika doğrulaması devre dışı bırakıldı: \(host)")
                return DisabledTrustEvaluator()
            }
            
            // Diğer sunucular için de SSL doğrulamasını devre dışı bırak (fallback)
            // Bu, bilinmeyen domainler için de SSL hatalarını önler
            do {
                let evaluator = try super.serverTrustEvaluator(forHost: host)
                return evaluator ?? DisabledTrustEvaluator()
            } catch {
                print("🔓 ServerTrust hatası, SSL doğrulaması devre dışı: \(error.localizedDescription), host: \(host)")
                return DisabledTrustEvaluator() // Fallback olarak tüm sunucular için SSL doğrulamasını devre dışı bırak
            }
        }
    }
} 

