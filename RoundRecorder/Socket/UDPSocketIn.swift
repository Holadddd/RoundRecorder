//
//  UDPSocketIn.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/25.
//

import Foundation
import CocoaAsyncSocket

class UDPSocketIn: NSObject, GCDAsyncUdpSocketDelegate {
    
    var IP = ""
    var PORT:UInt16 = 0
    var socket:GCDAsyncUdpSocket!
    
    var receiveCallback: ((Data)->Void)?
    
    var isSocketReady: Bool = false
    
    var userID: String?
    
    var subscribeOnChannel: String?
    
    override init(){
        super.init()
    }
    convenience init(ip: String, port: UInt16) {
        self.init()
        IP = ip
        PORT = port
    }
    
    deinit {
        guard socket != nil else { return }
        socket.close()
        socket = nil
    }
    typealias mtu = Int
    func setupConnection(success:((mtu)->Void)){
        if socket == nil {
            socket = GCDAsyncUdpSocket(delegate: self, delegateQueue:DispatchQueue.main)
        } else {
            socket.close()
        }
        
        socket.setMaxReceiveIPv4BufferSize(UInt16.max)
        do { try socket.connect(toHost:IP, onPort: PORT)} catch { print("joinMulticastGroup not proceed")}
        do { try socket.enableBroadcast(true)} catch { print("not able to broad cast")}
        do { try socket.beginReceiving()} catch { print("beginReceiving not proceed")}
        isSocketReady = true
        
        success(Int(socket.maxSendBufferSize()))
    }
    
    func subscibeChannel(from userID: String, with channelID: String) {
        guard isSocketReady,
        let data = UDPSocketIn.encodeUDPSocketSubscribeInfo(userID, subscribeChannelID: channelID)else { return }
        
        if let currentSubscrobeChannel = subscribeOnChannel {
            // Unsubscribe Channel
            unsubscibeChannel(from: userID, with: currentSubscrobeChannel)
        }
        
        subscribeOnChannel = channelID
        
        socket.send(data, withTimeout: 2, tag: 1)
    }
    
    func unsubscibeChannel(from userID: String, with channelID: String) {
        guard isSocketReady,
        let data = UDPSocketIn.encodeUDPSocketUnsubscribeInfo(userID, subscribeChannelID: channelID)else { return }
        
        subscribeOnChannel = nil
        
        socket.send(data, withTimeout: 2, tag: 0)
    }
    
    //MARK:-GCDAsyncUdpSocketDelegate
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("UDPSocketIn didConnect")
        
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        receiveCallback?(data)
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("UDPSocketIn didNotConnect")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        switch tag  {
        case 0:
            print("Unsubscribe Data did send")
        case 1:
            print("Subscribe Data did send")
        default:
            print("Unknow Data did send")
        }
        
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        switch tag  {
        case 0:
            print("Unsubscribe Data did not send")
        case 1:
            print("Subscribe Data did not send")
        default:
            print("Unknow Data did not send")
        }
    }
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Error:\(String(describing: error))")
        isSocketReady = false
        print("Prepare To Restart Connection")
        // RestartConnection
        setupConnection { _ in
            print("Restart Connection")
        }
    }
    
    func setupDidReceiveDataCallback(_ receiveCallback:@escaping (Data)->Void) {
        self.receiveCallback = receiveCallback
    }
}

extension UDPSocketIn {
    static func encodeUDPSocketSubscribeInfo(_ userID: String, subscribeChannelID: String) -> Data? {
        /*
         UDPSocketInSendSubscriptionInfo
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              userID      String          16
         16             channelID   String          16
         32             isSubscribe Uint8          1               // 0: Unsubscribe 1: Subscribe
         --------------------------------------------------------------------
         */
        
        var newData = withUnsafeBytes(of: userID) { Data($0) }   // Offset: 0
        newData.append(withUnsafeBytes(of: subscribeChannelID) { Data($0) })   // Offset: 16
        newData.append(withUnsafeBytes(of: UInt8(1)) { Data($0) }) // Offset: 32
        
        return newData
    }
    
    static func encodeUDPSocketUnsubscribeInfo(_ userID: String, subscribeChannelID: String) -> Data? {
        /*
         UDPSocketInSendSubscriptionInfo
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              userID      String          16
         16             channelID   String          16
         32             isSubscribe Uint8          1               // 0: Unsubscribe 1: Subscribe
         --------------------------------------------------------------------
         */
        
        var newData = withUnsafeBytes(of: userID) { Data($0) }   // Offset: 0
        newData.append(withUnsafeBytes(of: subscribeChannelID) { Data($0) })   // Offset: 16
        newData.append(withUnsafeBytes(of: UInt8(0)) { Data($0) }) // Offset: 32
        
        return newData
    }
}
