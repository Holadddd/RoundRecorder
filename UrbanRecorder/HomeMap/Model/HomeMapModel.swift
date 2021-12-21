//
//  HomeMapModel.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import Foundation
import SwiftUI
import MapKit

class HomeMapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var type: MapAnnotationItemType = .undefine
    var color: UIColor?
    var tint: UIColor { color ?? .red }
    let id = UUID()
    var imageSystemName: String = "shareplay"
    
    init(coordinate: CLLocationCoordinate2D, type: MapAnnotationItemType = .undefine, color: UIColor) {
        self.coordinate = coordinate
        self.color = color
        self.type = type
    }
    
    enum MapAnnotationItemType {
        case undefine
        case user
        case fixedPoint
        case dynamicPoint
    }
}
//
extension HomeMapAnnotation {
    static var taipei101: HomeMapAnnotation {
        let locationCoordinate = CLLocationCoordinate2D(latitude: 25.03376, longitude: 121.56488)
        let item = HomeMapAnnotation(coordinate: locationCoordinate, color: .blue)
        return item
    }
}

