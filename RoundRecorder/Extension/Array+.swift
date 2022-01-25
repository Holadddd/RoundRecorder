//
//  Array+.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/12/9.
//

import Foundation

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}

extension Array where Element == UInt8 {
    func readLittleEndian<T: FixedWidthInteger>(offset: Int, as: T.Type) -> T {
        assert(offset + MemoryLayout<T>.size <= self.count)
        //Prepare a region aligned for `T`
        var value: T = 0
        //Copy the misaligned bytes at `offset` to aligned region `value`
        _ = Swift.withUnsafeMutableBytes(of: &value) {valueBP in
            self.withUnsafeBytes {bufPtr in
                let range = offset..<offset+MemoryLayout<T>.size
                bufPtr.copyBytes(to: valueBP, from: range)
            }
        }
        return T(littleEndian: value)
    }
    
    func readFloatingPoint<T: FloatingPoint>(offset: Int, as: T.Type) -> T {
        var bytes: [UInt8] = []
        for index in offset..<(offset+8) {
            bytes.append(self[index])
        }
        
        return T(bytes: bytes)!
    }
    
}
