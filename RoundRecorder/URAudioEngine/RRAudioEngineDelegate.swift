//
//  RRAudioEngineDelegate.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/4.
//

import Foundation

protocol RRAudioEngineDelegate: AnyObject {
    func didUpdateReceiversBufferMetaData(_ engine: RRAudioEngine, metaData: RRAudioBufferMetadata)
    
    func captureAudioBufferDataCallBack(_ engine: RRAudioEngine, rrAudioData: Data)
}

extension RRAudioEngineDelegate {
    func captureAudioBufferDataCallBack(_ engine: RRAudioEngine, rrAudioData: Data) {}
}
