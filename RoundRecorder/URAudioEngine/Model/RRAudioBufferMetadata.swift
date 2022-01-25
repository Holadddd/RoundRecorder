//
//  RudioBufferMetadata.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/2.
//

import Foundation

struct RRAudioBufferMetadata: Codable {
    var locationCoordinate: RRLocationCoordinate3D
    
    var motionAttitude: RRMotionAttitude
}

public typealias RRLocationDegrees = Double
public typealias RRAltitudeMeters = Double
struct RRLocationCoordinate3D: Codable {
    
    public var latitude: RRLocationDegrees  //緯度

    public var longitude: RRLocationDegrees //經度
    
    public var altitude: RRLocationDegrees   //海拔
    
    func distanceAndDistance(from destination: RRLocationCoordinate3D) -> RR3DDirectionAndDistance {
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
        
        let altitudeDiffMeters = destination.altitude - self.altitude
        
        return RR3DDirectionAndDistance(direction: direction, distance: distance, altitudeDifference: altitudeDiffMeters)
    }
}

public typealias RRMotionAttitudeDegrees = Double
struct RRMotionAttitude: Codable {
    
    public var rollDegrees: RRMotionAttitudeDegrees = 0
    
    public var pitchDegrees: RRMotionAttitudeDegrees = 0
    
    public var yawDegrees: RRMotionAttitudeDegrees = 0
}

public typealias RRDirectionDegrees = Double
public typealias RRDistanceMeters = Double
struct RR3DDirectionAndDistance {
    public var direction: RRDirectionDegrees
    
    public var distance: RRDistanceMeters
    
    public var altitudeDifference: RRDistanceMeters
}
