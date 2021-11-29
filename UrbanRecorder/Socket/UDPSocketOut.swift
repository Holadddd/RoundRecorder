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
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue:DispatchQueue.main)
        
        do { try socket.connect(toHost:IP, onPort: PORT)} catch { print("joinMulticastGroup not proceed")}
        do { try socket.enableBroadcast(true)} catch { print("not able to broad cast")}
        isSocketReady = true
        
        print("MaxSendBufferSize: \(socket.maxSendBufferSize())")
        success(Int(socket.maxSendBufferSize()))
    }
    
    func send(data: Data) {
        guard isSocketReady else { return }
        socket.send(data, withTimeout: 0, tag: 0)
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

enum UDPSocketOutError: Error {
    
}
