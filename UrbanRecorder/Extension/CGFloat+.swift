//
//  CGFloat+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/22.
//

import SwiftUI

extension CGFloat {
    func bounce(inRange range: ClosedRange<CGFloat>) -> CGFloat {
        let increasing = Int(self / (range.upperBound - range.lowerBound)) % 2 == 0
        let newWidth = abs(self).truncatingRemainder(dividingBy: range.upperBound - range.lowerBound)
        return increasing ? range.lowerBound + newWidth : range.upperBound - newWidth
    }
}
