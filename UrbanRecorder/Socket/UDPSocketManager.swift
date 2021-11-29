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
    
    static let outPort: String = Bundle.main.object(forInfoDictionaryKey: "UDPSocketOutPort") as? String ?? ""
    
    static let inPort: String = Bundle.main.object(forInfoDictionaryKey: "UDPSocketInPort") as? String ?? ""
    
    static let shared: UDPSocketManager = UDPSocketManager()
    
    static let compressionAlgorithm: NSData.CompressionAlgorithm = .lz4
    
    static let enableCompresssionAlgorithm: Bool = false
    /*
     AWS can accept maximum package size(64K 65536 bytes), Mac default max buffer size is 9216
     Use the command for modify the os system maximun UPD buffer with size as 65535 bytes
     $ sysctl -w net.inet.udp.maxdgram=65535
     */
    var mtu: Int = 9212
    
    private var udpSocketOut: UDPSocketOut?
    
    private var udpSocketIn: UDPSocketIn?
    
    weak var delegate: UDPSocketManagerDelegate?
    
    private var receiveCallback: ((Data)->Void)?
    
    override init() {
        super.init()
    }
    
    func setupBroadcastConnection(_ complete: @escaping()->Void) {
        // UDPOutSocket
        let ip = UDPSocketManager.hostIP
        guard let outPort = UInt16(UDPSocketManager.outPort) else { fatalError() }
        udpSocketOut = UDPSocketOut(ip: ip, port: outPort)
        udpSocketOut?.setupConnection { mtu in
            self.mtu = mtu
            complete()
        }
    }
    
    func setupSubscribeConnection(_ complete: @escaping()->Void) {
        // UDPInSocket
        let ip = UDPSocketManager.hostIP
        guard let inPort = UInt16(UDPSocketManager.inPort) else { fatalError() }
        udpSocketIn = UDPSocketIn(ip: ip, port: inPort)
        udpSocketIn?.setupConnection { mtu in
            self.mtu = mtu
            setupUDPInReceive()
            complete()
        }
    }
    
    func subscribeChannel(from userID: String, with channelID: String) {
        // TODO: Subscribe from UDPSocket
        guard let udpSocketIn = udpSocketIn,
              udpSocketIn.isSocketReady,
              let subscribeInfo = UDPSocketManager.encodeUDPSocketSubscribeInfo(userID, subscribeChannelID: channelID)
        else { return }
        
        udpSocketIn.subscibeChannel(with: subscribeInfo)
    }
    
    // OutputSocket
    func broadcastBufferData(_ audioBufferData: NSMutableData, from userID: String , to channelID: String) {
        guard let udpSocketOut = udpSocketOut, udpSocketOut.isSocketReady else { return }
        
        var bufferDataByte = audioBufferData.mutableBytes
        var bufferSize = audioBufferData.length
        
        let payloadInfoDataSize = 40   // RecieverID(String) + UserID(String) + Date(UInt64)
        let defaultMaximumBufferSize = mtu - payloadInfoDataSize
        
        while true {
            if bufferSize > defaultMaximumBufferSize {
                
                let audioData = Data(bytes: bufferDataByte, count: defaultMaximumBufferSize)
                
                guard let sendingPayload = UDPSocketManager.encodeUDPSocketPayload(audioData, userID: userID, channelID: channelID) else { break }
                
                udpSocketOut.send(data: sendingPayload)
                
                bufferDataByte += defaultMaximumBufferSize
                bufferSize -= defaultMaximumBufferSize
            } else {
                
                let audioData = Data(bytes: bufferDataByte, count: bufferSize)
                
                guard let sendingPayload = UDPSocketManager.encodeUDPSocketPayload(audioData, userID: userID, channelID: channelID) else { break }
                
                udpSocketOut.send(data: sendingPayload)
                
                break
            }
        }
    }
    
    private func setupUDPInReceive() {
        
        guard let udpSocketIn = udpSocketIn, udpSocketIn.isSocketReady else { return }
        // Set Up ReceiveCallback
        udpSocketIn.setupDidReceiveDataCallback({ [weak self]  incomingData in
            
            let payloadType: UDPReceivedPayloadType = UDPSocketManager.getReceiviePayloadTypeAndData(incomingData)
            
            guard let self = self else { return }
            
            switch payloadType {
            case .subscribeProcess(let subscribeInfo):
                print("Subscribe Success: \(subscribeInfo)")
                udpSocketIn.subscribeOnChannel = subscribeInfo.subscribeChannelID
            case .audioBuffer(let recievedPayload):
                let data = recievedPayload.data
                let channelID = recievedPayload.channelID
                
                self.delegate?.didReceiveAudioBuffersData(self, data: data, from: channelID)
                // Notification
                let emitDate: UInt64 = recievedPayload.date
                let receiveDate: UInt64 = Date().millisecondsSince1970
                if receiveDate > emitDate {
                    let latencyMs: UInt64 = receiveDate - emitDate
                    DispatchQueue.main.async {[latencyMs] in
                        NotificationCenter.default.post(UDPSocketLatency: latencyMs)
                    }
                }
            case .unknow:
                break
            }
            
        })
    }
    
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
    
    static func encodeUDPSocketSubscribeInfo(_ userID: String, subscribeChannelID: String) -> Data? {
        /*
         UDPSocketInSendSubscribeInfo
         --------------------------------------------------------------------
         Field Offset | Field Name | Field type | Field Size(byte) | Description
         --------------------------------------------------------------------
         0              userID      String          16
         16             channelID   String          16
         --------------------------------------------------------------------
         */
        let date = Date().millisecondsSince1970
        
        var newData = withUnsafeBytes(of: userID) { Data($0) }   // Offset: 0
        newData.append(withUnsafeBytes(of: subscribeChannelID) { Data($0) })   // Offset: 16
        newData.append(withUnsafeBytes(of: date) { Data($0) }) // Offset: 32
        
        return newData
    }
    
    static func getReceiviePayloadTypeAndData(_ data: Data) -> UDPReceivedPayloadType {
        
        let payloadType: UInt8 = NSMutableData(data: data.advanced(by: 0)).bytes.load(as: UInt8.self)
        
        switch payloadType {
        case 0:
            /*
             UDPSocketReceiveSubscribeInfo
             --------------------------------------------------------------------
             Field Offset | Field Name | Field type | Field Size(byte) | Description
             --------------------------------------------------------------------
             0              payloadType Uint8           1               // 0: Subscribe 1:AudioBuffer
             1              channelID   String          16
             17             socketIP    String          16
             33             socketPort  UInt16          2
             35
             --------------------------------------------------------------------
             */
            
            // Parse Into SubscribeInfo
            let dataArray = [UInt8](data)
            let channelID: String = String(bytes: dataArray, encoding: .utf8, offset: 1, length: 16)
            let socketIP: String = String(bytes: dataArray, encoding: .utf8, offset: 17, length: 16)
            let socketPort: UInt16 = NSMutableData(data: data.advanced(by: 33)).bytes.load(as: UInt16.self)
            
            let recievedSubscribeInfo = UDPSocketRecievedSubscribeInfo(subscribeChannelID: channelID, socketIP: socketIP, socketPort: socketPort)
            
            return .subscribeProcess(recievedSubscribeInfo)
        case 1:
            /*
             UDPSocketReceivePayload
             --------------------------------------------------------------------
             Field Offset | Field Name | Field type | Field Size(byte) | Description
             --------------------------------------------------------------------
             0              payloadType Uint8           1               // 0: Subscribe 1:AudioBuffer
             1              channelID   String          16
             17             date        UInt64          8               MillisecondsSince1970
             25             data        UInt32
             --------------------------------------------------------------------
             */
            
            // Parse Into AudioBuffer
            let dataArray = [UInt8](data)
            let channelID: String = String(bytes: dataArray, encoding: .utf8, offset: 1, length: 16)
            let date: UInt64 = NSMutableData(data: data.advanced(by: 17)).bytes.load(as: UInt64.self)
            let payload: Data = data.advanced(by: 25)
            
            if UDPSocketManager.enableCompresssionAlgorithm {
                guard let decompressedPayload = payload.decompressed(using: UDPSocketManager.compressionAlgorithm) else {
                    print("Decompressed Fail")
                    return .unknow
                }
                
                let recievedPayload = UDPSocketRecievedPayload(channelID: channelID, date: date, data: decompressedPayload)
                
                return .audioBuffer(recievedPayload)
            } else {
                let recievedPayload = UDPSocketRecievedPayload(channelID: channelID, date: date, data: payload)
                
                return .audioBuffer(recievedPayload)
            }
        default:
            return .unknow
        }
    }
}
/*
 payloadType
 0: Subscribe session
 1: Audiobuffer payload
 */
enum UDPReceivedPayloadType {
    case subscribeProcess(UDPSocketRecievedSubscribeInfo)
    case audioBuffer(UDPSocketRecievedPayload)
    case unknow
}

struct UDPSocketRecievedPayload {
    let channelID: String
    let date: UInt64
    let data: Data
}

struct UDPSocketRecievedSubscribeInfo {
    let subscribeChannelID: String
    let socketIP: String
    let socketPort: UInt16
}
