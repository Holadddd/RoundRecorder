//
//  String+.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/26.
//

import Foundation

extension String {
    
    init (bytes: [UInt8] , encoding: String.Encoding, offset: Int, length: Int) {
        var charCollection = ""
        
        for i in offset..<(offset + length) {
            let v = bytes[i]
            
            guard v != 0, let char = String(bytes: [v], encoding: encoding) else { continue }
            charCollection += char
        }
        self = charCollection
    }
}
