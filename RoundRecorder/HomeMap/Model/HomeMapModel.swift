//
//  HomeMapModel.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import Foundation
import SwiftUI
import MapKit

class HomeMapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var userHeadingDegrees: Double?
    var type: MapAnnotationItemType = .undefine
    var color: UIColor?
    var tint: UIColor { color ?? .red }
    let id = UUID()
    var imageSystemName: String {
        switch type {
        case .undefine, .receiver:
            return "shareplay"
        case .user:
            return "location.north.fill"
        case .pathWithDot:
            return "circle.circle.fill"
        default:
            return ""
        }
    }
    
    init(coordinate: CLLocationCoordinate2D, userHeadingDegrees: Double? = nil, type: MapAnnotationItemType = .undefine, color: UIColor = .black) {
        self.coordinate = coordinate
        self.userHeadingDegrees = userHeadingDegrees
        self.color = color
        self.type = type
    }
    
    enum MapAnnotationItemType {
        case undefine
        case user
        case receiver
        case fixedPoint
        case pathWithDot
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

