//
//  VoiceServerAPI.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/28.
//

import Foundation

enum VoiceServerAPI: APIRequest {
    case makeCallRequest(userID: String, recieverID: String)
    
    case acceptCallRequest(userID: String, recieverID: String)
    
    case declineCallRequest(userID: String, recieverID: String)
    
    case closeTheSessionAndMakeNotice(userID: String, recieverID: String)
    
    static var urlPath: String = "/VoiceServer"
    
    var headers: [String : String]? {
        switch self {
        default:
            let headers = ["Content-Type":URLRequest.ContentType.json.rawValue,
                           "Accept": URLRequest.ContentType.json.rawValue]
            return headers
        }
    }
    
    var body: Data? {
        switch self {
        case .makeCallRequest(let userID, let recieverID):
            return CallRequestRQ(userID: userID, recieverID: recieverID).JSONData
        case .acceptCallRequest(let userID, let recieverID):
            return AcceptCallingRequestRQ(userID: userID, recieverID: recieverID).JSONData
        case .declineCallRequest(let userID, let recieverID):
            return DeclineCallingRequestRQ(userID: userID, recieverID: recieverID).JSONData
        case .closeTheSessionAndMakeNotice(let userID, let recieverID):
            return CloseTheSessionRQ(userID: userID, recieverID: recieverID).JSONData
        }
    }
    
    var method: String {
        switch self {
        case .makeCallRequest, .acceptCallRequest, .declineCallRequest, .closeTheSessionAndMakeNotice:
            return HTTPMethod.POST.rawValue
        }
    }
    
    var endPoint: String {
        var endPoint = ""
        switch self {
        case .makeCallRequest:
            endPoint = "/MakeCallRequest"
        case .acceptCallRequest:
            endPoint = "/AcceptCallingRequest"
        case .declineCallRequest:
            endPoint = "/DeclineCallingRequest"
        case .closeTheSessionAndMakeNotice:
            endPoint = "/CloseTheSession"
        }
        
        return VoiceServerAPI.urlPath + endPoint
    }
}
