//
//  URAudioEngineDelegate.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/4.
//

import Foundation

protocol URAudioEngineDelegate: AnyObject {
    func didUpdateReceiversBufferMetaData(_ engine: URAudioEngine, metaData: URAudioBufferMetadata)
    
    func captureAudioBufferDataCallBack(_ engine: URAudioEngine, urAudioData: NSMutableData)
}

extension URAudioEngineDelegate {
    func captureAudioBufferDataCallBack(_ engine: URAudioEngine, urAudioData: NSMutableData) {}
}
