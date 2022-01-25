//
//  Codable+.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/10/28.
//

import Foundation

extension Encodable {
    var JSONData: Data? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return data
    }
}
