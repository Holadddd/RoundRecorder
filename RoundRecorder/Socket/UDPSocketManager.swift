//
//  UDPSocketManager.swift
//  RoundRecorder
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
    
    static let broadcastTimeLimitation: TimeInterval = 600.0
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
    
    func stopBroadcastConnection() {
        // UDPOutSocket
        udpSocketOut?.cancelBroadcastChannel()
    }
    
    func setupSubscribeConnection(_ complete: @escaping(Result<Bool, UDPSocketError>)->Void) {
        // UDPInSocket
        let ip = UDPSocketManager.hostIP
        guard let inPort = UInt16(UDPSocketManager.inPort) else { complete(.failure(.failInSetupSubscription)); return }
        
        if udpSocketIn == nil {
            udpSocketIn = UDPSocketIn(ip: ip, port: inPort)
            udpSocketIn?.setupConnection {[weak self] mtu in
                guard let self = self else { return }
                self.mtu = mtu
                self.setupUDPInReceive()
                complete(.success(false))
            }
        } else {
            complete(.success(true))
        }
    }
    
    func subscribeChannel(from userID: String, with channelID: String) {
        guard let udpSocketIn = udpSocketIn else { print("udpSocketIn is not ready yet"); return }
        
        udpSocketIn.subscibeChannel(from: userID, with: channelID)
    }
    
    func unsubscribeChannel(from userID: String, with channelID: String) {
        guard let udpSocketIn = udpSocketIn else { print("udpSocketIn is not ready yet"); return }
        
        udpSocketIn.unsubscibeChannel(from: userID, with: channelID)
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
                
                udpSocketOut.broadcastChannel(userID: userID, channelID: channelID, payload: audioData)
                
                bufferDataByte += defaultMaximumBufferSize
                bufferSize -= defaultMaximumBufferSize
            } else {
                
                let audioData = Data(bytes: bufferDataByte, count: bufferSize)
                
                udpSocketOut.broadcastChannel(userID: userID, channelID: channelID, payload: audioData)
                
                break
            }
        }
    }
    
    private func setupUDPInReceive() {
        
        guard let udpSocketIn = udpSocketIn, udpSocketIn.isSocketReady else { return }
        // Set Up ReceiveCallback
        udpSocketIn.setupDidReceiveDataCallback({ [weak self]  incomingData in
            
            let payloadType: UDPReceivedPayloadType = UDPSocketManager.getUDPSocketReceivingPayloadTypeAndData(incomingData)
            
            guard let self = self else { return }
            
            switch payloadType {
            case .subscribeProcess(let subscribeInfo):
                let channelID = subscribeInfo.subscribeChannelID
                let ip = subscribeInfo.socketIP
                let port = subscribeInfo.socketPort
                print("=========    Success Subscribe On Channel: \(channelID), IP: \(ip), SOCKET PORT: \(port) ========")
            case .unsubscribeProcess(let unsubscribeInfo):
                let channelID = unsubscribeInfo.subscribeChannelID
                let ip = unsubscribeInfo.socketIP
                let port = unsubscribeInfo.socketPort
                print("=========    Success Unsubscribe On Channel: \(channelID), IP: \(ip), SOCKET PORT: \(port) ========")
            case .recievingBroadcastAudioBuffer(let recievedPayload):
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
                print("UDPInReceive unknow data")
                break
            }
            
        })
    }
    
    static func getUDPSocketReceivingPayloadTypeAndData(_ data: Data) -> UDPReceivedPayloadType {
        
        let payloadType: UInt8 = NSMutableData(data: data.advanced(by: 0)).bytes.load(as: UInt8.self)   // 0: Subscribe 1: Unsubscribe 11:AudioBuffer
        
        switch payloadType {
        case 0, 1:
            /*
             UDPSocketReceiveSubscribeInfo
             --------------------------------------------------------------------
             Field Offset | Field Name | Field type | Field Size(byte) | Description
             --------------------------------------------------------------------
             0              payloadType Uint8           1               // 0: Subscribe 1: Unsubscribe 11: BroadcastAudioBuffer 12: BroadcastFailWithRepeatChannelID
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
            
            if payloadType == 0 {
                let recievedSubscribeInfo = UDPSocketRecievedSubscribeInfo(subscribeChannelID: channelID, socketIP: socketIP, socketPort: socketPort)
                
                return .subscribeProcess(recievedSubscribeInfo)
            } else {
                let recievedSubscribeInfo = UDPSocketRecievedSubscribeInfo(subscribeChannelID: channelID, socketIP: socketIP, socketPort: socketPort)
                
                return .unsubscribeProcess(recievedSubscribeInfo)
            }
        case 11:
            /*
             UDPSocketReceivePayload
             --------------------------------------------------------------------
             Field Offset | Field Name | Field type | Field Size(byte) | Description
             --------------------------------------------------------------------
             0              payloadType Uint8           1               // 0: Subscribe 1: Unsubscribe 11: BroadcastAudioBuffer 12: BroadcastFailWithRepeatChannelID
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
                
                return .recievingBroadcastAudioBuffer(recievedPayload)
            } else {
                let recievedPayload = UDPSocketRecievedPayload(channelID: channelID, date: date, data: payload)
                
                return .recievingBroadcastAudioBuffer(recievedPayload)
            }
        default:
            return .unknow
        }
    }
}
/*
 payloadType
 0: Subscribe 1: Unsubscribe 11:AudioBuffer
 */
enum UDPReceivedPayloadType {
    case subscribeProcess(UDPSocketRecievedSubscribeInfo)
    case unsubscribeProcess(UDPSocketRecievedSubscribeInfo)
    case recievingBroadcastAudioBuffer(UDPSocketRecievedPayload)
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

enum UDPSocketError: Error {
    case failInSetupSubscription
}
