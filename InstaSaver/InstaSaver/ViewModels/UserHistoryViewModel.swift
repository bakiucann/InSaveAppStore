//// UserHistoryViewModel.swift
//
//import Foundation
//import Combine
//
//struct UserSearchItem: Identifiable, Codable {
//    var id: String { username }
//    let username: String
//    var avatarUrl: String?
//}
//
//class UserHistoryViewModel: ObservableObject {
//    @Published var userSearchHistory: [UserSearchItem] = []
//    
//    private let userDefaultsKey = "userSearchHistory"
//    private let maxHistoryLimit = 200 // Maksimum 200 kayıt
//    
//    init() {
//        loadHistory()
//    }
//    
//    // Kullanıcı aramalarını kaydet
//    func addSearch(username: String, avatarUrl: String?) {
//        // Zaten aynı kullanıcı varsa kaydetmeyi atla
//        guard !userSearchHistory.contains(where: { $0.username == username }) else {
//            print("User \(username) is already in the history, skipping.")
//            return
//        }
//        
//        // Eğer 200 kayıta ulaşıldıysa, en eski kaydı sil
//        if userSearchHistory.count >= maxHistoryLimit {
//            userSearchHistory.removeFirst() // İlk kaydı (en eski) sil
//        }
//        
//        // Yeni kullanıcıyı ekle
//        let newSearch = UserSearchItem(username: username, avatarUrl: avatarUrl)
//        userSearchHistory.append(newSearch)
//        saveHistory()
//        
//        print("Added user: \(username) with avatar URL: \(String(describing: avatarUrl))")
//    }
//    
//    // Arama geçmişini kaydet
//    private func saveHistory() {
//        if let encodedData = try? JSONEncoder().encode(userSearchHistory) {
//            UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
//            print("History saved successfully: \(userSearchHistory)") // Kaydedilen veriyi kontrol et
//        } else {
//            print("Failed to encode history.")
//        }
//    }
//    
//    // Arama geçmişini yükle
//    private func loadHistory() {
//        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
//           let decodedData = try? JSONDecoder().decode([UserSearchItem].self, from: data) {
//            userSearchHistory = decodedData
//            print("History loaded successfully with \(userSearchHistory.count) items.")
//        } else {
//            print("Failed to load history or history is empty.")
//        }
//    }
//    
//    // Geçmişten arama silme
//    func deleteSearch(at index: Int) {
//        userSearchHistory.remove(at: index)
//        saveHistory()
//    }
//    
//    // Tüm geçmişi temizle
//    func clearAllHistory() {
//        userSearchHistory.removeAll() // Tüm geçmişi sil
//        saveHistory() // Boş geçmişi kaydet
//    }
//}
