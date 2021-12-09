//
//  URRecordingDataHelper.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/6.
//

import Foundation
import AVFoundation
import SwiftUI

protocol URRecordingDataHelperDelegate: AnyObject {
    func didUpdateAudioRecordingDuration(_ seconds: UInt)
    
    func didUpdateAudioRecordingMovingDistance(_ meters: Double)
}

class URRecordingDataHelper: NSObject {

    static let URAudioDataFormatVersion: UInt8 = 1
    
    private var recordAudioBufferCollection: [URAudioBuffer]?
    
    private var chunkID: String = ""
    
    private var numChannels: UInt8 = 1
    
    private var sampleRate: UInt32?
    
    private var bitRate: UInt8?
    
    private var numberOfFrames: Int = 0
    
    private var audioSizeInRecordData: UInt = 0 {
        didSet{
            guard let sampleRate = sampleRate,
                  let bitRate = bitRate   else {
                      return
                  }
            let bytesPerSecond = UInt(numChannels) * UInt(sampleRate) * UInt(bitRate)
            
            let result = audioSizeInRecordData / (bytesPerSecond / 8)
            
            if result != audioDuration {
                audioDuration = result
                delagete?.didUpdateAudioRecordingDuration(audioDuration)
                // TODO:- Update distance
                if let lastLocationCodinate = lastLocationCodinate, let currentLocationCodinate = currentLocationCodinate {
                    let movinDistanceInLastSecond = lastLocationCodinate.distanceAndDistance(from: currentLocationCodinate)
                    
                    movingDistanceMeters += movinDistanceInLastSecond.distance
                    
                    self.lastLocationCodinate = currentLocationCodinate
                    
                    delagete?.didUpdateAudioRecordingMovingDistance(movingDistanceMeters)
                }
            }
        }
    }
    
    private var startTime: UInt = 0 // MillisecondsSince1970
    
    private var audioDuration: UInt = 0
    
    private var movingDistanceMeters: Double = 0
    
    private var lastLocationCodinate: URLocationCoordinate3D?
    
    private var currentLocationCodinate: URLocationCoordinate3D?
    
    weak var delagete: URRecordingDataHelperDelegate?
    
    override init() {
        super.init()
        
    }
    /*
     URAudioData Formatt(1)
     --------------------------------------------------------------------
     Field Offset | Field Name | Field type | Field Size(byte) | Description
     --------------------------------------------------------------------
     0              chunkID     String          16
     16             chunkSize   UInt64          8                   35
     24             formatVersionUint8          1
     25             numChannels UInt8           1                   Default is 1(Mono
     26             sampleRate  UInt32          4                   ex: 441000, 48000
     30             bitRate     UInt8           1                   ex: 16,24,32
     31             numFrames   UInt32          4
     35             URAudioBuffers
     --------------------------------------------------------------------
     */
    private func resetRecordingStatus() {
        recordAudioBufferCollection = nil // Deallocate the old file
        
        chunkID = ""
        numberOfFrames = 0
        audioSizeInRecordData = 0
        movingDistanceMeters = 0
        sampleRate = 0
        bitRate = 0
    }
    // MARK: Write
    public func generateEmptyURRecordingData(chunkID: String = UUID().uuidString, sampleRate: UInt32, bitRate: UInt8) -> Bool {
        resetRecordingStatus()
        
        self.chunkID = chunkID
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        
        return true
    }
    
    public func generateEmptyURRecordingData(chunkID: String = UUID().uuidString, audioFormat: AVAudioFormat) -> Bool {
        resetRecordingStatus()
        
        sampleRate = UInt32(audioFormat.sampleRate)
        bitRate = UInt8(audioFormat.bitRate)
        
        return true
    }
    
