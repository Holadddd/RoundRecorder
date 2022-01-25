//
//  FloatingPoint+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/11.
//

import Foundation

extension Double {
    func ceiling(toDecimal decimal: Int) -> Double {
        let numberOfDigits = abs(pow(10.0, Double(decimal)))
        if self.sign == .minus {
            return Double(Int(self * numberOfDigits)) / numberOfDigits
        } else {
            return Double(ceil(self * numberOfDigits)) / numberOfDigits
        }
    }
    
    func string(fractionDigits:Int) -> String {
        let string = String(format: "%.\(fractionDigits)f", self)
        return string
    }
    
    func toDisplayDistance() -> String {
        if self < 100 {
            return self.string(fractionDigits: 2) + " m"
        } else if self < 1000 {
            return self.string(fractionDigits: 0) + " m"
        } else {
            return (self / 1000).string(fractionDigits: 2) + " km"
        }
    }
}

extension FloatingPoint {

    init?(bytes: [UInt8]) {

        guard bytes.count == MemoryLayout<Self>.size else { return nil }

        self = bytes.withUnsafeBytes {

            return $0.load(fromByteOffset: 0, as: Self.self)
        }
    }
}
