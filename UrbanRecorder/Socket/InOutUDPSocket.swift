//
//  InOutUDPSocket.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/9.
//

import Foundation
import CocoaAsyncSocket

class InOutSocket: NSObject, GCDAsyncUdpSocketDelegate {
    
    var IP = ""
    var PORT:UInt16 = 0
    var socket:GCDAsyncUdpSocket!
    
    var mtu: Int = 0
    
    var currentSendingDataSize: Int = 0
    
    var standardDataSize: Int = 0
    
    var receiveCallback: ((Data)->Void)?
    
    private var isSocketReady: Bool = false
    
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
    
    func setupConnection(success:(()->())){
        currentSendingDataSize = 0
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue:DispatchQueue.main)
        socket.setMaxSendBufferSize(UInt16.max)
        do { try socket.bind(toPort: PORT)} catch { print("bind fail")}
        do { try socket.connect(toHost:IP, onPort: PORT)} catch { print("joinMulticastGroup not proceed")}
        do { try socket.enableBroadcast(true)} catch { print("not able to broad cast")}
        do { try socket.beginReceiving()} catch { print("beginReceiving not proceed")}
        success()
        isSocketReady = true
        mtu = Int(socket.maxSendBufferSize())
        print("maxReceiveIPv4BufferSize: \(socket.maxReceiveIPv4BufferSize()), maxSendBufferSize: \(socket.maxSendBufferSize())")
    }
    func send(data: Data){
        guard isSocketReady else { return }
        socket.send(data, withTimeout: 0, tag: 0)
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
        
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {

    }
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Error:\(String(describing: error))")
        isSocketReady = false
        print("Prepare To Restart Connection")
        // RestartConnection
        setupConnection {
            print("Restart Connection")
        }
    }
    
    func setupDidReceiveDataCallback(_ receiveCallback:@escaping (Data)->Void) {
        self.receiveCallback = receiveCallback
    }
}