    public func schechuleURAudioBuffer(_ buffer:  Data) {
        let urAudioBuffer = URAudioEngine.parseURAudioBufferData(buffer)
        
        numberOfFrames += 1
        
        audioSizeInRecordData += UInt(urAudioBuffer.mDataByteSize)
        
        if recordAudioBufferCollection == nil {
            recordAudioBufferCollection = [urAudioBuffer]
        } else {
            recordAudioBufferCollection?.append(urAudioBuffer)
        }
        
    }
    // MARK: Read
    public func getCurrentRecordingURAudioData() -> URAudioData? {
        guard let sampleRate = sampleRate,
              let bitRate = bitRate,
              let recordAudioBufferCollection = recordAudioBufferCollection else { return nil }
        
        return URAudioData(chunkID: chunkID,
                           chunkSize: UInt64(35),
                           formatVersion: UInt8(1),
                           numChannels: numChannels,
                           sampleRate: sampleRate,
                           bitRate: bitRate,
                           numFrames: UInt32(numberOfFrames),
                           audioBuffers: recordAudioBufferCollection)
    }
}

extension URRecordingDataHelper {
    static func parseURAudioData(_ data: Data) -> URAudioData {
        /*
         URAudioData Formatt(1)
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              chunkID     String          16
         16             chunkSize   UInt64          8                   35 + URAudioBuffers
         24             formatVersionUint8          1
         25             numChannels UInt8           1                   Default is 1(Mono
         26             sampleRate  UInt32          4                   ex: 441000, 48000
         30             bitRate     UInt8           1                   ex: 16,24,32
         31             numFrames   UInt32          4
         35             URAudioBuffers
         --------------------------------------------------------------------
         
         URAudioBuffer Formatt
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              date        UInt64          8               MillisecondsSince1970
         8              bufferLengthUInt32          4
         12             nChannel    UInt32          4
         16             sampleRate  UInt32          4
         20             bitRate     UInt32          4
         24             latitude    Double          8
         32             longitude   Double          8
         40             altitude    Double          8
         48             roll        Double          8
         56             pitch       Double          8
         64             yaw         Double          8
         72             data
         --------------------------------------------------------------------
         */
        
        let chunckID: String = NSMutableData(data: data.advanced(by: 0)).bytes.load(as: String.self)
        let chunkSize: UInt64 = NSMutableData(data: data.advanced(by: 16)).bytes.load(as: UInt64.self)
        let formatVersion: UInt8 = NSMutableData(data: data.advanced(by: 24)).bytes.load(as: UInt8.self)
        let numChannels: UInt8 = NSMutableData(data: data.advanced(by: 25)).bytes.load(as: UInt8.self)
        let sampleRate: UInt32 = NSMutableData(data: data.advanced(by: 26)).bytes.load(as: UInt32.self)
        let bitRate: UInt8 = NSMutableData(data: data.advanced(by: 30)).bytes.load(as: UInt8.self)
        let numFrames: UInt32 = NSMutableData(data: data.advanced(by: 31)).bytes.load(as: UInt32.self)
        
        //AudioBufferCollection
        var audioBufferCollection: [URAudioBuffer] = []
        var readingOffset = 35
        let audioBufferMetaDataSize = 72
        
        while readingOffset < (data.count - audioBufferMetaDataSize) {
            
            let currentBufferSize: UInt32 = NSMutableData(data: data.advanced(by: readingOffset + 8)).bytes.load(as: UInt32.self)
            
            let audioBuffer = URAudioEngine.parseURAudioBufferData( data.advanced(by: readingOffset)
            )
            
            readingOffset += (Int(currentBufferSize) + audioBufferMetaDataSize)
            
            audioBufferCollection.append(audioBuffer)
        }
        
        
        
        
        return URAudioData(chunkID: chunckID,
                           chunkSize: chunkSize,
                           formatVersion: formatVersion,
                           numChannels: numChannels,
                           sampleRate: sampleRate,
                           bitRate: bitRate,
                           numFrames: numFrames,
                           audioBuffers: audioBufferCollection)
    }
    
