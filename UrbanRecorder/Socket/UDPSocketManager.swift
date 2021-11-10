//
//  UDPSocketManager.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/2.
//

import Foundation
import AVFoundation
import CocoaAsyncSocket
import Network

protocol UDPSocketManagerDelegate: AnyObject {
    func didReceiveAudioBuffersData(_ manager: UDPSocketManager, data: Data,from sendID: String)
}

class UDPSocketManager: NSObject, GCDAsyncUdpSocketDelegate {
    
    static let hostIP: String = Bundle.main.object(forInfoDictionaryKey: "UDPSocketHostIP") as? String ?? ""
    
    static let port: String = Bundle.main.object(forInfoDictionaryKey: "UDPSocketPort") as? String ?? ""
    
    static let shared: UDPSocketManager = UDPSocketManager()
    
    static let compressionAlgorithm: NSData.CompressionAlgorithm = .lz4
    /*
     AWS can accept maximum package size(64K 65536 bytes), Mac default max buffer size is 9216
     Use this command to modify the os system maximun UPD buffer size as 65535 bytes
     $ sysctl -w net.inet.udp.maxdgram=65535
     */
    let mtu = 65535
    
    var udpSocketInOut: InOutSocket?
    
    var status: UDPSocketStstus = .disConneected
    
    weak var delegate: UDPSocketManagerDelegate?
    
    private var receiveCallback: ((Data)->Void)?
    
    override init() {
        super.init()
    }
    
    func setupConnection(_ complete: @escaping()->Void) {
        // UDPSocket
        let ip = UDPSocketManager.hostIP
        guard let port = UInt16(UDPSocketManager.port) else { fatalError() }
        udpSocketInOut = InOutSocket(ip: ip, port: port)
        udpSocketInOut?.setupConnection {
            setupUDPReceive()
            status = .connected
            complete()
        }
    }
    
    func sendBufferData(_ audioBufferData: NSMutableData, from userID: String = "", to recieverID: String = "") {
        guard status == .connected else { return }
        
        var bufferDataByte = audioBufferData.mutableBytes
        var bufferSize = audioBufferData.length
        
        #warning("AWS UDP Socket didnt have max limit of bytes, still need to check of the limit")
        let defaultMaximumBufferSize = mtu - 40
        
        while true {
            if bufferSize > defaultMaximumBufferSize {
                
                let audioData = Data(bytes: bufferDataByte, count: defaultMaximumBufferSize)
                
                guard let sendingPayload = UDPSocketManager.encodeUDPSocketPayload(audioData, userID: userID, recieverID: recieverID) else { break }
                
                sendData(sendingPayload)
                
                bufferDataByte += defaultMaximumBufferSize
                bufferSize -= defaultMaximumBufferSize
            } else {
                
                let audioData = Data(bytes: bufferDataByte, count: bufferSize)
                
                guard let sendingPayload = UDPSocketManager.encodeUDPSocketPayload(audioData, userID: userID, recieverID: recieverID) else { break }
                
                sendData(sendingPayload)
                
                break
            }
        }
    }
    
    private func setupUDPReceive() {
        udpSocketInOut?.setupDidReceiveDataCallback({ [weak self]  incomingData in
            
            guard let self = self else { return }
            
            guard let payload = UDPSocketManager.parseUDPSocketData(incomingData) else { return }
            
            let data = payload.data
            let emitID = payload.emitID
            
            self.delegate?.didReceiveAudioBuffersData(self, data: data, from: emitID)
            // Notification
            let date = payload.date
            let latencyMs = Date().millisecondsSince1970 - date
            DispatchQueue.main.async {[latencyMs] in
                NotificationCenter.default.post(UDPSocketLatency: latencyMs)
            }
        })
    }
    
    private func sendData(_ data: Data) {
        udpSocketInOut?.send(data: data)
    }
    
    static func encodeUDPSocketPayload(_ dataPtr: UnsafeMutableRawPointer, _ dataLength: Int, userID: String, recieverID: String) -> Data? {
        /*
         UDPSocketSendPayload
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              recieveID   String          16
         16             emitID      String          16
         32             date        UInt64          8               MillisecondsSince1970
         40             data        UInt32
         --------------------------------------------------------------------
         */
        let date = Date().millisecondsSince1970
        
        var data = withUnsafeBytes(of: recieverID) { Data($0) }   // Offset: 0
        data.append(withUnsafeBytes(of: userID) { Data($0) })   // Offset: 16
        data.append(withUnsafeBytes(of: date) { Data($0) }) // Offset: 32
        data.append(Data(bytes: dataPtr, count: dataLength))    // Offset: 40
        
        return data
    }
    
    static func encodeUDPSocketPayload(_ data: Data, userID: String, recieverID: String) -> Data? {
        /*
         UDPSocketSendPayload
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              recieveID   String          16
         16             emitID      String          16
         32             date        UInt64          8               MillisecondsSince1970
         40             data        UInt32
         --------------------------------------------------------------------
         */
        let date = Date().millisecondsSince1970
        
        var newData = withUnsafeBytes(of: recieverID) { Data($0) }   // Offset: 0
        newData.append(withUnsafeBytes(of: userID) { Data($0) })   // Offset: 16
        newData.append(withUnsafeBytes(of: date) { Data($0) }) // Offset: 32
        newData.append(data)    // Offset: 40
        
        return newData
    }
    
    static func parseUDPSocketData(_ data: Data) -> UDPSocketRecievedPayload? {
        /*
         UDPSocketReceivePayload
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              emitID      String          16
         16             date        UInt64          8               MillisecondsSince1970
         24             data        UInt32
         --------------------------------------------------------------------
         */
                
        let emitID: String = NSMutableData(data: data.advanced(by: 0)).bytes.load(as: String.self)
        let date: UInt64 = NSMutableData(data: data.advanced(by: 16)).bytes.load(as: UInt64.self)
        let payload: Data = data.advanced(by: 24)
        
        let recievedPayload = UDPSocketRecievedPayload(emitID: emitID, date: date, data: payload)
        
        return recievedPayload
    }
}

struct UDPSocketRecievedPayload {
    let emitID: String
    let date: UInt64
    let data: Data
}

enum UDPSocketStstus {
    case connected
    case disConneected
}
