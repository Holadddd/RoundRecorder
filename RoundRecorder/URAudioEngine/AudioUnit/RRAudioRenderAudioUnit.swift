//
//  RRAudioRenderAudioUnit.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/3.
//

protocol RRAudioRenderAudioUnitDelegate: AnyObject {
    func renderAudioBufferPointer(length bitToRead: Int) -> UnsafeMutableRawPointer?
}

import AVFoundation

class RRAudioRenderAudioUnit: AUAudioUnit {
    
    private let renderCallback: AUInternalRenderBlock = { (actionFlags, timeStamp, frameCount, outputBusNumber, outputData, renderEvent, pullInputBlock) in
        
        let AudioEngine: RRAudioEngine = RRAudioEngine.instance
        
        guard AudioEngine.currentAbility == .ScheduleAudioData || AudioEngine.currentAbility == .ScheduleAndCaptureAudioData  else {print("No Subscribe ability"); return noErr}
        
        let bitsPerFrame = AudioEngine.bytesPerFrame
        
        let bitToRead = Int(frameCount) * bitsPerFrame
        
        guard let renderData = AudioEngine.renderAudioBufferPointer(length: bitToRead) else {
            
            return noErr
        }
        
        let outputABL = UnsafeMutableAudioBufferListPointer(outputData)
        
        // outputData.counr is channel count
        for i in 0..<outputABL.count {
            let outputData = outputABL[i].mData
            let inputData = renderData
            
            if outputData == nil {
                // 如果沒有 output data 記憶體位置則將 output data 的記憶體位置指向 source data 的記憶體位置
                outputABL[i].mData = inputData
                outputABL[i].mDataByteSize = UInt32(bitToRead)
            } else if outputData != inputData {
                // 如果沒有 output data 與 input data 為不同記憶體位置，將 input data 位置後以 bitToRead 為數量的資料 copy 到 output data 上
                outputABL[i].mData = inputData
                outputABL[i].mDataByteSize = UInt32(bitToRead)
            }
        }

        return noErr
    }
    
    // MARK: - Global
    
    static let audioCompoentDescription = AudioComponentDescription(
        componentType: kAudioUnitType_Generator,
        componentSubType: hfsTypeCode("ARSc"), //AudioRenderinSource
        componentManufacturer: hfsTypeCode("Demo"),
        componentFlags: 0,
        componentFlagsMask: 0)
    
    static let registerSubclassOnce: Void = {
        AUAudioUnit.registerSubclass(RRAudioRenderAudioUnit.self,
                                     as: RRAudioRenderAudioUnit.audioCompoentDescription,
                                     name: "AudioRenderAudioUnit",
                                     version: UINT32_MAX)
    }()
    
    var _outputBusArray: AUAudioUnitBusArray!
    
    var pcmBuffer: AVAudioPCMBuffer!
    
    override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions = []) throws {
        
        do {
            try super.init(componentDescription: componentDescription, options: options)
            
            try setupIOFromat()
        } catch {
            throw error
        }
        
    }
    
    private func setupIOFromat() throws {
        let sampleRate = AVAudioSession.sharedInstance().sampleRate
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            abort()
        }
        do {
            let bus = try AUAudioUnitBus(format: format)
            self._outputBusArray = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [bus])
        } catch {
            throw error
        }
    }
    
    override var internalRenderBlock: AUInternalRenderBlock {
        
        return renderCallback
    }
    
    override var outputBusses : AUAudioUnitBusArray {
        return self._outputBusArray
    }
    override func allocateRenderResources() throws {
        do {
            try super.allocateRenderResources()
        } catch {
            throw error
        }
        
        let bus = self.outputBusses[0]
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: bus.format, frameCapacity: self.maximumFramesToRender)
    }
    
    override func deallocateRenderResources() {
        // Kernelからバッファを解放
        pcmBuffer = nil
    }
    
    override func shouldChange(to format: AVAudioFormat, for bus: AUAudioUnitBus) -> Bool {
        return true
    }
}

func hfsTypeCode(_ fileTypeString: String) -> OSType
{
    var result: OSType = 0
    var i: UInt32 = 0
    
    for uc in fileTypeString.unicodeScalars {
        result |= OSType(uc) << ((3 - i) * 8)
        i += 1
    }
    
    return result;
}


public typealias KernelRenderBlock = (_ buffer: AVAudioPCMBuffer) -> Void

class Atomic<T> {
    init(val: T) {
        self._value = val
    }
    
    var value: T {
        get {
            objc_sync_enter(self)
            let result = _value
            objc_sync_exit(self)
            return result
        }
        set {
            objc_sync_enter(self)
            _value = newValue
            objc_sync_exit(self)
        }
    }
    
    private var _value: T
}

class AudioUnitSampleKernel {
    var buffer = Atomic<AVAudioPCMBuffer?>(val: nil)
    var renderBlock = Atomic<KernelRenderBlock?>(val: nil)
}
