//
//  Int+.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/12/8.
//

import Foundation

extension UInt {
    func toHoursMinutesSeconds() -> (UInt, UInt, UInt) {
        return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
    }
    
    func toTimeUnit() -> String {
        if self < 10 {
            return "0\(self)"
        } else {
            return "\(self)"
        }
    }
}
