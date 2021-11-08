//
//  EngineHelper.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/3.
//

import Foundation
import AVFoundation

extension AVAudioFormat {
    var bitRate: Int {
        switch commonFormat {
        case .pcmFormatInt16:
            return 16
        case .pcmFormatInt32:
            return 32
        default:
            return 32
        }
    }
}

extension AVAudioSession.Port {
    
    var rankValue: Int {
        switch self {
        case .bluetoothA2DP:
            return 0
        case .bluetoothHFP:
            return 1
        default:
            return 2
        }
    }
}
//
//extension Date {
// var millisecondsSince1970:Int64 {
//        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
//        //RESOLVED CRASH HERE
//    }
//
//    init(milliseconds:Int) {
//        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
//    }
//}

//GLboolean, Boolean
extension UInt8: ExpressibleByBooleanLiteral {
    public var boolValue: Bool {
        return self != 0
    }
    public init(booleanLiteral value: BooleanLiteralType) {
        self = value ? UInt8(1) : UInt8(0)
    }
}
//GLint
extension Int32: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = value ? Int32(1) : Int32(0)
    }
}
//cl_bool
extension UInt32: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = value ? UInt32(1) : UInt32(0)
    }
}

//long, size_t
extension Int {
    public var g: CGFloat {
        return CGFloat(self)
    }
    public var d: Double {
        return Double(self)
    }
    public var f: Float {
        return Float(self)
    }
    public var b: Int8 {
        return Int8(self)
    }
    public var ub: UInt8 {
        return UInt8(self)
    }
    public var s: Int16 {
        return Int16(self)
    }
    public var us: UInt16 {
        return UInt16(self)
    }
    public var i: Int32 {
        return Int32(self)
    }
    public var ui: UInt32 {
        return UInt32(self)
    }
    //    public var l: Int {
    //        return Int(self)
    //    }
    public var ul: UInt {
        return UInt(self)
    }
    public var ll: Int64 {
        return Int64(self)
    }
    public var ull: UInt64 {
        return UInt64(self)
    }
}

//unsigned long
extension UInt {
    public var g: CGFloat {
        return CGFloat(self)
    }
    public var d: Double {
        return Double(self)
    }
    public var f: Float {
        return Float(self)
    }
    public var b: Int8 {
        return Int8(self)
    }
    public var ub: UInt8 {
        return UInt8(self)
    }
    public var s: Int16 {
        return Int16(self)
    }
    public var us: UInt16 {
        return UInt16(self)
    }
    public var i: Int32 {
        return Int32(self)
    }
    public var ui: UInt32 {
        return UInt32(self)
    }
    public var l: Int {
        return Int(self)
    }
    //    public var ul: UInt {
    //        return UInt(self)
    //    }
    public var ll: Int64 {
        return Int64(self)
    }
    public var ull: UInt64 {
        return UInt64(self)
    }
}

//GLint, cl_int
extension Int32 {
    public var g: CGFloat {
        return CGFloat(self)
    }
    public var d: Double {
        return Double(self)
    }
    public var f: Float {
        return Float(self)
    }
    public var b: Int8 {
        return Int8(self)
    }
    public var ub: UInt8 {
        return UInt8(self)
    }
    public var s: Int16 {
        return Int16(self)
    }
    public var us: UInt16 {
        return UInt16(self)
    }
    //    public var i: Int32 {
    //        return Int32(self)
    //    }
    public var ui: UInt32 {
        return UInt32(self)
    }
    public var l: Int {
        return Int(self)
    }
    public var ul: UInt {
        return UInt(self)
    }
    public var ll: Int64 {
        return Int64(self)
    }
    public var ull: UInt64 {
        return UInt64(self)
    }
}

//GLuint, GLenum, GLsizei
extension UInt32 {
    public var g: CGFloat {
        return CGFloat(self)
    }
    public var d: Double {
        return Double(self)
    }
    public var f: Float {
        return Float(self)
    }
    public var b: Int8 {
        return Int8(self)
    }
    public var ub: UInt8 {
        return UInt8(self)
    }
    public var s: Int16 {
        return Int16(self)
    }
    public var us: UInt16 {
        return UInt16(self)
    }
    public var i: Int32 {
        return Int32(self)
    }
    //    public var ui: UInt32 {
    //        return UInt32(self)
    //    }
    public var l: Int {
        return Int(self)
    }
    public var ul: UInt {
        return UInt(self)
    }
    public var ll: Int64 {
        return Int64(self)
    }
    public var ull: UInt64 {
        return UInt64(self)
    }
}

//Darwin clock_types.h
extension UInt64 {
    public var g: CGFloat {
        return CGFloat(self)
    }
    public var d: Double {
        return Double(self)
    }
    public var f: Float {
        return Float(self)
    }
    public var b: Int8 {
        return Int8(self)
    }
    public var ub: UInt8 {
        return UInt8(self)
    }
    public var s: Int16 {
        return Int16(self)
    }
    public var us: UInt16 {
        return UInt16(self)
    }
    public var i: Int32 {
        return Int32(self)
    }
    public var ui: UInt32 {
        return UInt32(self)
    }
    public var l: Int {
        return Int(self)
    }
    public var ul: UInt {
        return UInt(self)
    }
    public var ll: Int64 {
        return Int64(self)
    }
    //    public var ull: UInt64 {
    //        return UInt64(self)
    //    }
}

//GLfloat, cl_float
extension Float {
    public var g: CGFloat {
        return CGFloat(self)
    }
    public var d: Double {
        return Double(self)
    }
}

extension Double {
    public var g: CGFloat {
        return CGFloat(self)
    }
    public var f: Float {
        return Float(self)
    }
}

extension CGFloat {
    public var d: Double {
        return Double(self)
    }
    public var f: Float {
        return Float(self)
    }
}

//Int8
extension CChar: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: UnicodeScalar) {
        self = CChar(value.value)
    }
}

//UInt16
extension unichar: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: UnicodeScalar) {
        self = unichar(value.value)
    }
}
