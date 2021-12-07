//
//  URAudioOutputData.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/3.
//

import Foundation
import AVFoundation

class URAudioOutputData: NSObject {
    // Data from UDP socket
    private var outputData: NSMutableData?
    // Allocate size for data memory
    private var outputDataSize: Int
    // Buffer size for real time connection unlinear trasfer
    private var outputDataBufferSize: Int
    // Count for real data size
    private var outputDataOffset: Int = 0
    // Count for real data size in different cycle
    private var tmpOutputDataOffset: Int = 0
    //
    private var readingDataOffset: Int = 0
    // Trun false while the data is out of the same cycle and write at the front
    private var isReadAndWriteInSameCycling: Bool = true
    // Debug Helper
    private var resetCount: Int = 0
    // Start Writing Data
    private var isBlankData: Bool = true
    
    init(dataSize: Int, bufferBytesSize: Int) {
        
        outputDataSize = dataSize
        
        outputDataBufferSize = bufferBytesSize
        
        outputData = NSMutableData(length: dataSize)
        //Input empty bufferData
        let emptyBufferData = NSMutableData(length: outputDataBufferSize)
        
        outputData?.replaceBytes(in: NSRange(location: 0, length: emptyBufferData!.length), withBytes: emptyBufferData!.mutableBytes)
        
        readingDataOffset = 0
        
        print("Init Audio Output Data||Size:\(dataSize) buffer:\(bufferBytesSize)")
    }
    
    convenience init(format: AVAudioFormat, dataMS: Int, bufferMS: Int) {
        let bits = format.bitRate
        
        let samplesPerMs = format.sampleRate / 1000
        
        let dataBytesSize = Double(dataMS) * samplesPerMs * Double(bits)
        let bufferBytesSize = Double(bufferMS) * samplesPerMs * Double(bits)
        
        self.init(dataSize: Int(dataBytesSize), bufferBytesSize: Int(bufferBytesSize))
    }
    
    func isReadyForReading(with bytesToRead: Int) -> Bool {
        guard !isBlankData else { return false }
        // Make sure there is the data comming in
        if isReadAndWriteInSameCycling {
            guard  outputDataOffset > outputDataBufferSize else {
                return false
            }
            
            guard (readingDataOffset + bytesToRead) < outputDataOffset else {
                return false
            }
        }
        return true
    }
    
    func scheduleOutput(data: NSMutableData) {
        
        // The async thread need captured the data before write into the outputData
        DispatchQueue.global().sync { [weak self ,data] in
            guard let self = self else { return }
            
            let inputDataPtr = data.mutableBytes
            let inputDataLength = data.length
            
            if self.isReadAndWriteInSameCycling {
                self.outputData?.replaceBytes(in: NSRange(location: self.outputDataOffset, length: inputDataLength), withBytes: inputDataPtr)
                self.outputDataOffset += inputDataLength
            } else {
                self.outputData?.replaceBytes(in: NSRange(location: self.tmpOutputDataOffset, length: inputDataLength), withBytes: inputDataPtr)
                self.tmpOutputDataOffset += inputDataLength
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
    
    func getReadingData(with bytesToRead: Int) -> UnsafeMutableRawPointer? {
        guard isReadyForReading(with: bytesToRead) else { return nil}
        
        guard let readingData = outputData else { return nil }
        
        // Adjust the reading position is not over the data size, the status are include the data is losing too much when transport the data and read at the end of the data memory
        if (readingDataOffset + bytesToRead) > outputDataSize {
            // Make the position at front
            readDataAtFront()
        }
        
        let readingPtr = readingData.mutableBytes + readingDataOffset
        
        readingDataOffset += bytesToRead
        
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
        tmpOutputDataOffset = 0
        readingDataOffset = 0
        print("Read Data In Next Cycle")
    }
}
