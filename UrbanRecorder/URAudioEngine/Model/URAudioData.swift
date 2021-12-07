//
//  URAudioData.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/7.
//

import Foundation

class URAudioData {
    
    var chunkID: String
    
    var chunkSize: UInt64
    
    var formatVersion: UInt8
    
    var numChannels: UInt8
    
    var sampleRate: UInt32
    
    var bitRate: UInt8
    
    var numFrames: UInt32
    
    var audioBuffers: [URAudioBuffer] = []
    
    init(chunkID: String, chunkSize: UInt64, formatVersion: UInt8, numChannels: UInt8, sampleRate: UInt32, bitRate: UInt8, numFrames: UInt32, audioBuffers: [URAudioBuffer]) {
        self.chunkID = chunkID
        self.chunkSize = chunkSize
        self.formatVersion = formatVersion
        self.numChannels = numChannels
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.numFrames = numFrames
        self.audioBuffers = audioBuffers
    }
}
