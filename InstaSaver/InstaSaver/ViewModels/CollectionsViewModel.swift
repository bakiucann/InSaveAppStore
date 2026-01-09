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
    @Published var showCreateCollectionAlert = false
    @Published var newCollectionName = ""
    @Published var isLoading = false
    
    private var context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private var hasFetched = false // Track if we've already fetched
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
        setupObservers()
        // ❌ REMOVED: fetchCollections() from init
        // Fetch will be called on-demand in .onAppear
    }
    
    func deleteVideoFromCollection(collection: CollectionModel, video: BookmarkedVideo) {
        guard let context = collection.managedObjectContext else { return }
        
        context.perform {
            collection.removeFromVideos(video)
            context.delete(video)
            
            do {
                try context.save()
                DispatchQueue.main.async { [weak self] in
                    self?.refreshCollections()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.showError = true
                    self?.errorMessage = "Failed to save context: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteCollection(_ collection: CollectionModel) {
        guard let context = collection.managedObjectContext else { return }
        
        context.perform {
            context.delete(collection)
            
            do {
                try context.save()
                DispatchQueue.main.async { [weak self] in
                    self?.refreshCollections()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.showError = true
                    self?.errorMessage = "Failed to delete collection: \(error.localizedDescription)"
                }
            }
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
        // Only refresh if we've already fetched (avoid fetching on init)
        guard hasFetched else { return }
        
        DispatchQueue.main.async {
            self.refreshCollections()
        }
    }
    
    func fetchCollections() {
        // Prevent duplicate fetches while loading
        guard !isLoading else { return }
        
        isLoading = true
        hasFetched = true
        
        // Use background context for thread-safe fetching
        let backgroundContext = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<CollectionModel> = CollectionModel.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            do {
                let fetchedCollections = try backgroundContext.fetch(fetchRequest)
                
                // Get object IDs to fetch on main context
                let objectIDs = fetchedCollections.map { $0.objectID }
                
                // Switch to main context to get objects for UI
                DispatchQueue.main.async {
                    let mainContext = CoreDataManager.shared.context
                    let mainContextCollections = objectIDs.compactMap { try? mainContext.existingObject(with: $0) as? CollectionModel }
                    
                    self.collections = mainContextCollections
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError = true
                    self.errorMessage = "Failed to fetch collections: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Error fetching collections: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Force refresh collections (e.g., after adding/deleting/renaming)
    func refreshCollections() {
        isLoading = false // Reset loading state
        hasFetched = false // Reset fetch flag
        fetchCollections()
    }
    
    func addCollection(name: String) {
        context.perform {
            let newCollection = CollectionModel(context: self.context)
            newCollection.id = UUID()
            newCollection.name = name
            newCollection.createdAt = Date()
            
            do {
                try self.context.save()
                DispatchQueue.main.async { [weak self] in
                    self?.refreshCollections()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.showError = true
                    self?.errorMessage = "Failed to create collection: \(error.localizedDescription)"
                }
            }
        }
    }
}
