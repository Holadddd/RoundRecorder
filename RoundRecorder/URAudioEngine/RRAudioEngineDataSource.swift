//
//  RRAudioEngineDataSource.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/3.
//

import Foundation

protocol RRAudioEngineDataSource: AnyObject {
    func rrAudioEngine(currentLocationForEngine: RRAudioEngine) -> RRLocationCoordinate3D?
    
    func rrAudioEngine(currentTrueNorthAnchorsMotionForEngine: RRAudioEngine) -> RRMotionAttitude?
}

