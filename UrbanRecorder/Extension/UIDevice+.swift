//
//  UIDevice+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/20.
//

import Foundation
import SwiftUI
import AudioToolbox

extension UIDevice {
    static func vibrate() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
    }
}
