//
//  UserAPI.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/28.
//

import Foundation

enum UserAPI: APIRequest {
    
    case getAvailableUsersList(userID: String)
    
    case registerAvailableDevice(UUID: String, socketID: String, userID: String)
    
    static var urlPath = "/User"
    
    var endPoint: String {
        var endPoint = ""
        switch self {
        case .getAvailableUsersList:
            endPoint = "/GetAvailableUsersList"
        case .registerAvailableDevice:
            endPoint = "/RegisterAvailableDevice"
        }
        
        return UserAPI.urlPath + endPoint
    }
    
    var headers: [String : String]? {
        switch self {
        default:
            let headers = ["Content-Type":URLRequest.ContentType.json.rawValue,
                           "Accept": URLRequest.ContentType.json.rawValue]
            return headers
        }
    }
    
    var method: String {
        switch self {
        case .getAvailableUsersList:
            return HTTPMethod.GET.rawValue
        case .registerAvailableDevice:
            return HTTPMethod.POST.rawValue
        }
    }
    
    var body: Data? {
        switch self {
        case .registerAvailableDevice(let UUID, let socketID, let userID):
            
            return DeviceInfoRQ(UUID: UUID, socketID: socketID, userID: userID).JSONData
        default:
            return nil
        }
    }
}
