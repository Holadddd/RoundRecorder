//
//  PathBuilder.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/12/20.
//

import Foundation
import MapKit

protocol PathBuilderDelegate: AnyObject {
    func didUpdateDisplayAnnotations(_ annotations: [HomeMapAnnotation])
}

class PathBuilder {
    
    weak var delegate: PathBuilderDelegate?
    
    private var locationCollection: [CLLocationCoordinate2D]
    
    private static let routeQueue = DispatchQueue(label: "PathBuilder")
    
    private static let pathUnprocessDotColor: UIColor = UIColor("E3C598")
    
    private static let pathDidprocessDotColor: UIColor = .gray
    
    private var pathLocationWith1M: [CLLocationCoordinate2D] = []
    
    private var currentDisplayPathAnnotation: [HomeMapAnnotation] = []
    
    private var currentProcessIndex: Int = 0 {
        didSet {
            // TODO: Generate the annotion by updating process rate
            updateRoutesAnnotatationWith(processIndex: currentProcessIndex)
        }
    }
    
    private var idealDistanceBetweenAnnotation: Int = 1 {
        didSet {
            // TODO: Update display anntation
            generateRoutesAnnotionsWith(processIndex: currentProcessIndex)
        }
    }
    
    init(locationCollection: [CLLocationCoordinate2D]) {
        
        self.locationCollection = locationCollection
        
        pathLocationWith1M = generateLocationWithDistanceOver(meters: 1)
    }
    
    func didUpdateProcessRate(_ rate: Double) {
        let currentProcessIndex = getCurrentProcessIndexBy(rate)
        guard self.currentProcessIndex != currentProcessIndex else { return }
        self.currentProcessIndex = currentProcessIndex
    }
    
    func didUpdateCameraCenterDistance(_ distance: CLLocationDistance) {
        let idealDistance = getIdealDistanceWithCameraCenterDistance(distance)
        guard idealDistanceBetweenAnnotation != idealDistance else { return }
        idealDistanceBetweenAnnotation = idealDistance
    }
    
    private func generatePlaceMarkDistanceOver1Meter() -> [MKPlacemark] {
        
        var marks: [MKPlacemark] = []
        
        guard let origin = locationCollection.first, let last = locationCollection.last else { return marks}
        
        marks.append(MKPlacemark(coordinate: origin))
        
        var lastLocation: CLLocationCoordinate2D = origin
        
        for (index, location) in locationCollection.enumerated() {
            let distance = location.distance(from: lastLocation)
            
            guard distance > 1 && (index != locationCollection.count - 1) else { continue }
            
            marks.append(MKPlacemark(coordinate: location))
            
            lastLocation = location
        }
        
        marks.append(MKPlacemark(coordinate: last))
        
        return marks
    }
    
    private func generateLocationWithDistanceOver(meters: Double) -> [CLLocationCoordinate2D] {
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
    
    func converToMapItems() -> [MKMapItem] {
        
        let placeMarks = generatePlaceMarkDistanceOver1Meter()
        
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
    
    func didStartProcess() {
        guard currentDisplayPathAnnotation.count > 0 else { return }
        
        currentDisplayPathAnnotation[0].color = PathBuilder.pathDidprocessDotColor
        
        delegate?.didUpdateDisplayAnnotations(currentDisplayPathAnnotation)
    }

    private func generateRoutesAnnotionsWith(processIndex: Int) {
        
        var annotations: [HomeMapAnnotation] = []
        
        guard let origin = pathLocationWith1M.first, let last = pathLocationWith1M.last else {return}
        
        let getColor: (Int)->UIColor = { index in
            
            return index > processIndex ? PathBuilder.pathUnprocessDotColor: PathBuilder.pathDidprocessDotColor
        }
        
        annotations.append(HomeMapAnnotation(coordinate: origin, type: .pathWithDot, color: PathBuilder.pathUnprocessDotColor))
        
        for (index, locations)in pathLocationWith1M.enumerated() {
            guard index > 0 && index % idealDistanceBetweenAnnotation == 0 else { continue}
            
            let color = getColor(index)
            
            annotations.append(HomeMapAnnotation(coordinate: locations, type: .pathWithDot, color: color))
        }
        
        annotations.append(HomeMapAnnotation(coordinate: last, type: .pathWithDot, color: PathBuilder.pathUnprocessDotColor))
        
        currentDisplayPathAnnotation = annotations
        delegate?.didUpdateDisplayAnnotations(annotations)
    }
    
    private func updateRoutesAnnotatationWith(processIndex: Int) {
        let annotations: [HomeMapAnnotation] = currentDisplayPathAnnotation.enumerated().map { index, element in
            let color = index > processIndex ? PathBuilder.pathUnprocessDotColor: PathBuilder.pathDidprocessDotColor
            
            element.color = color
            
            return element
        }
        
        delegate?.didUpdateDisplayAnnotations(annotations)
    }
    
    private func getIdealDistanceWithCameraCenterDistance(_ distance: CLLocationDistance) -> Int {
        switch distance {
        case 0..<200:
            let distance = Int(distance / 40) == 0 ? 1 : Int(distance / 40)
            return distance
        case 200..<1000:
            return 5
        case 1000..<3000:
            return 10
        case 3000..<10000:
            return 20
        case 10000..<20000:
            return 50
        default:
            // Not Display
            return 100
        }
    }
    
    private func getCurrentProcessIndexBy(_ rate: Double) -> Int {
        let anotationCount = currentDisplayPathAnnotation.count
        return Int(Double(anotationCount) * rate)
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
