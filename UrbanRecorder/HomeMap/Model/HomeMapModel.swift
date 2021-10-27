//
//  HomeMapModel.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import Foundation
import SwiftUI
import MapKit

struct HomeMapAnnotationItem: Identifiable {
    var coordinate: CLLocationCoordinate2D
    var type: MapAnnotationItemType = .undefine
    var color: Color?
    var tint: Color { color ?? .red }
    let id = UUID()
    
    enum MapAnnotationItemType {
        case undefine
        case user
        case fixedPoint
        case dynamicPoint
    }
}
//
extension HomeMapAnnotationItem {
    static var taipei101: HomeMapAnnotationItem {
        let locationCoordinate = CLLocationCoordinate2D(latitude: 25.03376, longitude: 121.56488)
        let item = HomeMapAnnotationItem(coordinate: locationCoordinate, color: .blue)
        return item
    }
}
