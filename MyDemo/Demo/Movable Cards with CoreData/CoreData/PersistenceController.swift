//
//  PersistenceController.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/20.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController(inMemory: false)

    // responsible for conmunicating with database and model
    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        // initialize the persistent container
        // name: database name
        container = NSPersistentContainer(name: "FlashCards")
        // if inMemory is true, will only store data in memory
        if inMemory {
            // use a dummy URL for in-memory storage, won't persist data
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // enable automatic merging of changes, make sure UI can reflect changes automatically
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
