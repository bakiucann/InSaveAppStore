// CollectionsViewModel.swift

// CollectionsViewModel.swift

import Foundation
import CoreData
import SwiftUI
import Combine

class CollectionsViewModel: ObservableObject {
    @Published var collections: [CollectionModel] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
        setupObservers()
        fetchCollections()
    }
    
    func deleteVideoFromCollection(collection: CollectionModel, video: BookmarkedVideo) {
        if let context = collection.managedObjectContext {
            collection.removeFromVideos(video)
            context.delete(video)
            do {
                try context.save()
                fetchCollections()
            } catch {
                showError = true
                errorMessage = "Failed to save context: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteCollection(_ collection: CollectionModel) {
        guard let context = collection.managedObjectContext else { return }
        context.delete(collection)
        
        do {
            try context.save()
            fetchCollections() // Listeyi yenile
        } catch {
            showError = true
            errorMessage = "Failed to delete collection: \(error.localizedDescription)"
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)
            .sink { [weak self] notification in
                self?.handleContextObjectsDidChange(notification)
            }
            .store(in: &cancellables)
    }
    
    func updateCollectionAfterVideoDeletion(_ collection: CollectionModel) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
        }
    }
    
    private func handleContextObjectsDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.fetchCollections()
        }
    }
    
    func fetchCollections() {
        DispatchQueue.global(qos: .background).async {
            let fetchRequest: NSFetchRequest<CollectionModel> = CollectionModel.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            do {
                let fetchedCollections = try self.context.fetch(fetchRequest)
                DispatchQueue.main.async {
                    self.collections = fetchedCollections
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError = true
                    self.errorMessage = "Failed to fetch collections: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func addCollection(name: String) {
        let newCollection = CollectionModel(context: context)
        newCollection.id = UUID()
        newCollection.name = name
        newCollection.createdAt = Date()
        
        do {
            try context.save()
            fetchCollections()
        } catch {
            showError = true
            errorMessage = "Failed to create collection: \(error.localizedDescription)"
        }
    }
}