    static func encodeURAudioData( urAudioData: URAudioData) -> Data {
        // 1. urAudioBufferCollectionSize
        let urAudioBufferCollection = urAudioData.audioBuffers
        var urAudioBufferCollectionSize = 0
        var urAudioBufferDataCollection: [Data] = []
        for buffer in urAudioBufferCollection {
            let date = buffer.date ?? Date().millisecondsSince1970
            let latitude = buffer.metadata?.locationCoordinate.latitude ?? 0
            let longitude = buffer.metadata?.locationCoordinate.longitude ?? 0
            let altitude = buffer.metadata?.locationCoordinate.altitude ?? 0
            
            let roll = buffer.metadata?.motionAttitude.rollDegrees ?? 0
            let pitch = buffer.metadata?.motionAttitude.pitchDegrees ?? 0
            let yaw = buffer.metadata?.motionAttitude.yawDegrees ?? 0
            
            let audioData = Data.init(bytes: buffer.audioData.bytes, count: Int(buffer.mDataByteSize))
            
            let bufferData = URAudioEngine.encodeURAudioBufferData(date,
                                                                   buffer.mDataByteSize,
                                                                   buffer.mNumberChannels,
                                                                   buffer.sampleRate,
                                                                   buffer.bitRate,
                                                                   latitude,
                                                                   longitude,
                                                                   altitude,
                                                                   roll,
                                                                   pitch,
                                                                   yaw,
                                                                   audioData)
            
            urAudioBufferDataCollection.append(bufferData)
            urAudioBufferCollectionSize += bufferData.count
        }
        
        let newDataSize: Int = urAudioBufferCollectionSize + Int(urAudioData.chunkSize)
        
        var newData = Data(count: newDataSize)
        
        // MARK: Encode URAudioData
        newData.replaceSubrange(0..<16, with: withUnsafeBytes(of: urAudioData.chunkID) { Data($0) })    //  Offset: 0, chunkID

        newData.replaceSubrange(16..<24, with: withUnsafeBytes(of: urAudioData.chunkSize) { Data($0) })    //  Offset: 16, chunkSize
        
        newData.replaceSubrange(24..<25, with: withUnsafeBytes(of: urAudioData.formatVersion) { Data($0) })    //  Offset: 24, formatVersion

        newData.replaceSubrange(25..<26, with: withUnsafeBytes(of: urAudioData.numChannels) { Data($0) })    //  Offset: 25, numChannels

        newData.replaceSubrange(26..<30, with: withUnsafeBytes(of: urAudioData.sampleRate) { Data($0) })    //  Offset: 26, sampleRate

        newData.replaceSubrange(30..<31, with: withUnsafeBytes(of: urAudioData.bitRate) { Data($0) })    //  Offset: 30, bitRate
        
        newData.replaceSubrange(31..<35, with: withUnsafeBytes(of: urAudioData.numFrames) { Data($0) })    //  Offset: 30, numFrames
        // Encode AudioBuffer
        for data in urAudioBufferDataCollection {   // Start at offset: 35, urAudioBufferData
            newData.append(data)
        }
        
        return newData
    }
    
    static func getURAudioBufferAudioSize(_ data: Data) -> UInt32 {
        let bufferLength: UInt32 = NSMutableData(data: data.advanced(by: 8)).bytes.load(as: UInt32.self)    // Offset: 8, bufferLength
        return bufferLength
    }
    
    static func getURAudioBufferLocationCoordinate(_ data: Data) -> URLocationCoordinate3D {
        
        let latitude: Double = NSMutableData(data: data.advanced(by: 24)).bytes.load(as: Double.self)
        let longitude: Double = NSMutableData(data: data.advanced(by: 32)).bytes.load(as: Double.self)
        let altitude: Double = NSMutableData(data: data.advanced(by: 40)).bytes.load(as: Double.self)
        
        return URLocationCoordinate3D(latitude: latitude,
                                      longitude: longitude,
                                      altitude: altitude)
    }
}
