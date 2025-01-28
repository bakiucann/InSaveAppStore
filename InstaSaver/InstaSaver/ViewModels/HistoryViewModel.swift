// HistoryViewModel.swift

import Foundation
import Combine
import UIKit
import CoreData

// Models
struct HistoryItem: Identifiable {
    let id: String
    let title: String
    let originCover: String?
    let originalUrl: String?
    let date: Date
    let coverImageData: Data?
    let type: String
}

class HistoryViewModel: ObservableObject {
    @Published var history: [HistoryItem] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchHistory()
        
        // Bildirimleri dinle
        NotificationCenter.default.addObserver(self, selector: #selector(newVideoSaved(_:)), name: NSNotification.Name("NewVideoSaved"), object: nil)
    }
    
    // Bildirimi dinleyen metod
    @objc private func newVideoSaved(_ notification: Notification) {
        fetchHistory() // Yeni kaydedilen videoyu yükle ve güncelle
    }
    
    func saveCoverImage(from url: URL, for videoID: String) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                print("Görsel yüklenemedi")
                return
            }
            
            DispatchQueue.main.async {
                // Core Data'ya kaydetme işlemi
                let imageData = image.pngData() // PNG formatında Data'ya çevirme
                CoreDataManager.shared.updateCoverImageData(for: videoID, with: imageData)
            }
        }.resume()
    }
    
    func fetchHistory() {
        let savedVideos = CoreDataManager.shared.fetchSavedVideos()
        
        var uniqueVideos: [String: HistoryItem] = [:]
        
        // Önce en son kaydedilenleri al
        for video in savedVideos {
            if let videoID = video.id {
                let historyItem = convertToHistoryItem(video)
                uniqueVideos[videoID] = historyItem
            }
        }
        
        // Dictionary değerlerini diziye çevir ve tarihe göre sırala
        self.history = Array(uniqueVideos.values)
            .sorted(by: { $0.date > $1.date }) // En son kaydedilenler en üstte
    }
    
    func addHistoryItem(_ item: HistoryItem) {
        // Check if item already exists to avoid duplicates
        if !history.contains(where: { $0.id == item.id }) {
            history.insert(item, at: 0) // Yeni öğeyi listenin başına ekle
            
            // If history contains 200 or more items, remove the oldest one
            if history.count > 200 {
                if let oldestItem = history.min(by: { $0.date < $1.date }) {
                    deleteHistoryItem(oldestItem)
                }
            }
        }
    }
    
    func deleteHistoryItem(_ item: HistoryItem) {
        CoreDataManager.shared.deleteSavedVideo(by: item.id)
        history.removeAll { $0.id == item.id }
        // Silme işleminden sonra listeyi yeniden sırala
        history = history.sorted(by: { $0.date > $1.date })
    }
    
    private func convertToHistoryItem(_ savedVideo: SavedVideo) -> HistoryItem {
        return HistoryItem(
            id: savedVideo.id ?? "",
            title: savedVideo.uniqueId ?? "",
            originCover: savedVideo.originCover,
            originalUrl: savedVideo.originalUrl,
            date: savedVideo.date ?? Date(),
            coverImageData: savedVideo.coverImageData,
            type: savedVideo.type ?? "video"
        )
    }
}
