//
//  URRecordingDataHelperTests.swift
//  UrbanRecorderTests
//
//  Created by ting hui wu on 2021/12/7.
//

import XCTest
@testable import UrbanRecorder

class URRecordingDataHelperTests: XCTestCase {

    var sut: URRecordingDataHelper!
    
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
     30             bytesRate   UInt8           1                   ex: 16,24,32
     31             numFrames   UInt32          4
     35             URAudioBuffers
     --------------------------------------------------------------------
     */
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        sut = URRecordingDataHelper()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
        try super.tearDownWithError()
    }
    
    func test_generateEmptyURRecordingData() {
        // given
        let chuckID = UUID().uuidString
        let sampleRate: UInt32 = 48000
        let bitRate: UInt8 = 16
        // when
        let result = sut.generateEmptyURRecordingData(chunkID: chuckID,
                                         sampleRate: sampleRate,
                                                      bitRate: bitRate)
        
        let emptyData = sut.getCurrentRecordingURAudioData()
        // then
        XCTAssertTrue(result)
        XCTAssertNotNil(emptyData)
    }
    
    func test_parseEmptyURAudioData() {
        // given
        let chuckID = UUID().uuidString
        let numberOfChannels: UInt8 = 1
        let sampleRate: UInt32 = 48000
        let bitRate: UInt8 = 16
        
        // when
        let result = sut.generateEmptyURRecordingData(chunkID: chuckID,
                                         sampleRate: sampleRate,
                                                      bitRate: bitRate)
        
        let emptyData = sut.getCurrentRecordingURAudioData()
        // then
        XCTAssertTrue(result)
        XCTAssertNotNil(emptyData)
        
        XCTAssertEqual(chuckID, emptyData!.chunkID)
        XCTAssertEqual(numberOfChannels, emptyData!.numChannels)
        XCTAssertEqual(sampleRate, emptyData!.sampleRate)
        XCTAssertEqual(bitRate, emptyData!.bitRate)
    }
    
    func test_schechuleURAudioBufferThenParseIntoURAudioData() {
        // given
        let chuckID = UUID().uuidString
        let numberOfChannels: UInt8 = 1
        let sampleRate: UInt32 = 48000
        let bitRate: UInt8 = 16
        
        var audioBufferDataCollection: [Data] = []
        
        let bufferCount: Int = Int.random(in: 0..<100)
        
        var generateAudioBuffersSize: Int = 0
        
        let audioBufferMetaDataSize: Int = 72
        
        for _ in 0..<bufferCount {
            let date: UInt64 = Date().millisecondsSince1970
            let bufferLength: UInt32  = UInt32.random(in: 0...65356)
            let nChannel: UInt32 = UInt32(1)
            let sampleRate: UInt32 = UInt32(48000)
            let bitRate: UInt32 = UInt32(16)
            let latitude: Double = Double.random(in: 0...90)
            let longitude: Double = Double.random(in: -180...180)
            let altitude: Double = 0.0
            let roll: Double = Double.random(in: -180...180)
            let pitch: Double = Double.random(in: -180...180)
            let yaw: Double = Double.random(in: -180...180)
            let audioData = Data(count: Int(bufferLength))
            let givenData = URAudioEngine.encodeURAudioBufferData(date, bufferLength, nChannel, sampleRate, bitRate, latitude, longitude, altitude, roll, pitch, yaw, audioData) as Data
            
            audioBufferDataCollection.append(givenData)
            
            generateAudioBuffersSize += Int(bufferLength) + audioBufferMetaDataSize
        }
        
        // when
        let result = sut.generateEmptyURRecordingData(chunkID: chuckID,
                                         sampleRate: sampleRate,
                                                      bitRate: bitRate)
        
        for data in audioBufferDataCollection {
            sut.schechuleURAudioBuffer(data)
        }
        
        let currentData = sut.getCurrentRecordingURAudioData()
        
        let data = URRecordingDataHelper.encodeURAudioData(urAudioData: currentData!)
        // Problem vvv
        let urAudioData = URRecordingDataHelper.parseURAudioData(data)
        // then
        XCTAssertTrue(result)
        XCTAssertNotNil(currentData)
        
        XCTAssertEqual(chuckID, urAudioData.chunkID)
        XCTAssertEqual(UInt64(data.count), urAudioData.chunkSize + UInt64(generateAudioBuffersSize))
        XCTAssertEqual(numberOfChannels, urAudioData.numChannels)
        XCTAssertEqual(sampleRate, urAudioData.sampleRate)
        XCTAssertEqual(bitRate, urAudioData.bitRate)
        XCTAssertEqual(UInt32(bufferCount), urAudioData.numFrames)
        XCTAssertEqual(bufferCount, urAudioData.audioBuffers.count)
        
        for (index, element) in urAudioData.audioBuffers.enumerated() {
            let inputData = URAudioEngine.parseURAudioBufferData(audioBufferDataCollection[index])
            
            XCTAssertEqual(inputData.date, element.date)
            XCTAssertEqual(inputData.mNumberChannels, element.mNumberChannels)
            XCTAssertEqual(inputData.sampleRate, element.sampleRate)
            XCTAssertEqual(inputData.bitRate, element.bitRate)
            
            let inputLocation = inputData.metadata?.locationCoordinate
            let parseLocation = element.metadata?.locationCoordinate
            XCTAssertNotNil(inputLocation)
            XCTAssertNotNil(parseLocation)
            XCTAssertEqual(inputLocation?.altitude, parseLocation?.altitude)
            XCTAssertEqual(inputLocation?.latitude, parseLocation?.latitude)
            XCTAssertEqual(inputLocation?.longitude, parseLocation?.longitude)
            
            let inputMotion = inputData.metadata?.motionAttitude
            let parseMotion = element.metadata?.motionAttitude
            XCTAssertNotNil(inputMotion)
            XCTAssertNotNil(parseMotion)
            XCTAssertEqual(inputMotion?.rollDegrees, parseMotion?.rollDegrees)
            XCTAssertEqual(inputMotion?.pitchDegrees, parseMotion?.pitchDegrees)
            XCTAssertEqual(inputMotion?.yawDegrees, parseMotion?.yawDegrees)
        }
    }
}
