//
//  UrbanRecorderTests.swift
//  UrbanRecorderTests
//
//  Created by ting hui wu on 2021/11/17.
//

import XCTest
@testable import UrbanRecorder

class UrbanRecorderTests: XCTestCase {

    var sut: URAudioEngine!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        sut = URAudioEngine()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
        try super.tearDownWithError()
    }
    /*
     URAudio Formatt
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
    func test_encodeURAudioBufferData() {
        // given
        let date: UInt64 = Date().millisecondsSince1970
        let bufferLength: UInt32  = UInt32 .random(in: 0...65356)
        let nChannel: UInt32 = UInt32(1)
        let sampleRate: UInt32 = UInt32(48000)
        let bitRate: UInt32 = UInt32(16)
        let latitude: Double = 25.6789
        let longitude: Double = 121.234560
        let altitude: Double = 0.0
        let roll: Double = 1.234
        let pitch: Double = 2.345
        let yaw: Double = 3.456
        let audioData = Data(count: Int(bufferLength))
        // when
        let urAudioData = URAudioEngine.encodeURAudioBufferData(date, bufferLength, nChannel, sampleRate, bitRate, latitude, longitude, altitude, roll, pitch, yaw, audioData)
        // then
        let metaDataSize: Int = MemoryLayout.size(ofValue: date) +
        MemoryLayout.size(ofValue: bufferLength) +
        MemoryLayout.size(ofValue: nChannel) +
        MemoryLayout.size(ofValue: sampleRate) +
        MemoryLayout.size(ofValue: bitRate) +
        MemoryLayout.size(ofValue: latitude) +
        MemoryLayout.size(ofValue: longitude) +
        MemoryLayout.size(ofValue: altitude) +
        MemoryLayout.size(ofValue: roll) +
        MemoryLayout.size(ofValue: pitch) +
        MemoryLayout.size(ofValue: yaw)
        XCTAssertEqual(metaDataSize, 72)
        
        let expectedSize: Int = Int(bufferLength) + metaDataSize
        
        XCTAssertEqual(urAudioData.length, expectedSize)
    }
    
    func test_parseURAudioBufferData() {
        // given
        let date: UInt64 = Date().millisecondsSince1970
        let bufferLength: UInt32  = UInt32 .random(in: 0...65356)
        let nChannel: UInt32 = UInt32(1)
        let sampleRate: UInt32 = UInt32(48000)
        let bitRate: UInt32 = UInt32(16)
        let latitude: Double = 25.6789
        let longitude: Double = 121.234560
        let altitude: Double = 0.0
        let roll: Double = 1.234
        let pitch: Double = 2.345
        let yaw: Double = 3.456
        let audioData = Data(count: Int(bufferLength))
        let givenData = URAudioEngine.encodeURAudioBufferData(date, bufferLength, nChannel, sampleRate, bitRate, latitude, longitude, altitude, roll, pitch, yaw, audioData) as Data
        // when
        let urAudioBufferData = URAudioEngine.parseURAudioBufferData(givenData)
        // then
        XCTAssertEqual(urAudioBufferData.date, date)
        XCTAssertEqual(urAudioBufferData.mDataByteSize, bufferLength)
        XCTAssertEqual(urAudioBufferData.mNumberChannels, nChannel)
        XCTAssertEqual(urAudioBufferData.sampleRate, sampleRate)
        XCTAssertEqual(urAudioBufferData.bitRate, bitRate)
        XCTAssertEqual(urAudioBufferData.metadata?.locationCoordinate.latitude, latitude)
        XCTAssertEqual(urAudioBufferData.metadata?.locationCoordinate.longitude, longitude)
        XCTAssertEqual(urAudioBufferData.metadata?.locationCoordinate.altitude, altitude)
        XCTAssertEqual(urAudioBufferData.metadata?.motionAttitude.roll, roll)
        XCTAssertEqual(urAudioBufferData.metadata?.motionAttitude.pitch, pitch)
        XCTAssertEqual(urAudioBufferData.metadata?.motionAttitude.yaw, yaw)
        XCTAssertEqual(urAudioBufferData.mDataByteSize, bufferLength)
        XCTAssertEqual(urAudioBufferData.audioData.length, audioData.count)
    }
}
