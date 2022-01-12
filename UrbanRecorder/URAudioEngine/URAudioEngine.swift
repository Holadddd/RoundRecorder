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

typealias Second = Double
class URAudioEngine: NSObject {
    
    static let instance: URAudioEngine = URAudioEngine()
    
    static let metaDataUpdatedInterval: Second = 0.5
    
    private var inputEngine: AVAudioEngine = AVAudioEngine()
    
    private var outputEngine: AVAudioEngine = AVAudioEngine()
    
    var currentAbility: URAudioEngineAbility = .undefined
    
    var status: URAudioEngineStatus = .unReady
    
    var useCase: URAudioEngineUseCase = .streamingWithHighQuality
    
    weak var dataSource: URAudioEngineDataSource?
    
    weak var delegate: URAudioEngineDelegate?
    
    // The convert format default as stereo layout & sampleRate is 48000
    var convertFormat: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channelLayout: ChannelLayout.stereo.object)
    
    lazy var inputFormat: AVAudioFormat = inputEngine.inputNode.inputFormat(forBus: 0)
    
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
    // Player Data
    private var playerData: URAudioOutputData?
    
    //AudioNode
    lazy var rendererAudioUnit: AVAudioUnit? = nil
    
    var streamingMixer: AVAudioMixerNode = AVAudioMixerNode()
    
    var streamingEnvironmentNode: AVAudioEnvironmentNode = AVAudioEnvironmentNode()
    
    var mainMixer: AVAudioMixerNode = AVAudioMixerNode()
    // environment info
    var listenerPosition: AVAudio3DPoint {
        return streamingEnvironmentNode.listenerPosition
    }
    
    var listenerAngularOrientation: AVAudio3DAngularOrientation {
        return streamingEnvironmentNode.listenerAngularOrientation
    }
    
    override init() {
        super.init()
        // Set engine inActive
        setupAudioSession()
    }
    
    private func setupAudioSession() {
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
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoChat, options: engineOption)
            
            try AVAudioSession.sharedInstance().setActive(true)
            
            let desiredNumChannels: Int = 8 // for 7.1 rendering
            let maxChannels: Int = AVAudioSession.sharedInstance().maximumOutputNumberOfChannels
            
            if maxChannels >= desiredNumChannels {
                try AVAudioSession.sharedInstance().setPreferredOutputNumberOfChannels(desiredNumChannels)
            }
            
        } catch {
            status = .failInSetUp
        }
    }
    
    private func setupNodeParameters() {
        // MARK: AudioNode preset
        #warning("Check the precise using mode")
        streamingMixer.sourceMode = .spatializeIfMono
        
        streamingEnvironmentNode.renderingAlgorithm = renderingAlgo
        streamingEnvironmentNode.reverbParameters.enable = true
        streamingEnvironmentNode.reverbParameters.level = -20.0
        streamingEnvironmentNode.reverbParameters.loadFactoryReverbPreset(.plate)
        
        updateListenerPosition(AVAudio3DPoint(x: 0, y: 0, z: 0))
    }
    /*
     The AudioSession status is active
     Subscribe: setupInputAudioUnit -> setupNodeAttachment -> setupAudioNodeConnection -> startEngine
     Broadcast: setupNodeAttachment ->          setupAudioNodeConnection  -> setupRendererAudioData -> startEngine
                                    \(IF Granted)               ^
                                     - > beginTappingMicrophone/
     
     Case
     Subscribe
     Broadcast
     SubscribeThenBroadcast
     BroadcastThenSubscribe
     */
    // TODO: Write a Task for concurrenct queue
    func setupAudioEngineEnvironmentForScheduleAudioData() {
        switch currentAbility {
        case .undefined, .CaptureAudioData:
            let taskAfterSetupInputAudioUnit = {[weak self] in
                guard let self = self else { return }

                // 2. Store the incoming data with custom allocat size
                self.setupRendererAudioData(updatedInterval: URAudioEngine.metaDataUpdatedInterval)
                // 3. Attach node on audioEngine
                self.setupOutputNodeAttachment()
                // 4. Connect node with specify sequence and format
                self.setupAudioOutputNodeConnection()
                
                self.startOutputEngine()   // This will change switch AirPod connection from other device
                
                self.currentAbility = self.currentAbility == .CaptureAudioData ? .ScheduleAndCaptureAudioData : .ScheduleAudioData
            }
            // 1. Set up Audio Unit For render the input streaming data while engine is running
            if rendererAudioUnit == nil {
                setupRendererAudioUnit() {
                    taskAfterSetupInputAudioUnit()
                }
            } else {
                taskAfterSetupInputAudioUnit()
            }
        case .ScheduleAudioData:
            print("The Ability of Schechule AudioData is been active")
        default:
            print("Unhandle ability")
            break
        }
    }
    // Make sure the microphone access is been granted
    func setupAudioEngineEnvironmentForCaptureAudioData() {
        switch currentAbility {
        case .undefined:
            beginTappingMicrophone()
            
            startInputEngine()   // This will change hte AirPod connect to the device
            
            currentAbility = .CaptureAudioData
            
            print("Ability: \(currentAbility)")
        case .ScheduleAudioData:
            beginTappingMicrophone()
            
            startInputEngine()   // Console: AUAudioUnit.mm:1352  Cannot set maximumFramesToRender while render resources allocated.
            
            currentAbility = .ScheduleAndCaptureAudioData
            
            print("Ability: \(currentAbility)")
        case .CaptureAudioData:
            print("The Ability of CaptureAudioData is been active")
        default:
            print("Unhandle ability")
            break
        }
    }
    
    func stopCaptureAudioData() {
        switch currentAbility {
        case .undefined:
            print("No Capture ability can be terminate")
        case .ScheduleAudioData:
            print("No Capture ability can be terminate")
        case .CaptureAudioData:
            print("Terminate Capture ability and stop engine")
            
            removeTappingMicrophone()
            pauseInputEngine()
            
            currentAbility = .undefined
        case .ScheduleAndCaptureAudioData:
            print("Terminate Capture ability(remove capture callback) and keep schedule ability")
            removeTappingMicrophone()
            pauseInputEngine()
            
            currentAbility = .ScheduleAudioData
        }
    }
    
    func stopScheduleAudioData() {
        switch currentAbility {
        case .undefined:
            print("No ScheduleAudioData ability can be terminate")
        case .CaptureAudioData:
            print("No ScheduleAudioData ability can be terminate")
        case .ScheduleAudioData:
            
            rendererData = nil
            
            pauseOutputEngine()
            
            currentAbility = .undefined
            print("Terminate ScheduleAudioData ability and stop engine")
        case .ScheduleAndCaptureAudioData:
            print("Terminate ScheduleAudioData ability(remove rendererData & inputUnit) and keep CaptureAudioData ability")
            
            rendererData = nil
            
            pauseOutputEngine()
            
            currentAbility = .CaptureAudioData
        }
    }
    
    private func setupOutputNodeAttachment() {
        // Engine wont multi attaching node on
        if let rendererAudioUnit = rendererAudioUnit {
            outputEngine.attach(rendererAudioUnit)
        }
        
        outputEngine.attach(streamingMixer)   // Console: UrbanRecorder[56842:741656] throwing -10878
        
        outputEngine.attach(streamingEnvironmentNode)
    }
    
    private func setupRendererAudioUnit(_ completion: @escaping()->Void ) {
        
        URAudioRenderAudioUnit.registerSubclassOnce
        
        AVAudioUnit.instantiate(with: URAudioRenderAudioUnit.audioCompoentDescription, options: []) { auUnit, error in
            guard error == nil, let auUnit = auUnit else { fatalError() }

            self.rendererAudioUnit = auUnit

            completion()
        }
    }
    
    private func beginTappingMicrophone() {
        guard !inputEngine.isRunning else {
            print("Tapping Microphone cant install while the engine is running")
            return
        }
        let inputNode = inputEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        let sampleRate = inputFormat.sampleRate
        // Setup Converter
        let formatConverter = AVAudioConverter(from: inputFormat, to: convertFormat)!
        // Remove tap on bus 0 for prevent multiple install tap
        inputNode.removeTap(onBus: 0)
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
            
        }
    }
    
    private func removeTappingMicrophone() {
        let inputNode = inputEngine.inputNode
        inputNode.removeTap(onBus: 0)
    }
    
    private func pauseInputEngine() {
        if inputEngine.isRunning {
            inputEngine.pause()
        } else {
            print("Engine is not running")
        }
    }
    
    private func startInputEngine() {
        if !inputEngine.isRunning {
            do {
                inputEngine.prepare()
                try inputEngine.start()
            } catch {
                print("InputEngine is fail start")
            }
        } else {
            print("InputEngine is running")
        }
        
    }
    
    private func pauseOutputEngine() {
        if outputEngine.isRunning {
            outputEngine.pause()
        } else {
            print("Engine is not running")
        }
    }
    
    private func startOutputEngine() {
        if !outputEngine.isRunning {
            do {
                outputEngine.prepare()
                try outputEngine.start()
            } catch {
                print("OutputEngine is fail start")
            }
        } else {
            print("OutputEngine is running")
        }
        
    }
    //MARK: - AudioNode connect
    private func setupAudioOutputNodeConnection() {
        // Keep Layout as Mono to play SpactialAudio
        guard let monoLayout: AVAudioChannelLayout = AVAudioChannelLayout.init(layoutTag: kAudioChannelLayoutTag_Mono) else { return }
        
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channelLayout: monoLayout)
        
        guard let stereoLayout: AVAudioChannelLayout = AVAudioChannelLayout.init(layoutTag: kAudioChannelLayoutTag_Stereo) else { return }
        
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channelLayout: stereoLayout)
        
        if let rendererAudioUnit = rendererAudioUnit {
            outputEngine.connect(rendererAudioUnit, to: streamingMixer, format: monoFormat)
        }
        
        outputEngine.connect(streamingMixer, to: streamingEnvironmentNode, format: monoFormat)
        
        let outputFormat = outputEngine.outputNode.outputFormat(forBus: 0)
        print(outputFormat)
        
        outputEngine.connect(streamingEnvironmentNode, to: outputEngine.outputNode, format: stereoFormat)  // Console: [AUSpatialMixerV2] OutputElement: Unsupported number of channels 0 in audio channel layout UseChannelDescriptions: must be two or more
    }
    //MARK: - SetAudioOutputData
    private func setupRendererAudioData(updatedInterval: Double) {
        rendererData = URAudioOutputData(format: convertFormat, dataMS: rendererDataMilliseconds, bufferMS: rendererDataBufferMilliseconds)
        
        rendererData?.setupReadingMetadataCallback(interval: updatedInterval, {[weak self] receivingMetadata in
            guard let self = self else { return }
            self.updateReceivingMetadata(receivingMetadata)
        })
    }
    //MARK: - AudioIOCallback
    public func schechuleRendererAudioBuffer(_ buffer: URAudioBuffer) {
        // ScheduleAudioBuffer
        rendererData?.scheduleURAudioBuffer(buffer: buffer)
    }
    
    private func captureAudioInputBuffer(_ audioBuffer: AudioBuffer) {
        guard let currentLocation = dataSource?.urAudioEngine(currentLocationForEngine: self) else { return }
        let trueNorthAnchorsMotion = dataSource?.urAudioEngine(currentTrueNorthAnchorsMotionForEngine: self)
        
        let date = Date().millisecondsSince1970
        
        let nChannel = UInt32(audioBuffer.mNumberChannels)
        let sampleRate = UInt32(convertFormat.sampleRate)
        let bitRate = UInt32(convertFormat.bitRate)
        
        let latitude = currentLocation.latitude
        let longitude = currentLocation.longitude
        let altitude = currentLocation.altitude
        
        let roll = trueNorthAnchorsMotion?.rollDegrees ?? 0
        let pitch = trueNorthAnchorsMotion?.pitchDegrees ?? 0
        let yaw = trueNorthAnchorsMotion?.yawDegrees ?? 0
        
        guard let mData = audioBuffer.mData else { return }
        let bufferLenght = audioBuffer.mDataByteSize
        let audioData = Data.init(bytes: mData, count: Int(bufferLenght))
        
        let urAudioData = URAudioEngine.encodeURAudioBufferData(date, bufferLenght, nChannel, sampleRate, bitRate, latitude, longitude, altitude, roll, pitch, yaw, audioData)
        
        delegate?.captureAudioBufferDataCallBack(self, urAudioData: urAudioData)
    }
    // MARK: Player feature
    public func setupPlayerDataAndStartPlayingAtSeconds(_ data: URAudioData, startOffset: Second, updateInterval: Second, updateDurationCallback: @escaping ((Second)->Void), endOfFilePlayingCallback: @escaping ((Second)->Void)) {
        // 1. Generate URAudioOutputData with data formatt
        playerData = URAudioOutputData(data: data)
        
        playerData?.setupEndOfFilePlayingCallback(endOfFilePlayingCallback)
        
        playerData?.setupReadingDurationCallback(interval: updateInterval, updateDurationCallback)
        
        playerData?.setupReadingMetadataCallback(interval: updateInterval, {[weak self] receivingMetadata in
            guard let self = self else { return }
            self.updateReceivingMetadata(receivingMetadata)
        })
        // 2. Calculate the offset and schechule rest of the frame
        playerData?.setReadingOffset(second: startOffset)
        // 3. Setup audioEngine environment
        useCase = .player
        
    }
    
    public func removePlayerData() {
        playerData = nil
    }
    
    private func updateReceivingMetadata(_ receivingMetadata: URAudioBufferMetadata) {
        // View
        delegate?.didUpdateReceiversBufferMetaData(self, metaData: receivingMetadata)
        
        // MARK: Update Orientation
        if let userTrueNorthAnchorsMotion = self.dataSource?.urAudioEngine(currentTrueNorthAnchorsMotionForEngine: self) {
            let yawDegrees: Float = Float(userTrueNorthAnchorsMotion.yawDegrees)
            let pitchDegrees: Float = Float(userTrueNorthAnchorsMotion.pitchDegrees)
            let rollDegrees: Float = Float(userTrueNorthAnchorsMotion.rollDegrees)
            let userOrientation = AVAudio3DAngularOrientation(yaw: yawDegrees, pitch: pitchDegrees, roll: rollDegrees)
            
            updateListenerOrientation(userOrientation)
        }
        // NotUsing
        let _ = receivingMetadata.motionAttitude
        
        // MARK: Update Position
        if let userLocation = self.dataSource?.urAudioEngine(currentLocationForEngine: self) {
            let receiverLocation = receivingMetadata.locationCoordinate
            let directionAndDistance = userLocation.distanceAndDistance(from: receiverLocation)
            // Audio Engine
            let listenerPosition = URAudioEngine.get3DMetersPositionWith(directionAndDistance)
            
            updateListenerPosition(listenerPosition)
        }
    }
    /*
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
    // MARK: - Parse data
    static func parseURAudioBufferData(_ data: Data)->(URAudioBuffer) {
        
        // Prevent data is not been aligned
        let dataArray = [UInt8](data)
        // Parse into URAudioBuffer
        let metadataLenght = 72
        let date: UInt64 = dataArray.readLittleEndian(offset: 0, as: UInt64.self)
        
        let audioBufferLength: UInt32 = dataArray.readLittleEndian(offset: 8, as: UInt32.self)
        
        let channel: UInt32 =  dataArray.readLittleEndian(offset: 12, as: UInt32.self)
        let sampleRate: UInt32 =  dataArray.readLittleEndian(offset: 16, as: UInt32.self)
        let bitRate: UInt32 =  dataArray.readLittleEndian(offset: 20, as: UInt32.self)
        
        let latitude: Double = dataArray.readFloatingPoint(offset: 24, as: Double.self)
        let longitude: Double = dataArray.readFloatingPoint(offset: 32, as: Double.self)
        let altitude: Double = dataArray.readFloatingPoint(offset: 40, as: Double.self)
        
        let trueNorthRollDegrees: Double = dataArray.readFloatingPoint(offset: 48, as: Double.self)
        let trueNorthPitchDegrees: Double = dataArray.readFloatingPoint(offset: 56, as: Double.self)
        let trueNorthYawDegrees: Double = dataArray.readFloatingPoint(offset: 64, as: Double.self)
        
        let startOffset = metadataLenght
        let endOffset = metadataLenght + Int(audioBufferLength)
        let mDataArray = dataArray[startOffset..<endOffset]
        let mData = NSMutableData(data: Data(mDataArray))
        
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
    
    static func parseURAudioBufferData(_ data: Data, audioBuffersSize: Int)->[URAudioBuffer] {
        var readingOffset: Int = 0
        
        var bufferCollectinos: [URAudioBuffer] = []
        
        let metadataLenght = 72
        
        // Prevent data is not been aligned
        let dataArray = [UInt8](data)
        
        while readingOffset < audioBuffersSize {
            let date: UInt64 = dataArray.readLittleEndian(offset: readingOffset + 0, as: UInt64.self)
            
            let audioBufferLength: UInt32 = dataArray.readLittleEndian(offset: readingOffset + 8, as: UInt32.self)
            
            let channel: UInt32 =  dataArray.readLittleEndian(offset: readingOffset + 12, as: UInt32.self)
            let sampleRate: UInt32 =  dataArray.readLittleEndian(offset: readingOffset + 16, as: UInt32.self)
            let bitRate: UInt32 =  dataArray.readLittleEndian(offset: readingOffset + 20, as: UInt32.self)
            
            let latitude: Double = dataArray.readFloatingPoint(offset: readingOffset + 24, as: Double.self)
            let longitude: Double = dataArray.readFloatingPoint(offset: readingOffset + 32, as: Double.self)
            let altitude: Double = dataArray.readFloatingPoint(offset: readingOffset + 40, as: Double.self)
            
            let trueNorthRollDegrees: Double = dataArray.readFloatingPoint(offset: readingOffset + 48, as: Double.self)
            let trueNorthPitchDegrees: Double = dataArray.readFloatingPoint(offset: readingOffset + 56, as: Double.self)
            let trueNorthYawDegrees: Double = dataArray.readFloatingPoint(offset: readingOffset + 64, as: Double.self)
            
            let startOffset = readingOffset + metadataLenght
            let endOffset = readingOffset + metadataLenght + Int(audioBufferLength)
            let mDataArray = dataArray[startOffset..<endOffset]
            let mData = NSMutableData(data: Data(mDataArray))
            
            let location = URLocationCoordinate3D(latitude: latitude,
                                                  longitude: longitude,
                                                  altitude: altitude)
            
            let trueNorthMotion = URMotionAttitude(rollDegrees: trueNorthRollDegrees,
                                          pitchDegrees: trueNorthPitchDegrees,
                                          yawDegrees: trueNorthYawDegrees)
            
            let metadata: URAudioBufferMetadata = URAudioBufferMetadata(locationCoordinate: location,
                                                                        motionAttitude: trueNorthMotion)
            
            let buffer = URAudioBuffer(mData, audioBufferLength, channel, sampleRate, bitRate, metadata, date)
            
            bufferCollectinos.append(buffer)
            
            readingOffset += (Int(audioBufferLength) + metadataLenght)
        }
        
        return bufferCollectinos
    }
    
    static func encodeURAudioBufferData(_ date: UInt64,
                                         _ bufferLength: UInt32,
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
        data.append(withUnsafeBytes(of: bufferLength) { Data($0) }) // Offset: 8
        data.append(withUnsafeBytes(of: nChannel) { Data($0) }) // Offset: 12
        data.append(withUnsafeBytes(of: sampleRate) { Data($0) })   // Offset: 16
        data.append(withUnsafeBytes(of: bitRate) { Data($0) })  // Offset: 20
        data.append(withUnsafeBytes(of: latitude) { Data($0) }) // Offset: 24
        data.append(withUnsafeBytes(of: longitude) { Data($0) })    // Offset: 32
        data.append(withUnsafeBytes(of: altitude) { Data($0) }) // Offset: 40
        data.append(withUnsafeBytes(of: roll) { Data($0) }) // Offset: 48
        data.append(withUnsafeBytes(of: pitch) { Data($0) })    // Offset: 56
        data.append(withUnsafeBytes(of: yaw) { Data($0) })  // Offset: 64
        data.append(audioData)    // Offset: 72
        
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
        case .streamingWithHighQuality, .player:
            return supportBluetoothA2Dp ? advanceUseCase : normalUseCase
        case .streaming:
            return normalUseCase
        }
    }
    
    func requestRecordPermissionAndStartTappingMicrophone(_ complete: @escaping ((Bool)->Void) ) {
        // Record Permission
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            
            if status != .readyWithRecordPermission {
                
                self.status = .readyWithRecordPermission
                
            }
            complete(true)
        default:
            // RecordPermissionAndStartTapping
            AVAudioSession.sharedInstance().requestRecordPermission { isGranted in
                
                if isGranted {
                    self.status = .readyWithRecordPermission
                    
                } else {
                    self.status = .readyWithoutRecordPermission
                }
                complete(isGranted)
                print("AudioEngine: \(self.status)")
            }
        }
    }
}

extension URAudioEngine: URAudioRenderAudioUnitDelegate {
    func renderAudioBufferPointer(length bitToRead: Int) -> UnsafeMutableRawPointer? {
        guard outputEngine.isRunning else { return nil }
        
        switch useCase {
        case .streaming, .streamingWithHighQuality:
            return rendererData?.getReadingDataPtr(with: bitToRead)
        case .player:
            return playerData?.getReadingDataPtr(with: bitToRead)
        }
    }
}

extension URAudioEngine {
    static func get3DMetersPositionWith(_ directionAndDistance: UR3DDirectionAndDistance) -> AVAudio3DPoint {
        
        // Direction Degrees Point To Receiver
        // Positive X is direct to the east
        // Negitive Z is direct to the north
        // Y is for elevation
        // Transfer TrueNorth degrees to quadrant degrees
        let quadrantDegrees = -directionAndDistance.direction + 90
        let degreesInPi = (quadrantDegrees / 180 * Double.pi)
        
        let distanceMeters = directionAndDistance.distance > 5 ? 10 : directionAndDistance.distance
        let x: Float = -Float(cos(degreesInPi) * distanceMeters)
        let y: Float = 0
        let z: Float = Float(sin(degreesInPi) * distanceMeters)
        
        let position = AVAudio3DPoint(x: x, y: y, z: z)
        
        return position
    }
}

enum URAudioEngineAbility {
    case undefined
    case ScheduleAudioData
    case CaptureAudioData
    case ScheduleAndCaptureAudioData
}


enum URAudioEngineStatus {
    case unReady
    
    case readyWithRecordPermission
    
    case readyWithoutRecordPermission
    
    case failInSetUp
}

enum URAudioEngineUseCase {
    case streamingWithHighQuality
    
    case streaming
    
    case player
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
