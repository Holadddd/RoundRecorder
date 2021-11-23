//
//  Notification+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/2.
//

import Foundation

extension Notification.Name {
    static let TCPsocketConnectionDidFinish = Notification.Name("socketClinetDidConnect")
    
    static let UDPSocketConnectionLatency = Notification.Name("socketConnectionLatency") // Milliseconds
}

extension NotificationCenter {
    
    func post(UDPSocketLatency: UInt64) {
        post(name: Notification.Name.UDPSocketConnectionLatency, object: nil, userInfo: ["millisecond": UDPSocketLatency])
    }
}
