//
//  PathBuilder.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/12/20.
//

import Foundation
import MapKit

struct PathBuilder {
    
    var locationCollection: [CLLocationCoordinate2D]
    
    private static let routeQueue = DispatchQueue(label: "PathBuilder")
    
    func generatePlaceMarkDistanceOver(meters: Double) -> [MKPlacemark] {
        
        var marks: [MKPlacemark] = []
        
        guard let origin = locationCollection.first, let last = locationCollection.last else { return marks}
        
        marks.append(MKPlacemark(coordinate: origin))
        
        var lastLocation: CLLocationCoordinate2D = origin
        
        for (index, location) in locationCollection.enumerated() {
            let distance = location.distance(from: lastLocation)
            
            guard distance > meters && (index != locationCollection.count - 1) else { continue }
            
            marks.append(MKPlacemark(coordinate: location))
            
            lastLocation = location
        }
        
        marks.append(MKPlacemark(coordinate: last))
        
        return marks
    }
    
    func generateLocationWithDistanceOver(meters: Double) -> [CLLocationCoordinate2D] {
        var locations: [CLLocationCoordinate2D] = []
        
        guard let origin = locationCollection.first, let last = locationCollection.last else { return locations}
        
        locations.append(origin)
        
        var lastLocation: CLLocationCoordinate2D = origin
        
        for (index, location) in locationCollection.enumerated() {
            let distance = location.distance(from: lastLocation)
            
            guard distance > meters && (index != locationCollection.count - 1) else { continue }
            
            locations.append(location)
            
            lastLocation = location
        }
        
        locations.append(last)
        
        return locations
    }
    
    static func converToMapItems(placeMarks: [MKPlacemark]) -> [MKMapItem] {
        return placeMarks.map {
            MKMapItem(placemark: $0)
        }
    }
    
    static func generateRouteWith(mapItems: [MKMapItem], complete:@escaping ((Result<[MKRoute], RouteBuilderError>)->Void) ) {
        
        routeQueue.async {
            let semaphore = DispatchSemaphore(value: 1)
            var routes: [MKRoute] = []
            
            for (index, item) in mapItems.enumerated() {
                guard index > 0 else { continue }
                let start = mapItems[index - 1]
                
                let request = MKDirections.Request()
                request.source = start
                request.destination = item
                
                let directions = MKDirections(request: request)
                semaphore.wait()
                directions.calculate { response, error in
                    if let mapRoute = response?.routes.first {
                        routes.append(mapRoute)
                    }
                    semaphore.signal()
                }
            }
            
            complete(.success(routes))
        }
    }
    
    static func generateRoutesAnnotionsWith(locations: [CLLocationCoordinate2D], centerDistance: CLLocationDistance, complete:@escaping ((Result<[HomeMapAnnotation], RouteBuilderError>)->Void) ) {
        
        routeQueue.async {
            // The Annotations is set as 1 meters in each location
            let idealDistance: Int = {
                switch centerDistance {
                case 0..<200:
                    let distance = Int(centerDistance / 40) == 0 ? 1 : Int(centerDistance / 40)
                    return distance
                case 200..<1000:
                    return 5
                case 1000..<5000:
                    return 20
                case 5000..<10000:
                    return 50
                case 10000..<20000:
                    return 100
                default:
                    // Not Display
                    return 200
                }
            }()
            print("The ideal distance is: \(idealDistance)")
            var annotations: [HomeMapAnnotation] = []
            
            guard let origin = locations.first, let last = locations.last else { complete(.success(annotations)); return}
            
            annotations.append(HomeMapAnnotation(coordinate: origin, type: .pathWithDot))
            
            for (index, locations)in locations.enumerated() {
                guard index > 0 && index % idealDistance == 0 else { continue}
                annotations.append(HomeMapAnnotation(coordinate: locations, type: .pathWithDot))
            }
            annotations.append(HomeMapAnnotation(coordinate: last, type: .pathWithDot))
            
            complete(.success(annotations))
        }
    }
}

enum RouteBuilderError: Error {
    case failInCalculateRoute
}

extension CLLocationCoordinate2D {
    func distance(from destination: CLLocationCoordinate2D) -> Double {
        func hypotenuse(_ a: Double, _ b: Double) -> Double {
            return (a * a + b * b).squareRoot()
        }
        /*
         1° of latitude = always 111.32 km
         1° of longitude = 40075 km * cos( latitude ) / 360
         */
        let latitudeDifferenceDegrees = (destination.latitude - self.latitude) // 緯度
        let lontitudeDifferenceDegrees = (destination.longitude - self.longitude)  // 經度
        let latitudeMeters = latitudeDifferenceDegrees * 111320
        let longitudeMeters = lontitudeDifferenceDegrees * 40075000 * cos(latitudeDifferenceDegrees * Double.pi / 180) / 360
        
        var direction: Double {
            if longitudeMeters == 0 {
                return latitudeMeters >= 0 ? 0 : 180
            } else if latitudeMeters == 0 {
                return longitudeMeters >= 0 ? 90 : -90
            }
            let tanValue = latitudeMeters / longitudeMeters
            let tanDegrees = atan(tanValue) * 180 / Double.pi
            
            var directionDegrees: Double = 0
            
            if longitudeMeters > 0 {
                // 1,2
                directionDegrees = 90 - tanDegrees
            } else {
                // 3,4
                directionDegrees = -90 - tanDegrees
            }
            
            return directionDegrees.isNaN ? 0 : directionDegrees
        }
        
        let distance = hypotenuse(latitudeMeters, longitudeMeters)
        
        return distance
    }
}
