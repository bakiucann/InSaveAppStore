//
//  Persistence.swift
//  InstaSaver
//
//  Created by Baki Uçan on 5.01.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // fatalError yerine error logging ve graceful handling
            let nsError = error as NSError
            print("❌ CRITICAL: Preview context save failed")
            print("❌ Error: \(nsError), \(nsError.userInfo)")
            // Preview context'te save hatası kritik değil, sadece log'la
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "InstaSaver")
        if inMemory {
            // Force unwrapping yerine optional binding kullan
            if let firstDescription = container.persistentStoreDescriptions.first {
                firstDescription.url = URL(fileURLWithPath: "/dev/null")
            } else {
                print("⚠️ Warning: No persistent store descriptions found for in-memory store")
            }
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // fatalError yerine error logging ve graceful handling
                print("❌ CRITICAL: Core Data persistent store yüklenemedi")
                print("❌ Error: \(error), \(error.userInfo)")
                print("❌ Store Description: \(storeDescription)")
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                
                // Production'da crash yerine error handling yapılmalı
                // Bu durumda Core Data kullanılamaz, ama uygulama çalışmaya devam edebilir
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
