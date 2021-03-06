//
//  RRRecordingDataHelper.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/12/6.
//

import Foundation
import AVFoundation
import SwiftUI

protocol RRRecordingDataHelperDelegate: AnyObject {
    func didUpdateAudioRecordingDuration(_ seconds: UInt)
    
    func didUpdateAudioRecordingMovingDistance(_ meters: Double)
}

class RRRecordingDataHelper: NSObject {

    static let RRAudioDataFormatVersion: UInt8 = 1
    
    private var recordAudioBufferCollection: [RRAudioBuffer] = []
    
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
                if let currentLocationCodinate = currentLocationCodinate {
                    if let lastLocationCodinate = lastLocationCodinate {
                        let movinDistanceInLastSecond = lastLocationCodinate.distanceAndDistance(from: currentLocationCodinate)
                        
                        guard movinDistanceInLastSecond.distance > 1 else { return }
                        movingDistanceMeters += movinDistanceInLastSecond.distance
                        
                        self.lastLocationCodinate = currentLocationCodinate
                        
                        delagete?.didUpdateAudioRecordingMovingDistance(movingDistanceMeters)
                    } else {
                        lastLocationCodinate = currentLocationCodinate
                    }
                }
            }
        }
    }
    
    private var startTime: UInt = 0 // MillisecondsSince1970
    
    private var audioDuration: UInt = 0
    
    private var movingDistanceMeters: Double = 0
    
    private var lastLocationCodinate: RRLocationCoordinate3D?
    
    private var currentLocationCodinate: RRLocationCoordinate3D?
    
    weak var delagete: RRRecordingDataHelperDelegate?
    
    override init() {
        super.init()
        
    }
    /*
     RRAudioData Formatt(1)
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
     35             RRAudioBuffers
     --------------------------------------------------------------------
     */
    private func resetRecordingStatus() {
        recordAudioBufferCollection.removeAll() // Deallocate the old file
        
        chunkID = ""
        numberOfFrames = 0
        audioSizeInRecordData = 0
        movingDistanceMeters = 0
        sampleRate = 0
        bitRate = 0
        
        currentLocationCodinate = nil
        lastLocationCodinate = nil
    }
    // MARK: Write
    public func generateEmptyRRRecordingData(chunkID: String = UUID().uuidString, sampleRate: UInt32, bitRate: UInt8) -> Bool {
        resetRecordingStatus()
        
        self.chunkID = chunkID
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        
        return true
    }
    
    public func generateEmptyRRRecordingData(chunkID: String = UUID().uuidString, audioFormat: AVAudioFormat) -> Bool {
        resetRecordingStatus()
        
        self.chunkID = chunkID
        sampleRate = UInt32(audioFormat.sampleRate)
        bitRate = UInt8(audioFormat.bitRate)
        
        return true
    }
    
    public func schechuleRRAudioBuffer(_ buffer:  Data) {
        let rrAudioBuffer = RRAudioEngine.parseRRAudioBufferData(buffer)
        
        numberOfFrames += 1
        
        audioSizeInRecordData += UInt(rrAudioBuffer.mDataByteSize)
        
        recordAudioBufferCollection.append(rrAudioBuffer)
        
        currentLocationCodinate = rrAudioBuffer.metadata?.locationCoordinate
    }
    // MARK: Read
    public func getCurrentRecordingRRAudioData() -> RRAudioData? {
        guard let sampleRate = sampleRate,
              let bitRate = bitRate
        else { return nil }
        
        return RRAudioData(chunkID: chunkID,
                           chunkSize: UInt64(35),
                           formatVersion: UInt8(1),
                           numChannels: numChannels,
                           sampleRate: sampleRate,
                           bitRate: bitRate,
                           numFrames: UInt32(numberOfFrames),
                           audioBuffers: recordAudioBufferCollection)
    }
}

