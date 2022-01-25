//
//  Helper.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/10/22.
//

import Foundation
import SwiftUI

struct DeviceInfo {
    static var isCurrentDeviceIsPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
    
    func onChange(_ handler: @escaping () -> Void) ->Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler()
        })
    }
}

struct EnumMap<Enum: CaseIterable & Hashable, Value> {
    private let values: [Enum : Value]

    init(resolver: (Enum) -> Value) {
        var values = [Enum : Value]()

        for key in Enum.allCases {
            values[key] = resolver(key)
        }

        self.values = values
    }

    subscript(key: Enum) -> Value {
        // Here we have to force-unwrap, since there's no way
        // of telling the compiler that a value will always exist
        // for any given key. However, since it's kept private
        // it should be fine - and we can always add tests to
        // make sure things stay safe.
        return values[key]!
    }
}

struct ChannelIDChecker {
    
    func isChannelValidation(_ channelID: String) -> Bool {
        guard channelID != "" else { return false}
        for c in channelID {
            guard !c.isWhitespace && !c.isSymbol else { return false }
        }
        return true
    }
}

extension UIApplication{
    func endEditing(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
