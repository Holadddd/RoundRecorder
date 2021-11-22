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
    
    var mtu: Int = 0
    
    var currentSendingDataSize: Int = 0
    
    var standardDataSize: Int = 0
    
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
        do { try socket.enableBroadcast(true)} catch { print("not able to broad cast")}
        do { try socket.beginReceiving()} catch { print("beginReceiving not proceed")}
        success()
        mtu = Int(socket.maxSendBufferSize())
        print("maxReceiveIPv4BufferSize: \(socket.maxReceiveIPv4BufferSize()), maxSendBufferSize: \(socket.maxSendBufferSize())")
    }
    func send(data: Data){
        let expectSize = currentSendingDataSize + data.count
        
        standardDataSize = data.count
        
        if expectSize > mtu {
            print("Prevent Over Buffer Size")
            dataCollection.append(data)
        } else {
            currentSendingDataSize += data.count
            socket.send(data, withTimeout: 0, tag: 0)
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
        
        currentSendingDataSize -= standardDataSize
        
        while true {
            
            guard dataCollection.count > 0 else { break }
            
            let nextData = dataCollection[0]
            
            guard mtu - currentSendingDataSize > nextData.count else { break }
            
            currentSendingDataSize += nextData.count
            
            socket.send(nextData, withTimeout: 0, tag: 0)
            
            standardDataSize = nextData.count
            
            dataCollection.remove(at: 0)
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
