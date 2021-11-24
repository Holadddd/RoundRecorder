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
    
    static let enableCompresssionAlgorithm: Bool = false
    /*
     AWS can accept maximum package size(64K 65536 bytes), Mac default max buffer size is 9216
     Use the command for modify the os system maximun UPD buffer with size as 65535 bytes
     $ sysctl -w net.inet.udp.maxdgram=65535
     */
    var mtu = 65535
    
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
    
    func subscribeChannel(from channelID: String = "") {
        // TODO: Subscribe from UDPSocket
    }
    
    func sendBufferData(_ audioBufferData: NSMutableData, from userID: String = "", to recieverID: String = "") {
        guard status == .connected else { return }
        
        var bufferDataByte = audioBufferData.mutableBytes
        var bufferSize = audioBufferData.length
        
        #warning("AWS UDP Socket didnt have max limit of bytes, still need to check of the limit")
        let payloadInfoDataSize = 40   // RecieverID(String) + UserID(String) + Date(UInt64)
        let defaultMaximumBufferSize = mtu - payloadInfoDataSize
        
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
            let emitDate: UInt64 = payload.date
            let receiveDate: UInt64 = Date().millisecondsSince1970
            if receiveDate > emitDate {
                let latencyMs: UInt64 = receiveDate - emitDate
                DispatchQueue.main.async {[latencyMs] in
                    NotificationCenter.default.post(UDPSocketLatency: latencyMs)
                }
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
        
        if UDPSocketManager.enableCompresssionAlgorithm {
            guard let decompressedPayload = payload.decompressed(using: UDPSocketManager.compressionAlgorithm) else {
                print("Decompressed Fail")
                return nil
            }
            
            let recievedPayload = UDPSocketRecievedPayload(emitID: emitID, date: date, data: decompressedPayload)
            
            return recievedPayload
        } else {
            let recievedPayload = UDPSocketRecievedPayload(emitID: emitID, date: date, data: payload)
            
            return recievedPayload
        }
        
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
