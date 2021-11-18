//
//  InOutUDPSocket.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/9.
//

import Foundation
import CocoaAsyncSocket

class InOutSocket: NSObject, GCDAsyncUdpSocketDelegate {
   //let IP = "10.123.45.2"
    var IP = ""
    var PORT:UInt16 = 0
    var socket:GCDAsyncUdpSocket!
    
    var receiveCallback: ((Data)->Void)?
    
    var dataCollection: [Data] = []
    private var isStartSendData: Bool = false
    
    override init(){
        super.init()
    }
    convenience init(ip: String, port: UInt16) {
        self.init()
        IP = ip
        PORT = port
    }
    
    deinit {
        socket.close()
        socket = nil
    }
    
    func setupConnection(success:(()->())){
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue:DispatchQueue.main)
        do { try socket.bind(toPort: PORT)} catch { print("bind fail")}
        do { try socket.connect(toHost:IP, onPort: PORT)} catch { print("joinMulticastGroup not proceed")}
        do { try socket.enableBroadcast(true)} catch { print("not able to brad cast")}
        do { try socket.beginReceiving()} catch { print("beginReceiving not proceed")}
        success()
        print("maxReceiveIPv4BufferSize: \(socket.maxReceiveIPv4BufferSize()), maxSendBufferSize: \(socket.maxSendBufferSize())")
    }
    func send(data: Data){
        #warning("Need Thread safe")
        dataCollection.append(data)
        if !isStartSendData {
            socket.send(dataCollection[0], withTimeout: 0, tag: 0)
        }
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
        dataCollection.remove(at: 0)
        
        if dataCollection.count > 1 {
            socket.send(dataCollection[0], withTimeout: 0, tag: 0)
        } else if dataCollection.count == 0 {
            isStartSendData = false
        }
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
//        print("didNotSendDataWithTag")
    }
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Error:\(error)")
    }
    
    func setupDidReceiveDataCallback(_ receiveCallback:@escaping (Data)->Void) {
        self.receiveCallback = receiveCallback
    }
}
