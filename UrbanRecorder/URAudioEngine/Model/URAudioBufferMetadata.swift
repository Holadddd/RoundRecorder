//
//  AudioBufferMetadata.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/2.
//

import Foundation

struct URAudioBufferMetadata: Codable {
    var locationCoordinate: URLocationCoordinate3D
    
    var motionAttitude: URMotionAttitude
}

public typealias URLocationDegrees = Double
public typealias URAltitudeMeters = Double
struct URLocationCoordinate3D: Codable {
    
    public var latitude: URLocationDegrees  //緯度

    public var longitude: URLocationDegrees //經度
    
    public var altitude: URAltitudeMeters   //海拔
    
    func distanceAndDistance(from destination: URLocationCoordinate3D) -> UR2DDirectionAndDistance {
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
        
        return UR2DDirectionAndDistance(direction: direction, distance: distance)
    }
}

public typealias URMotionAttitudeDegrees = Double
struct URMotionAttitude: Codable {
    
    public var roll: URMotionAttitudeDegrees
    
    public var pitch: URMotionAttitudeDegrees
    
    public var yaw: URMotionAttitudeDegrees
}

public typealias URDirectionDegrees = Double
public typealias URDistanceMeters = Double
struct UR2DDirectionAndDistance {
    public var direction: URDirectionDegrees
    
    public var distance: URDistanceMeters
}
