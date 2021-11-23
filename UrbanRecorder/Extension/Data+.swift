//
//  Data+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/2.
//

import Foundation

extension Data {
    public func compressed(using compressionAlgorithm: NSData.CompressionAlgorithm) -> Data? {
        // Compress Data
        do {
            let compressedNSData = try (self as NSData).compressed(using: compressionAlgorithm)
                // use your compressed data
            let compressedData = compressedNSData as Data
            
            return compressedData
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func decompressed(using compressionAlgorithm: NSData.CompressionAlgorithm) -> Data? {
        var decompressData: Data?
        
        do {
            decompressData = try (self as NSData).decompressed(using: compressionAlgorithm) as Data
            
            return decompressData
        } catch {
            return nil
        }
    }
}
