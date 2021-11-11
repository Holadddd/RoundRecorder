//
//  Double+.swift
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
}
