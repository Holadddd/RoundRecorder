//
//  URLRequest+.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/10/28.
//

import Foundation

extension URLRequest{
    
    // MARK: - Public option
    ///Content Type for URLRequest
    enum ContentType : String{
        case json = "application/json"
        case formData = "multipart/form-data"
        case urlencoded = "application/x-www-form-urlencoded"
        case others = ""
    }
    ///HttpVerb for URLRequest
    enum HTTPVerb: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case HEAD = "HEAD"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
        case OPTIONS = "OPTIONS"
        case TRACE = "TRACE"
        case CONNECT = "CONNECT"
        case UNKNOWN = "UNKNOWN"
    }
    ///HTTPMimeType for URLRequest
    enum HTTPMimeType : String {
        case imageJpeg = "image/jpeg"
        case imagePng = "image/png"
    }
}
