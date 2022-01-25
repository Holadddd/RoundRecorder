//
//  RRAudioOutputData.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/3.
//

import Foundation
import AVFoundation

class RRAudioOutputData: NSObject {
    
    // Data type
    private var dataUseCase: RRAudioEngineUseCase = .streaming
    // Data from UDP socket
    private var outputData: NSMutableData?
    // Allocate size for data memory
    private var outputDataSize: Int = 0
    // Buffer size for real time connection unlinear trasfer
    private var outputDataBufferSize: Int = 0
    // Count for real data size
    private var outputDataOffset: Int = 0
    // Count for real data size in different cycle
    private var tmpOutputDataOffset: Int = 0
    //
    private var dataBitRate: Int = 0
    private var dataSampleRate: Double = 0
    private var samplesPerMs: Double {
        return dataSampleRate / 1000
    }
    private var bitsPerMs: Double {
        return dataSampleRate / 1000 * Double(dataBitRate)
    }
    private var bytesPerMs: Double {
        return dataSampleRate / 1000 * Double(dataBitRate / 8)
    }
    // RRAudioBufferMetadata
    typealias locationOffet = Int
    private var audioBufferMetadatas: [(locationOffet, RRAudioBufferMetadata?)] = []
    private var metadatasReadingIndex: Int = 0
    
    private var tmpAudioBufferMetadatas: [(locationOffet, RRAudioBufferMetadata?)] = []
    
    private var readingDataOffset: Int = 0
    // Trun false while the data is out of the same cycle and write at the front
    private var isReadAndWriteInSameCycling: Bool = true
    // Debug Helper
    private var resetCount: Int = 0
    // Start Writing Data
    private var isBlankData: Bool = true
    /* Callback */
    // Duration
    private var durationInterval: Second = 10
    private var lastUpdatedDuration: Second = 0
    private var currentDurationCallback: ((Second)->Void)?
    // Metadata
    private var metadataInterval: Second = 10
    private var lastUpdatedMetadata: Second = 0
    private var currentMetadataCallback: ((RRAudioBufferMetadata)->Void)?
    // End Of File
    private var endOfFilePlayingCallback: ((Second)->Void)?
    
    init(dataSize: Int, bufferBytesSize: Int) {
        super.init()
        
        outputDataSize = dataSize
        
        outputDataBufferSize = bufferBytesSize
        
        self.generateEmptyData()
    }
    
    private func generateEmptyData() {
        outputData = NSMutableData(length: outputDataSize)
        //Input empty bufferData
        let emptyBufferData = NSMutableData(length: outputDataBufferSize)
        
        outputData?.replaceBytes(in: NSRange(location: 0, length: emptyBufferData!.length), withBytes: emptyBufferData!.mutableBytes)
        
        readingDataOffset = 0
        
        print("Init Audio Output Data||Size:\(outputDataSize) buffer:\(outputDataBufferSize)")
    }
    // Streaming
    convenience init(format: AVAudioFormat, dataMS: Int, bufferMS: Int) {
        let bits = format.bitRate
        
        let samplesPerMs = format.sampleRate / 1000
        
        let dataBytesSize = Double(dataMS) * samplesPerMs * (Double(bits) / 8)
        let bufferBytesSize = Double(bufferMS) * samplesPerMs * (Double(bits) / 8)
        
        self.init(dataSize: Int(dataBytesSize), bufferBytesSize: Int(bufferBytesSize))
        
        dataBitRate = bits
        
        dataSampleRate = format.sampleRate
    }
    // Player
    convenience init(data: RRAudioData) {
        
        var dataSize: Int = 0
        
        for buffer in data.audioBuffers {
            dataSize += Int(buffer.mDataByteSize)
        }
        
        self.init(dataSize: dataSize, bufferBytesSize: 0)
        
        // Data format
        dataBitRate = Int(data.bitRate)
        
        dataSampleRate = Double(data.sampleRate)
        // Schedule Buffer
        for buffer in data.audioBuffers {
            self.scheduleRRAudioBuffer(buffer: buffer)
        }
        
        dataUseCase = .player
    }
    
    func setupEndOfFilePlayingCallback(_ callback:@escaping ((Second)->Void)) {
        endOfFilePlayingCallback = callback
    }
    
    func setupReadingDurationCallback(interval: Second, _ callback:@escaping ((Second)->Void)) {
        self.durationInterval = interval
        currentDurationCallback = callback
    }
    
    func setupReadingMetadataCallback(interval: Second, _ callback:@escaping ((RRAudioBufferMetadata)->Void)) {
        self.metadataInterval = interval
        currentMetadataCallback = callback
    }
    
    func setReadingOffset(second: Second) {
        // Second -> MS
        let readingMS = second * 1000
        // MS -> DataOffset(Size)
        let offset = readingMS * bytesPerMs
        
        readingDataOffset = Int(offset)
    }
    //
    func isReadyForReading(with bytesToRead: Int) -> Bool {
        guard !isBlankData else { return false }
        // Make sure there is the data comming in
        if isReadAndWriteInSameCycling {
            // The data is longer than buffersize
            guard  outputDataOffset > outputDataBufferSize else {
                return false
            }
            // Prevent Reading offset is not over datasize
            guard (readingDataOffset + bytesToRead) < outputDataOffset else {
                switch dataUseCase {
                case .streaming, .streamingWithHighQuality:
                    return false
                case .player:
                    let second: Double = (Double(readingDataOffset) / bytesPerMs) / 1000
                    endOfFilePlayingCallback?(second)
                    return false
                }
            }
        }
        return true
    }
    
