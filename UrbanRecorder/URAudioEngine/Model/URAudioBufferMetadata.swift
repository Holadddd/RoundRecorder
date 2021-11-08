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

}

public typealias URMotionAttitudeDegrees = Double
struct URMotionAttitude: Codable {
    
    public var roll: URMotionAttitudeDegrees
    
    public var pitch: URMotionAttitudeDegrees
    
    public var yaw: URMotionAttitudeDegrees
}
