//
//  URAudioEngine.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/2.
//

import Foundation
import AVFoundation
import AVFAudio
import AudioToolbox
import UIKit

class URAudioEngine {
    
    static let instance: URAudioEngine = URAudioEngine()
    
    private var engine: AVAudioEngine = AVAudioEngine()
    
    private var captureAudioBufferDataCallBack: ((Data)->Void)?
    
    var status: URAudioEngineStatus = .unReady
    
    var useCase: URAudioEngineUseCase = .singleRecordWithHighQuality
    
    weak var dataSource: URAudioEngineDataSource?
    
    weak var delegate: URAudioEngineDelegate?
    
    // The convert format default as stereo layout & sampleRate is 48000
    var convertFormat: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channelLayout: ChannelLayout.stereo.object)
    
    var bytesPerFrame: Int {
        return convertFormat.streamDescription.pointee.framesToBytes(1)
    }
    
    private var _multichannelOutputEnabled: Bool = true
    
    private var renderingAlgo: AVAudio3DMixingRenderingAlgorithm {
        if _multichannelOutputEnabled {
            return AVAudio3DMixingRenderingAlgorithm.sphericalHead
        } else {
            return AVAudio3DMixingRenderingAlgorithm.equalPowerPanning
        }
    }
    
    var inputVolumeMeters: PowerMeter = PowerMeter()
    // Streaming Data
    private var rendererData: URAudioOutputData?
    
    private let rendererDataBufferMilliseconds: Int = 0
    
    private let rendererDataMilliseconds: Int = 1 * 60 * 100
    //AudioNode
    lazy var inputAudioUnit: AVAudioUnit? = nil
    
    var streamingMixer: AVAudioMixerNode = AVAudioMixerNode()
    
    var streamingEnvironmentNode: AVAudioEnvironmentNode = AVAudioEnvironmentNode()
    // environment info
    var listenerPosition: AVAudio3DPoint {
        return streamingEnvironmentNode.listenerPosition
    }
    
    var listenerAngularOrientation: AVAudio3DAngularOrientation {
        return streamingEnvironmentNode.listenerAngularOrientation
    }
    
    init() {
        // Set engine inActive
        do {
            var engineOption: AVAudioSession.CategoryOptions = []   // When BluetoothA2DP and the allowBluetooth option are both set, when a single device supports both the Hands-Free Profile (HFP) and A2DP, the system gives hands-free ports a higher priority for routing. But Only A2DP suport spatial audio.
            
            // Set input priority
            for output in AVAudioSession.sharedInstance().currentRoute.outputs {
                if output.portType == .bluetoothA2DP {
                    engineOption = generateCategoryOptions(useCase, supportBluetoothA2Dp: true)
                } else {
                    engineOption = generateCategoryOptions(useCase, supportBluetoothA2Dp: false)
                }
            }
            
            // .measurement Filter the ambient sound, able recording, motion detect
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: engineOption)
            
            try AVAudioSession.sharedInstance().setActive(true)
            
            let desiredNumChannels: Int = 8 // for 7.1 rendering
            let maxChannels: Int = AVAudioSession.sharedInstance().maximumOutputNumberOfChannels
            
            if maxChannels >= desiredNumChannels {
                try AVAudioSession.sharedInstance().setPreferredOutputNumberOfChannels(desiredNumChannels)
            }
            
        } catch {
            status = .failInSetUp
        }
        // Set audioEngine
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // MARK: AudioNode preset
        #warning("Check the precise using mode")
        streamingMixer.sourceMode = .spatializeIfMono
        
        streamingEnvironmentNode.renderingAlgorithm = renderingAlgo
        streamingEnvironmentNode.reverbParameters.enable = true
        streamingEnvironmentNode.reverbParameters.level = -20.0
        streamingEnvironmentNode.reverbParameters.loadFactoryReverbPreset(.plate)
        
        updateListenerPosition(AVAudio3DPoint(x: 0, y: 0, z: 0))
        // MARK: Generate Input AudioUnit
        setupInputAudioUnit()
        
        // MARK: Attach AudioNode
        if let inputAudioUnit = inputAudioUnit {
            engine.attach(inputAudioUnit)
        }
        
        engine.attach(streamingMixer)
        
        engine.attach(streamingEnvironmentNode)
        
        // MARK: RequestRecordPermission
        requestRecordPermission { isGranted in
            if isGranted {
                self.beginTappingMicrophone()
                //
                self.setupAudioNodeConnection()
                // Setup the renderer data
                self.setupRendererAudioData()
                // we're ready to start rendering so start the engine
                self.startEngine()
                
                self.status = .readyWithRecordPermission
                print("AudioEngine: \(self.status)")
            } else {
                #warning("Show Alert View")
                print("Show Alert View")
                // TODO: enable tourist mode
            }
        }
    }
    
    private func setupInputAudioUnit() {
        
        URAudioRenderAudioUnit.registerSubclassOnce
        
        AVAudioUnit.instantiate(with: URAudioRenderAudioUnit.audioCompoentDescription, options: []) { auUnit, error in
            guard error == nil, let auUnit = auUnit else { fatalError() }
            
            self.inputAudioUnit = auUnit
        }
    }
    
    private func beginTappingMicrophone() {
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        let sampleRate = inputFormat.sampleRate
        // Setup Converter
        let formatConverter = AVAudioConverter(from: inputFormat, to: convertFormat)!
        
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(0.1*sampleRate), format: inputFormat) {[weak self, formatConverter, convertFormat] (buffer, time) in
            guard let self = self else { return }
            // Convert received buffer in required format
            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }

            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: convertFormat, frameCapacity: AVAudioFrameCount(convertFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!
            
            var error: NSError? = nil
            let status = formatConverter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            assert(status != .error)
            
            // Process convert buffer data
            let audioBuffers = UnsafeMutablePointer(convertedBuffer.mutableAudioBufferList)[0].mBuffers
            
            self.captureAudioInputBuffer(audioBuffers)
            
            // Calculate the volume of input
//            let bufferData = audioBuffers.mData!
//
//            let bufferSize: Int = Int(audioBuffers.mDataByteSize)
//            let frameCounts = bufferSize / self.bytesPerFrame
//            self.inputVolumeMeters.process_Int16(bufferData.assumingMemoryBound(to: Int16.self), 1, frameCounts)
        }
    }
    
    private func startEngine() {
        do {
            try engine.start()
        } catch {
            status = .failInSetUp
        }
    }
    //MARK: - AudioNode connect
    private func setupAudioNodeConnection() {
        guard let layout: AVAudioChannelLayout = AVAudioChannelLayout.init(layoutTag: kAudioChannelLayoutTag_Stereo) else { return }
        
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channelLayout: layout)
        
        if let inputAudioUnit = inputAudioUnit {
            engine.connect(inputAudioUnit, to: streamingMixer, format: stereoFormat)
        }
        
        engine.connect(streamingMixer, to: streamingEnvironmentNode, format: stereoFormat)
        
        engine.connect(streamingEnvironmentNode, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))
    }
    //MARK: - SetAudioOutputData
    private func setupRendererAudioData() {
        //Init AudioOutputData
        // TODO: Make ms as data size
        rendererData = URAudioOutputData(format: convertFormat, dataMS: rendererDataMilliseconds, bufferMS: rendererDataBufferMilliseconds)
    }
    //MARK: - AudioIOCallback
    public func schechuleRendererAudioBuffer(_ data: NSMutableData) {
        rendererData?.scheduleOutput(data: data)
    }
    
    public func schechuleRendererAudioBuffer(_ buffer: URAudioBuffer) {
        // TODO: Update Environment
        if let metatdata = buffer.metadata {
            let location = metatdata.locationCoordinate
            
            let motion = metatdata.motionAttitude
        }
        // ScheduleAudioData
        rendererData?.scheduleOutput(data: buffer.audioData)
    }
    
    public func setupURAudioEngineCaptureCallBack(_ handler: @escaping ((Data)->Void)) {
        captureAudioBufferDataCallBack = handler
    }
    
    private func captureAudioInputBuffer(_ audioBuffer: AudioBuffer) {
        let currentLocation = dataSource?.urAudioEngine(currentLocationForEngine: self)
        let currentMotion = dataSource?.urAudioEngine(currentMotionForEngine: self)
        
        let date = Date().millisecondsSince1970
        
        #warning("Check channel count")
        let nChannel = UInt32(1)
        let sampleRate = UInt32(convertFormat.sampleRate)
        let bitRate = UInt32(convertFormat.bitRate)
        
        let latitude = currentLocation?.latitude ?? 0
        let longitude = currentLocation?.longitude ?? 0
        let altitude = currentLocation?.altitude ?? 0
        
        let roll = currentMotion?.roll ?? 0
        let pitch = currentMotion?.pitch ?? 0
        let yaw = currentMotion?.pitch ?? 0
        
        guard let mData = audioBuffer.mData else { return }
        let audioData = Data.init(bytes: mData, count: Int(audioBuffer.mDataByteSize))
        
        let urAudioData = encodeURAudioBufferData(date, nChannel, sampleRate, bitRate, latitude, longitude, altitude, roll, pitch, yaw, audioData)
        
        captureAudioBufferDataCallBack?(urAudioData)
    }
    
    /*
     URAudio Formatt
     --------------------------------------------------------------------
     Field Offset | Field Name | Field type | Field Size(byte) | Description
     --------------------------------------------------------------------
     0              date        UInt64           8               MillisecondsSince1970
     8              nChannel    UInt32           4
     12             sampleRate UInt32           4
     16             bitRate    UInt32           4
     20             latitude    Double          8
     28             longitude   Double          8
     36             altitude    Double          8
     44             roll        Double          8
     52             pitch       Double          8
     60             yaw         Double          8
     68             data
     --------------------------------------------------------------------
     */
    // MARK: - Parse data
    static func parseURAudioBufferData(_ data: Data)->(URAudioBuffer) {
        // TODO: parse data into URAudioBuffer
        
        
        // Parse into URAudioBuffer
        let metadataLenght = 68
        let audioBufferLength: UInt32 = UInt32(data.count - metadataLenght)
        
        let date: UInt64 = NSMutableData(data: data.advanced(by: 0)).bytes.load(as: UInt64.self)
        let channel: UInt32 =  NSMutableData(data: data.advanced(by: 8)).bytes.load(as: UInt32.self)
        
        let latitude: Double = NSMutableData(data: data.advanced(by: 20)).bytes.load(as: Double.self)
        let longitude: Double = NSMutableData(data: data.advanced(by: 28)).bytes.load(as: Double.self)
        let altitude: Double = NSMutableData(data: data.advanced(by: 36)).bytes.load(as: Double.self)
        
        let roll: Double = NSMutableData(data: data.advanced(by: 44)).bytes.load(as: Double.self)
        let pitch: Double = NSMutableData(data: data.advanced(by: 52)).bytes.load(as: Double.self)
        let yaw: Double = NSMutableData(data: data.advanced(by: 60)).bytes.load(as: Double.self)
        
        let mData = NSMutableData(data: data.advanced(by: metadataLenght))
            
        let location = URLocationCoordinate3D(latitude: latitude,
                                              longitude: longitude,
                                              altitude: altitude)
        
        let motion = URMotionAttitude(roll: roll,
                                      pitch: pitch,
                                      yaw: yaw)
        
        let metadata: URAudioBufferMetadata = URAudioBufferMetadata(locationCoordinate: location,
                                                                    motionAttitude: motion)
        
        let buffer = URAudioBuffer(mData, audioBufferLength, channel, metadata, date)
        
        return buffer
    }
    
    private func encodeURAudioBufferData(_ date: UInt64,
                                         _ nChannel: UInt32,
                                         _ sampleRate: UInt32,
                                         _ bitRate: UInt32,
                                         _ latitude: Double,
                                         _ longitude: Double,
                                         _ altitude: Double,
                                         _ roll: Double,
                                         _ pitch: Double,
                                         _ yaw: Double,
                                         _ audioData: Data) -> Data {
        
        var data = withUnsafeBytes(of: date) { Data($0) }   // Offset: 0
        data.append(withUnsafeBytes(of: nChannel) { Data($0) }) // Offset: 8
        data.append(withUnsafeBytes(of: sampleRate) { Data($0) })   // Offset: 12
        data.append(withUnsafeBytes(of: bitRate) { Data($0) })  // Offset: 16
        data.append(withUnsafeBytes(of: latitude) { Data($0) }) // Offset: 20
        data.append(withUnsafeBytes(of: longitude) { Data($0) })    // Offset: 28
        data.append(withUnsafeBytes(of: altitude) { Data($0) }) // Offset: 36
        data.append(withUnsafeBytes(of: roll) { Data($0) }) // Offset: 44
        data.append(withUnsafeBytes(of: pitch) { Data($0) })    // Offset: 52
        data.append(withUnsafeBytes(of: yaw) { Data($0) })  // Offset: 60
        data.append(audioData)    // Offset: 68
        
        return data
    }
    // MARK: - Update Environment
    private func updateListenerPosition(_ position: AVAudio3DPoint) {
        streamingEnvironmentNode.listenerPosition = position
    }
    
    private func updateListenerOrientation(_ orientation: AVAudio3DAngularOrientation) {
        streamingEnvironmentNode.listenerAngularOrientation = orientation
    }
    
    private func updateEnvirmentReverb(_ reverbParameters: AVAudioUnitReverbPreset) {
        streamingEnvironmentNode.reverbParameters.loadFactoryReverbPreset(reverbParameters)
    }
    
}

