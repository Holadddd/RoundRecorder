//
//  RecordedData+CoreDataProperties.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/13.
//
//

import Foundation
import CoreData


extension RecordedData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecordedData> {
        return NSFetchRequest<RecordedData>(entityName: "RecordedData")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var fileName: String?
    @NSManaged public var file: Data?
    @NSManaged public var movingDistance: Double
    @NSManaged public var recordDuration: Int64
    @NSManaged public var timestamp: Date?

}

extension RecordedData : Identifiable {

}
