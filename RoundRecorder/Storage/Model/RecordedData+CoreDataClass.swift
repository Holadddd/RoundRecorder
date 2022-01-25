//
//  RecordedData+CoreDataClass.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/12/13.
//
//

import Foundation
import CoreData
import MapKit

@objc(RecordedData)
public class RecordedData: NSManagedObject {
    var playingDuration: Second = 0
    
    var routes: [MKRoute]?
}