extension URAudioEngine {
    private func generateCategoryOptions(_ useCase: URAudioEngineUseCase, supportBluetoothA2Dp: Bool)-> AVAudioSession.CategoryOptions {
        
        let normalUseCase: AVAudioSession.CategoryOptions = [.allowBluetooth, .mixWithOthers, .defaultToSpeaker]
        let advanceUseCase: AVAudioSession.CategoryOptions = [.allowBluetoothA2DP, .mixWithOthers, .defaultToSpeaker]
        
        switch useCase {
        case .tourist:
            return supportBluetoothA2Dp ? advanceUseCase : normalUseCase
        case .singleRecord:
            return normalUseCase
        case .muiltipleRecord:
            return normalUseCase
        case .singleRecordWithHighQuality:
            return supportBluetoothA2Dp ? advanceUseCase : normalUseCase
        case .muiltipleRecordWithHighQuality:
            return supportBluetoothA2Dp ? advanceUseCase : normalUseCase
        }
    }
    
    private func requestRecordPermission(_ complete: @escaping ((Bool)->Void) ) {
        // Record Permission
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            complete(true)
        default:
            // RecordPermissionAndStartTapping
            AVAudioSession.sharedInstance().requestRecordPermission { isGranted in
                complete(isGranted)
            }
        }
    }
}

extension URAudioEngine: URAudioRenderAudioUnitDelegate {
    func renderAudioBufferPointer(length bitToRead: Int) -> UnsafeMutableRawPointer? {
        guard engine.isRunning else { return nil }
        
        let dataPtr = rendererData?.getReadingData(with: bitToRead)
        
        return dataPtr
    }
}

enum URAudioEngineStatus {
    case unReady
    
    case readyWithRecordPermission
    
    case readyWithoutRecordPermission
    
    case failInSetUp
}

enum URAudioEngineUseCase {
    case tourist
    
    case singleRecord
    
    case muiltipleRecord
    
    case singleRecordWithHighQuality
    
    case muiltipleRecordWithHighQuality
}

enum ChannelLayout {
    
    case mono
    
    case stereo
    
    private var tag: AudioChannelLayoutTag{
        switch self {
        case .mono:
            return kAudioChannelLayoutTag_Mono
        case .stereo:
            return kAudioChannelLayoutTag_Stereo
        }
    }
    
    var object: AVAudioChannelLayout {
        return AVAudioChannelLayout.init(layoutTag: self.tag) ?? AVAudioChannelLayout.init(layoutTag: kAudioChannelLayoutTag_Stereo)!
    }
}
