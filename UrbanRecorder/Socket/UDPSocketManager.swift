//
//  UDPSocketManager.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/2.
//

import Foundation
import AVFoundation
import CocoaAsyncSocket

protocol UDPSocketManagerDelegate: AnyObject {
    
    func didReceiveAudioBuffersData(_ manager: UDPSocketManager, data: Data)
    
}

class UDPSocketManager: NSObject, GCDAsyncUdpSocketDelegate {
    
    static let hostIP: String = Bundle.main.object(forInfoDictionaryKey: "UDPSocketHostIP") as? String ?? ""
    
    static let port: String = Bundle.main.object(forInfoDictionaryKey: "UDPSocketPort") as? String ?? ""
    
    static let shared: UDPSocketManager = UDPSocketManager()
    
    static let compressionAlgorithm: NSData.CompressionAlgorithm = .lz4
    
    //AWS can accept maximum package size(64K 65536 bytes)
    let MTU = 65535
    
    var socket: GCDAsyncUdpSocket?
    
    var status: UDPSocketStstus = .disConneected
    
    weak var delegate: UDPSocketManagerDelegate?
    
    private var receiveCallback: ((Data)->Void)?
    
    override init() {
        super.init()
        
        setupUDPReceive()
    }
    
    func setupConnection() {
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue:DispatchQueue.main)
        
        guard let socket = socket ,
              let port = UInt16(UDPSocketManager.port)
        else { return }
        
        let ip = UDPSocketManager.hostIP
        
        do { try socket.bind(toPort: port)} catch { print("")}
        do { try socket.connect(toHost: ip, onPort: port)} catch { print("joinMulticastGroup not proceed")}
        do { try socket.enableBroadcast(true)} catch { print("not able to brad cast")}
        do { try socket.beginReceiving()} catch { print("beginReceiving not proceed")}
        
        status = .connected
    }
    
    func sendAudioBuffer(_ audioBuffer: AudioBuffer, from userUUID: String = "", to recieverUserUUID: String = "") {
        guard status == .connected else { return }
        
        guard var bufferData = audioBuffer.mData else { return }
        var bufferSize = audioBuffer.mDataByteSize
        
        guard let msData = String(Date().millisecondsSince1970).data(using: .utf8) else { return }
        // Using UUID for fixed data size, the size would be 115 bytes
        let socketInfoData = try! JSONEncoder().encode(UDPSocketInfo(senderUserUUID: userUUID, recieverUserUUID: recieverUserUUID))
        
        #warning("AWS UDP Socket didnt have max limit of bytes, still need to check of the limit")
        let defaultMaximumBufferSize = MTU - msData.count - socketInfoData.count
        
        while true {
            if bufferSize > defaultMaximumBufferSize {
                var data = Data.init(bytes: bufferData, count: defaultMaximumBufferSize)
                data.append(msData)
                
                guard var compressedData = data.compressed(using: UDPSocketManager.compressionAlgorithm) else { return }
                // Append data after compressed
                compressedData.append(socketInfoData)
                sendData(compressedData)
                
                bufferData += defaultMaximumBufferSize
                bufferSize -= UInt32(defaultMaximumBufferSize)
            } else {
                var data = Data.init(bytes: bufferData, count: Int(bufferSize))
                data.append(msData)
                guard var compressedData = data.compressed(using: UDPSocketManager.compressionAlgorithm) else { return }
                // Append data after compressed
                compressedData.append(socketInfoData)
                sendData(compressedData)
                break
            }
        }
    }
    
    private func setupUDPReceive() {
        receiveCallback = {[weak self] incomingData in
            guard let self = self,
                  let data = incomingData.decompressed(using: UDPSocketManager.compressionAlgorithm)
            else { return }
            
            data.withUnsafeBytes { rawBufferPointer in
                guard let rawPtr = rawBufferPointer.baseAddress else { return }

                let msTimeStampDataSize: Int = 13
                // AudioData
                let audioDataLength = data.count - msTimeStampDataSize
                let audioData = Data.init(bytes: rawPtr, count: audioDataLength)

                self.delegate?.didReceiveAudioBuffersData(self, data: audioData)

                // Latency
                let timeData = Data.init(bytes: rawPtr + audioDataLength, count: msTimeStampDataSize)
                guard let timeString = String(data: timeData, encoding: .utf8),
                      let sendMsTimeStamp = Int64(timeString) else { return }

                let receiveMsTimeStamp = Date().millisecondsSince1970

                let latencyMs = receiveMsTimeStamp - sendMsTimeStamp
                // Notification
                DispatchQueue.main.async {[latencyMs] in
                    NotificationCenter.default.post(UDPSocketLatency: latencyMs)
                }
            }
        }
    }
    
    private func sendData(_ data: Data) {
        socket?.send(data, withTimeout: -1, tag: 0)
    }
    
}

extension UDPSocketManager {
    //MARK:-GCDAsyncUdpSocketDelegate
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        receiveCallback?(data)
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("didNotConnect")
        status = .disConneected
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("didNotSendDataWithTag")
    }
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Error:\(error.debugDescription)")
        status = .disConneected
    }
}

struct UDPSocketInfo: Codable {
    let senderUserUUID: String
    let recieverUserUUID: String
}

enum UDPSocketStstus {
    case connected
    case disConneected
}
