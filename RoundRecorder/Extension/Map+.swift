//
//  Map+.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2022/1/17.
//

import Foundation
import CoreLocation

extension CLLocation {
    var toCLLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
    }
}