extension RRRecordingDataHelper {
    static func parseRRAudioData(_ data: Data) -> RRAudioData {
        /*
         RRAudioData Formatt(1)
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
         35             RRAudioBuffers
         --------------------------------------------------------------------
         
         RRAudioBuffer Formatt
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
        // Prevent data is not been aligned
        let dataArray = [UInt8](data)
        
        let chunckID: String = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: String.self)}
        let chunkSize: UInt64 = dataArray.readLittleEndian(offset: 16, as: UInt64.self)
        let formatVersion: UInt8 = dataArray.readLittleEndian(offset: 24, as: UInt8.self)
        let numChannels: UInt8 = dataArray.readLittleEndian(offset: 25, as: UInt8.self)
        let sampleRate: UInt32 = dataArray.readLittleEndian(offset: 26, as: UInt32.self)
        let bitRate: UInt8 = dataArray.readLittleEndian(offset: 30, as: UInt8.self)
        let numFrames: UInt32 = dataArray.readLittleEndian(offset: 31, as: UInt32.self)
        
        //AudioBufferCollection
        let readingOffset = 35
        
        let audioBuffersSize = data.count - readingOffset
        
        let audioBufferCollection = RRAudioEngine.parseRRAudioBufferData(data.advanced(by: readingOffset), audioBuffersSize: audioBuffersSize)
        
        let rrAudioData = RRAudioData(chunkID: chunckID,
                                      chunkSize: chunkSize,
                                      formatVersion: formatVersion,
                                      numChannels: numChannels,
                                      sampleRate: sampleRate,
                                      bitRate: bitRate,
                                      numFrames: numFrames,
                                      audioBuffers: audioBufferCollection)
        
        return rrAudioData
    }
    
    static func encodeRRAudioData( rrAudioData: RRAudioData) -> Data {
        // 1. urAudioBufferCollectionSize
        let rrAudioBufferCollection = rrAudioData.audioBuffers
        var rrAudioBufferCollectionSize = 0
        var rrAudioBufferDataCollection: [Data] = []
        
        for buffer in rrAudioBufferCollection {
            let date = buffer.date ?? Date().millisecondsSince1970
            let latitude = buffer.metadata?.locationCoordinate.latitude ?? 0
            let longitude = buffer.metadata?.locationCoordinate.longitude ?? 0
            let altitude = buffer.metadata?.locationCoordinate.altitude ?? 0
            
            let roll = buffer.metadata?.motionAttitude.rollDegrees ?? 0
            let pitch = buffer.metadata?.motionAttitude.pitchDegrees ?? 0
            let yaw = buffer.metadata?.motionAttitude.yawDegrees ?? 0
            
            let audioData = Data.init(bytes: buffer.audioData.bytes, count: Int(buffer.mDataByteSize))
            
            let bufferData = RRAudioEngine.encodeRRAudioBufferData(date,
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
            
            rrAudioBufferDataCollection.append(bufferData)
            rrAudioBufferCollectionSize += bufferData.count
        }
        
        let newDataSize: Int = rrAudioBufferCollectionSize + Int(rrAudioData.chunkSize)
        // Allocate Memory
        var newData = Data(count: newDataSize)
        
        // MARK: Encode URAudioData
        newData.replaceSubrange(0..<16, with: withUnsafeBytes(of: rrAudioData.chunkID) { Data($0) })    //  Offset: 0, chunkID

        newData.replaceSubrange(16..<24, with: withUnsafeBytes(of: rrAudioData.chunkSize) { Data($0) })    //  Offset: 16, chunkSize
        
        newData.replaceSubrange(24..<25, with: withUnsafeBytes(of: rrAudioData.formatVersion) { Data($0) })    //  Offset: 24, formatVersion

        newData.replaceSubrange(25..<26, with: withUnsafeBytes(of: rrAudioData.numChannels) { Data($0) })    //  Offset: 25, numChannels

        newData.replaceSubrange(26..<30, with: withUnsafeBytes(of: rrAudioData.sampleRate) { Data($0) })    //  Offset: 26, sampleRate

        newData.replaceSubrange(30..<31, with: withUnsafeBytes(of: rrAudioData.bitRate) { Data($0) })    //  Offset: 30, bitRate
        
        newData.replaceSubrange(31..<35, with: withUnsafeBytes(of: rrAudioData.numFrames) { Data($0) })    //  Offset: 30, numFrames
        // Encode AudioBuffer
        var dataWritingOffset: Int = 35
        
        for data in rrAudioBufferDataCollection {   // Start at offset: 35, urAudioBufferData
            let endOfDataOffset = dataWritingOffset + data.count
            newData.replaceSubrange(dataWritingOffset..<endOfDataOffset, with: data)
            
            dataWritingOffset = endOfDataOffset
        }
        
        return newData
    }
    
    static func getRRAudioBufferAudioSize(_ data: Data) -> UInt32 {
        // Prevent data is not been aligned
        let dataArray = [UInt8](data)
        
        let bufferLength: UInt32 = dataArray.readLittleEndian(offset: 8, as: UInt32.self)    // Offset: 8, bufferLength
        return bufferLength
    }
    
    static func getRRAudioBufferLocationCoordinate(_ data: Data) -> RRLocationCoordinate3D {
        // Prevent data is not been aligned
        let dataArray = [UInt8](data)
        
        let latitude: Double = dataArray.readFloatingPoint(offset: 24, as: Double.self)
        let longitude: Double = dataArray.readFloatingPoint(offset: 32, as: Double.self)
        let altitude: Double = dataArray.readFloatingPoint(offset: 40, as: Double.self)
        
        return RRLocationCoordinate3D(latitude: latitude,
                                      longitude: longitude,
                                      altitude: altitude)
    }
}
