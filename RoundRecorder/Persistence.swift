//
//  Persistence.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<5 {
            let recordData = RecordedData(context: viewContext)
            recordData.id = UUID()
            recordData.fileName = "12/10_12:34"
            recordData.movingDistance = 12.34
            recordData.recordDuration = 123
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "RoundRecorderModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
    private func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
                fatalError("Fail in saving context error \(error)")
            }
        }
    }
    // MARK: RecordedData
    func creatRecordedData(complete: @escaping (RecordedData)->Void ){
        let recordedData = RecordedData(context: container.viewContext)
        
        complete(recordedData)
        
        save()
    }
    
    func fetchAllRecordedDatas()->[RecordedData] {
        let fetchRequest: NSFetchRequest<RecordedData> = RecordedData.fetchRequest()
        fetchRequest.predicate = nil       // ex: Fetch data id is 3 => NSPredicate(format: "id == 3")
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    func updateRecordedData(complete: @escaping ()->Void ) {
        complete()
        
        save()
    }
    
    func deleteRecordedData(_ recordedData: RecordedData) {
        container.viewContext.delete(recordedData)
        
        save()
    }
}
