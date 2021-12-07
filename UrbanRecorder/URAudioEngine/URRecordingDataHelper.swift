//
//  URRecordingDataHelper.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/6.
//

import Foundation
import AVFoundation

class URRecordingDataHelper: NSObject {

    static let URAudioDataFormatVersion: UInt8 = 1
    
    private var recordData: Data?
    
    private var numberOfFrames: Int = 0
    
    private var dataSize: Int = 0
    
    private var outputDataBufferSize: Int = 0
    
    private var outputDataOffset: Int = 0
    
    private var tmpOutputDataOffset: Int = 0
    
    private var readingDataOffset: Int = 0
    
    private var startTime: Int64 = 0 // MillisecondsSince1970
    
    private var audioDuration: Int64 = 0 // Second
    
    override init() {
        super.init()
        
    }
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
     */
    // MARK: Write
    public func generateEmptyURRecordingData(chunkID: String = UUID().uuidString, numChannels: UInt8, sampleRate: UInt32, bitRate: UInt8) -> Bool {
        var newData = Data(count: 35)
        numberOfFrames = 0
        newData.replaceSubrange(0..<16, with: withUnsafeBytes(of: chunkID) { Data($0) })    //  Offset: 0, chunkID
        
        newData.replaceSubrange(24..<25, with: withUnsafeBytes(of: URRecordingDataHelper.URAudioDataFormatVersion) { Data($0) })    //  Offset: 24, formatVersion
        
        newData.replaceSubrange(25..<26, with: withUnsafeBytes(of: numChannels) { Data($0) })    //  Offset: 25, numChannels
        
        newData.replaceSubrange(26..<30, with: withUnsafeBytes(of: sampleRate) { Data($0) })    //  Offset: 26, sampleRate
        
        newData.replaceSubrange(30..<31, with: withUnsafeBytes(of: bitRate) { Data($0) })    //  Offset: 30, bitRate
        
        recordData = newData
        return true
    }
    
    public func schechuleURAudioBuffer(_ buffer:  Data) {
        guard recordData != nil else { print("Record Data is not generate"); return }
        numberOfFrames += 1
        recordData!.append(buffer)
    }
    // MARK: Read
    public func getCurrentRecordingData() -> Data? {
        guard var currentData = recordData else { print("Fail to get recordData") ;return nil }
        //TODO: Write the empty info(chunkSize, numFrames)
        
        currentData.replaceSubrange(16..<24, with: withUnsafeBytes(of: UInt64(currentData.count)) { Data($0) })     //  Offset: 16, chunckSize
        
        currentData.replaceSubrange(31..<35, with: withUnsafeBytes(of: UInt32(numberOfFrames)) { Data($0) })     //  Offset: 31, numFrames
        
        return currentData
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
            
            let audioBuffer = URRecordingDataHelper.parseURAudioBufferData(source: NSMutableData(data: data.advanced(by: readingOffset)).bytes, urAudioBufferSize: currentBufferSize)
            
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
    
    static func parseURAudioBufferData(source: UnsafeRawPointer, urAudioBufferSize: UInt32)->URAudioBuffer {
        
        let metadataLenght = 72
        
        let date: UInt64 = source.load(fromByteOffset: 0, as: UInt64.self)
        
        let audioBufferLength: UInt32 =  source.load(fromByteOffset: 8, as: UInt32.self)
        
        let channel: UInt32 =  source.load(fromByteOffset: 12, as: UInt32.self)
        let sampleRate: UInt32 =  source.load(fromByteOffset: 16, as: UInt32.self)
        let bitRate: UInt32 =  source.load(fromByteOffset: 20, as: UInt32.self)
        
        let latitude: Double = source.load(fromByteOffset: 24, as: Double.self)
        let longitude: Double = source.load(fromByteOffset: 32, as: Double.self)
        let altitude: Double = source.load(fromByteOffset: 40, as: Double.self)
        
        let trueNorthRollDegrees: Double = source.load(fromByteOffset: 48, as: Double.self)
        let trueNorthPitchDegrees: Double = source.load(fromByteOffset: 56, as: Double.self)
        let trueNorthYawDegrees: Double = source.load(fromByteOffset: 64, as: Double.self)
        
        let mData = NSMutableData.init(bytes: source.advanced(by: metadataLenght), length: Int(urAudioBufferSize))
            
        let location = URLocationCoordinate3D(latitude: latitude,
                                              longitude: longitude,
                                              altitude: altitude)
        
        let trueNorthMotion = URMotionAttitude(rollDegrees: trueNorthRollDegrees,
                                      pitchDegrees: trueNorthPitchDegrees,
                                      yawDegrees: trueNorthYawDegrees)
        
        let metadata: URAudioBufferMetadata = URAudioBufferMetadata(locationCoordinate: location,
                                                                    motionAttitude: trueNorthMotion)
        
        let buffer = URAudioBuffer(mData, audioBufferLength, channel, sampleRate, bitRate, metadata, date)
        
        return buffer
    }
}
