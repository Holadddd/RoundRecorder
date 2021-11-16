//
//  SubscribeManager.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/1.
//

import Foundation
import SocketIO

protocol SocketManagerDelegate: AnyObject {
    
    func callRequest(from user: UserInfo)
    
    func callRequestAccept(from user: UserInfo)
    
    func callRequestDecline(from user: UserInfo)
    
    func calledSessionClosed(by user: UserInfo)
}

class SubscribeManager: NSObject {
    
    static let hostIP: String = Bundle.main.object(forInfoDictionaryKey: "SocketHostIP") as? String ?? ""
    
    static let shared: SubscribeManager = SubscribeManager()
    
    var userID: String?
    
    var sockerID: String? {
        return client?.sid ?? nil
    }
    
    var manager: SocketManager?
    
    var client: SocketIOClient? 
    
    weak var delegate: SocketManagerDelegate?
    
    override init() {
        super.init()
        
        let urlString = "http://" + SubscribeManager.hostIP 
        guard let url = URL(string: urlString) else {return}
        
        manager = SocketManager(socketURL: url)
        
        client = manager?.defaultSocket
    }
    
    func setupWith(_ userID: String) {
        self.userID = userID
        
        client?.on(clientEvent: .connect) {[weak self]data, ack in
            guard let self = self else {print("Fail to get socket client id"); return }
            
            // Publish the socket status
            NotificationCenter.default.post(name: .TCPsocketConnectionDidFinish, object: nil)
            
            // TODO: Sync UUID and socket ID by calling web post api for server sending the correct subscription
            self.didSetupClientConnection(userID: userID)
            print("Connect socket seuccess")
            for event in SubscribeEvent.allCases {
                self.subscribeOnEvent(event)
            }
        }
        
        client?.connect()
    }
    
    private func didSetupClientConnection(userID: String) {
        self.userID = userID
    }
    
    private func subscribeOnEvent(_ subscribesEvent: SubscribeEvent) {
        
        client?.on(subscribesEvent.eventID, callback: { [weak self] content, ack in
            guard let self = self else { return }
            guard let dic = content[0] as? [String:String],
                  let deviceID = dic["deviceID"],
                  let userID = dic["userID"]
            else { return }
            
            let emitUser = UserInfo(deviceID: deviceID, userID: userID, isAvailable: true)
            
            switch subscribesEvent {
            case .callRequest:
                self.delegate?.callRequest(from: emitUser)
            case .callRequestAccept:
                self.delegate?.callRequestAccept(from: emitUser)
            case .callRequestDecline:
                self.delegate?.callRequestDecline(from: emitUser)
            case .calledSessionClosed:
                self.delegate?.calledSessionClosed(by: emitUser)
            }
        })
    }
    
    private func unSubscribeOnEvent(_ subscribesEvent: SubscribeEvent) {
        client?.off(subscribesEvent.eventID)
    }
}

enum SubscribeEvent: CaseIterable {
    
    case callRequest
    
    case callRequestAccept
    
    case callRequestDecline
    
    case calledSessionClosed
    
    var eventID: String {
        switch self {
        case .callRequest:
            return "callRequest"
        case .callRequestAccept:
            return "acceptCallRequest"
        case .callRequestDecline:
            return "declineCallRequest"
        case .calledSessionClosed:
            return "sessionClosed"
        }
    }
    
}

