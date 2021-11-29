//
//  UDPSocketIn.swift
//  UrbanRecorder
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
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue:DispatchQueue.main)
        socket.setMaxReceiveIPv4BufferSize(UInt16.max)
        do { try socket.connect(toHost:IP, onPort: PORT)} catch { print("joinMulticastGroup not proceed")}
        do { try socket.enableBroadcast(true)} catch { print("not able to broad cast")}
        do { try socket.beginReceiving()} catch { print("beginReceiving not proceed")}
        isSocketReady = true
        
        print("MaxReceiveIPv4BufferSize: \(socket.maxReceiveIPv4BufferSize())")
        success(Int(socket.maxSendBufferSize()))
    }
    func subscibeChannel(with data: Data) {
        guard isSocketReady else { return }
        socket.send(data, withTimeout: 2, tag: 0)
    }
    //MARK:-GCDAsyncUdpSocketDelegate
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("didConnect")
        
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        receiveCallback?(data)
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("didNotConnect")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("Subscribe Data did send")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("Subscribe Data did not send")
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

