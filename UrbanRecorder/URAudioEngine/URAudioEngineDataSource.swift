//
//  URAudioEngineDataSource.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/3.
//

import Foundation

protocol URAudioEngineDataSource: AnyObject {
    func urAudioEngine(currentLocationForEngine: URAudioEngine) -> URLocationCoordinate3D?
    
    func urAudioEngine(currentTrueNorthAnchorsMotionForEngine: URAudioEngine) -> URMotionAttitude?
}

