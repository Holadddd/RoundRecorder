//
//  UDPSocketOut.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/9.
//

import Foundation
import CocoaAsyncSocket

class UDPSocketOut: NSObject, GCDAsyncUdpSocketDelegate {
    
    var IP = ""
    var PORT:UInt16 = 0
    var socket:GCDAsyncUdpSocket!
    
    var isSocketReady: Bool = false
    
    var userID: String?
    
    var broadcastOnChannel: String?
    
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
    func setupConnection(success:((mtu)->Void)) {
        if socket == nil {
            socket = GCDAsyncUdpSocket(delegate: self, delegateQueue:DispatchQueue.main)
        } else {
            socket.close()
        }
        
        do { try socket.connect(toHost:IP, onPort: PORT)} catch { print("joinMulticastGroup not proceed")}
        do { try socket.enableBroadcast(true)} catch { print("not able to broad cast")}
        
        isSocketReady = true
        
        success(Int(socket.maxSendBufferSize()))
    }
    
    func broadcastChannel(userID: String, channelID: String, payload: Data) {
        guard isSocketReady,
        let data = UDPSocketOut.encodeUDPSocketPayload(payload, userID: userID, channelID: channelID) else { return }
        
        socket.send(data, withTimeout: 0, tag: 0)
    }
    
    func cancelBroadcastChannel() {
        socket.close()
        
        isSocketReady = false
    }
    
    //MARK:-GCDAsyncUdpSocketDelegate
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("UDPSocketOut didConnect")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("UDPSocketOut didNotConnect")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {

    }
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Error:\(String(describing: error))")
        isSocketReady = false
        print("Prepare To Restart Connection")
        // RestartConnection
        setupConnection { _ in
            print("Restart UDPSocketOut Connection")
        }
    }
}

extension UDPSocketOut {
    static func encodeUDPSocketPayload(_ dataPtr: UnsafeMutableRawPointer, _ dataLength: Int, userID: String, channelID: String) -> Data? {
        /*
         UDPSocketOutSendPayload
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              userID      String          16
         16             channelID   String          16
         32             date        UInt64          8               MillisecondsSince1970
         40             data        UInt32
         --------------------------------------------------------------------
         */
        let date = Date().millisecondsSince1970
        
        var data = withUnsafeBytes(of: userID) { Data($0) }   // Offset: 0
        data.append(withUnsafeBytes(of: channelID) { Data($0) })   // Offset: 16
        data.append(withUnsafeBytes(of: date) { Data($0) }) // Offset: 32
        
        if UDPSocketManager.enableCompresssionAlgorithm {
            guard let compressData = Data(bytes: dataPtr, count: dataLength).compressed(using: UDPSocketManager.compressionAlgorithm) else {
                print("CompressFail")
                return data
            }
            data.append(compressData)    // Offset: 40
            
            return data
        } else {
            data.append(Data(bytes: dataPtr, count: dataLength))    // Offset: 40
            
            return data
        }
    }
    
    static func encodeUDPSocketPayload(_ data: Data, userID: String, channelID: String) -> Data? {
        /*
         UDPSocketSendPayload
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              userID      String          16
         16             channelID   String          16
         32             date        UInt64          8               MillisecondsSince1970
         40             data        UInt32
         --------------------------------------------------------------------
         */
        let date = Date().millisecondsSince1970
        
        var newData = withUnsafeBytes(of: userID) { Data($0) }   // Offset: 0
        newData.append(withUnsafeBytes(of: channelID) { Data($0) })   // Offset: 16
        newData.append(withUnsafeBytes(of: date) { Data($0) }) // Offset: 32
        
        if UDPSocketManager.enableCompresssionAlgorithm {
            guard let compressData = data.compressed(using: UDPSocketManager.compressionAlgorithm) else {
                print("CompressFail")
                return data
            }
            newData.append(compressData)    // Offset: 40
            
            return newData
        } else {
            newData.append(data)    // Offset: 40
            
            return newData
        }
    }
}
enum UDPSocketOutError: Error {
    
}
