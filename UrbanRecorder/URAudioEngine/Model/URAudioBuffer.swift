//
//  URAudioBuffer.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/4.
//

import Foundation
import CoreAudioTypes

struct URAudioBuffer {
    
    var audioData: NSMutableData
    
    var mDataByteSize: UInt32 = 0
    
    var mNumberChannels: UInt32 = 0
    
    var sampleRate: UInt32 = 0
    
    var bitRate: UInt32 = 0
    
    var metadata: URAudioBufferMetadata?
    
    var date: UInt64?
    
    init(_ mData: NSMutableData, _ mDataByteSize: UInt32, _ mNumberChannels: UInt32, _ sampleRate: UInt32, _ bitRate: UInt32, _ metadata: URAudioBufferMetadata? = nil, _ date: UInt64? = nil) {
        self.audioData = mData
        self.mDataByteSize = mDataByteSize
        self.mNumberChannels = mNumberChannels
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.metadata = metadata
        self.date = date
    }
}
