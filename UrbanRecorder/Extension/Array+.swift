//
//  Array+.swift
//  UrbanRecorder
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