    func scheduleRRAudioBuffer(buffer: RRAudioBuffer) {
        
        // The async thread need captured the data before write into the outputData
        DispatchQueue.global().sync { [weak self ,buffer] in
            guard let self = self else { return }
            
            let inputDataPtr = buffer.audioData.mutableBytes
            let inputDataLength = buffer.audioData.length
            let metaData = buffer.metadata
            
            if self.isReadAndWriteInSameCycling {
                self.outputData?.replaceBytes(in: NSRange(location: self.outputDataOffset, length: inputDataLength), withBytes: inputDataPtr)
                self.outputDataOffset += inputDataLength
                
                audioBufferMetadatas.append((self.outputDataOffset, metaData))
            } else {
                self.outputData?.replaceBytes(in: NSRange(location: self.tmpOutputDataOffset, length: inputDataLength), withBytes: inputDataPtr)
                self.tmpOutputDataOffset += inputDataLength
                
                tmpAudioBufferMetadatas.append((self.tmpOutputDataOffset, metaData))
            }
            
            self.isBlankData =  false
        }
        
        // Prevent the recording data is over the memory size
        if self.isReadAndWriteInSameCycling {
            if (outputDataOffset + outputDataBufferSize) > (outputDataSize) {
                // Reset recording start at front position
                writeDataAtFront()
            }
        }
    }
    
    func getReadingDataPtr(with bytesToRead: Int) -> UnsafeMutableRawPointer? {
        guard isReadyForReading(with: bytesToRead) else { return nil}
        
        guard let readingData = outputData else { return nil}
        
        // Adjust the reading position is not over the data size, the status are include the data is losing too much when transport the data and read at the end of the data memory
        if (readingDataOffset + bytesToRead) > outputDataSize {
            // Make the position at front
            readDataAtFront()
        }
        // ReadingPtr
        let readingPtr = readingData.mutableBytes + readingDataOffset
        // Get Reading MetaData by ReadingDataOffset
        var metadata: RRAudioBufferMetadata? = nil
        
        if let element = audioBufferMetadatas[safe: metadatasReadingIndex] {
            let offset = element.0
            if readingDataOffset >= offset {
                metadatasReadingIndex += 1
            }
            metadata = element.1
        } else {
            print("Reading audioBufferMetadatas out of range, skip updating metadatas")
        }
        
        readingDataOffset += bytesToRead
        
        let readingDuration: Double = (Double(readingDataOffset) / bytesPerMs) / 1000
        if (readingDuration - lastUpdatedDuration) > durationInterval {
            lastUpdatedDuration += durationInterval
            currentDurationCallback?(lastUpdatedDuration)
        }
        
        if (readingDuration - lastUpdatedMetadata) > metadataInterval , let metadata = metadata {
            lastUpdatedMetadata += metadataInterval
            currentMetadataCallback?(metadata)
        }
        
        return readingPtr
    }
    
    private func writeDataAtFront() {
        
        guard let outputData = outputData else { return }
        // Shift the remaining data at front, but adjust in the static data buffer size
        let bufferDataPtr = outputData.mutableBytes + (outputDataOffset - outputDataBufferSize)
        let bufferDataSize = outputDataBufferSize
        // Shift the last buffer data at front
        outputData.replaceBytes(in: NSRange(location: 0, length: bufferDataSize), withBytes: bufferDataPtr)
        // Reset the tmp data size
        tmpOutputDataOffset += outputDataBufferSize
        resetCount += 1
        
        isReadAndWriteInSameCycling = false
        
        print("=====RESET(\(resetCount)) OUTPUT DATA || The rest data size is \(bufferDataSize) bytes======")
    }
    
    private func readDataAtFront() {
        isReadAndWriteInSameCycling = true
        outputDataOffset = tmpOutputDataOffset
        audioBufferMetadatas = tmpAudioBufferMetadatas
        tmpOutputDataOffset = 0
        metadatasReadingIndex = 0
        lastUpdatedDuration = 0
        lastUpdatedMetadata = 0
        tmpAudioBufferMetadatas.removeAll()
        readingDataOffset = 0
        print("Read Data In Next Cycle")
    }
    
    private func resetAllParameters() {
        isReadAndWriteInSameCycling = true
        outputDataOffset = 0
        tmpOutputDataOffset = 0
        audioBufferMetadatas.removeAll()
        tmpAudioBufferMetadatas.removeAll()
        tmpOutputDataOffset = 0
        metadatasReadingIndex = 0
        lastUpdatedDuration = 0
        lastUpdatedMetadata = 0
        tmpAudioBufferMetadatas.removeAll()
        readingDataOffset = 0
        resetCount = 0
        
        generateEmptyData()
    }
}
