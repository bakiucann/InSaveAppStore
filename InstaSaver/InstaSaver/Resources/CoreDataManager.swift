// CoreDataManager.swift

import Foundation
import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "InstaSaver")
        
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Persistent stores yüklenemedi: \(error.localizedDescription)")
            } else {
                print("Persistent store yüklendi: \(description)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Mevcut metotlarınızı koruyun ve gerektiğinde yeni metotlar ekleyin
    
    func isBookmarked(videoID: String) -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BookmarkedVideo")
        fetchRequest.predicate = NSPredicate(format: "id == %@", videoID)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error fetching data from Core Data: \(error.localizedDescription)")
            return false
        }
    }
    
    func saveBookmark(videoID: String, cover: String) {
        DispatchQueue.main.async {
            let newBookmark = BookmarkedVideo(context: self.context)
            newBookmark.id = videoID
            newBookmark.cover = cover
            
            do {
                try self.context.save()
                print("Bookmark saved successfully.")
            } catch {
                print("Error saving to Core Data: \(error.localizedDescription)")
            }
        }
    }
    
    func saveVideoInfo(videoID: String, uniqueId: String, originCover: String, downloadLink: String, date: Date, type: String = "video") {
        let context = persistentContainer.viewContext
        
        let savedVideo = SavedVideo(context: context)
        savedVideo.id = videoID 
        savedVideo.uniqueId = uniqueId
        savedVideo.originCover = originCover
        savedVideo.originalUrl = downloadLink
        savedVideo.date = date
        savedVideo.type = type
        
        // URL'den kapak görselini asenkron bir şekilde indir
        if let coverUrl = URL(string: originCover) {
            URLSession.shared.dataTask(with: coverUrl) { data, response, error in
                if let data = data {
                    DispatchQueue.main.async {
                        savedVideo.coverImageData = data
                        do {
                            try context.save()
                            print("Video/Story başarıyla kaydedildi.")
                        } catch {
                            print("Video/Story bilgileri kaydedilemedi: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Kapak görseli indirilemedi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                }
            }.resume()
        }
    }
    
    // Story kaydetmek için yeni bir yardımcı fonksiyon
    func saveStoryInfo(story: InstagramStoryModel) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let formattedDate = dateFormatter.string(from: Date())
        
        saveVideoInfo(
            videoID: story.id,
            uniqueId: "Story - \(formattedDate)",
            originCover: story.thumbnailUrl,
            downloadLink: story.url,
            date: Date(),
            type: "story"
        )
    }
    
    func fetchSavedVideos() -> [SavedVideo] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SavedVideo> = SavedVideo.fetchRequest()
        
        do {
            let savedVideos = try context.fetch(fetchRequest)
            return savedVideos
        } catch {
            print("Failed to fetch saved videos: \(error.localizedDescription)")
            return []
        }
    }
    
    func updateCoverImageData(for videoID: String, with imageData: Data?) {
        DispatchQueue.main.async {
            let fetchRequest: NSFetchRequest<SavedVideo> = SavedVideo.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", videoID)
            
            do {
                let videos = try self.context.fetch(fetchRequest)
                if let video = videos.first {
                    video.coverImageData = imageData
                    try self.context.save()
                }
            } catch {
                print("Cover Image Data kaydedilemedi: \(error)")
            }
        }
    }
    
    func deleteSavedVideo(by id: String) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SavedVideo> = SavedVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let savedVideos = try context.fetch(fetchRequest)
            for video in savedVideos {
                context.delete(video)
            }
            try context.save()
            print("Video deleted successfully from Core Data.")
        } catch {
            print("Failed to delete video: \(error.localizedDescription)")
        }
    }
    
    func removeBookmark(videoID: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BookmarkedVideo")
        fetchRequest.predicate = NSPredicate(format: "id == %@", videoID)
        
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                if let objectToDelete = object as? NSManagedObject {
                    context.delete(objectToDelete)
                }
            }
            
            try context.save()
        } catch {
            print("Error removing from Core Data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Daily Download Limit Management
    
    func getTodayDownloadCount() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<DailyDownloadLimit> = DailyDownloadLimit.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let result = try context.fetch(fetchRequest)
            return Int(result.first?.downloadCount ?? 0)
        } catch {
            print("Error fetching daily download count: \(error)")
            return 0
        }
    }
    
    func incrementDailyDownloadCount() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<DailyDownloadLimit> = DailyDownloadLimit.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startOfDay as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let downloadLimit: DailyDownloadLimit
            
            if let existingLimit = results.first {
                downloadLimit = existingLimit
                downloadLimit.downloadCount += 1
            } else {
                downloadLimit = DailyDownloadLimit(context: context)
                downloadLimit.date = Date()
                downloadLimit.downloadCount = 1
            }
            
            try context.save()
        } catch {
            print("Error incrementing daily download count: \(error)")
        }
    }
    
    func canDownloadMore() -> Bool {
        let currentCount = getTodayDownloadCount()
        return currentCount < 10
    }
    
    func getRemainingDownloads() -> Int {
        let currentCount = getTodayDownloadCount()
        return max(0, 10 - currentCount)
    }
    
    func clearAllSavedVideos() {
        let fetchRequest: NSFetchRequest<SavedVideo> = SavedVideo.fetchRequest()
        
        do {
            let savedVideos = try context.fetch(fetchRequest)
            for video in savedVideos {
                context.delete(video)
            }
            try context.save()
            print("All saved videos cleared successfully.")
        } catch {
            print("Failed to clear saved videos: \(error.localizedDescription)")
        }
    }
}
