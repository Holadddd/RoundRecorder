//
//  HTTPClient.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/28.
//

import Foundation

protocol APIRequest {
    
    static var urlPath: String { get }
    
    var headers: [String: String]? { get }

    var body: Data? { get }

    var method: String { get }

    var endPoint: String { get }
}

enum HTTPClientError: Error {

    case decodeDataFail

    case clientError(Data)

    case serverError

    case unexpectedError
    
}

enum HTTPMethod: String {

    case GET

    case POST
}

class HTTPClient {
    
    static let hostIP: String = Bundle.main.object(forInfoDictionaryKey: "APIHostIP") as? String ?? ""
    
    static let shared = HTTPClient()

    private let decoder = JSONDecoder()

    private let encoder = JSONEncoder()

    private init() { }
    
    func request(_ API: APIRequest,
        completion: @escaping (Result<Data?, Error>) -> Void
    ) {
        
        let request = makeURLRequest(API)
        
        URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, response, error) in

            guard error == nil else {

                return completion(Result.failure(error!))
            }
                
            // swiftlint:disable force_cast
            let httpResponse = response as! HTTPURLResponse
            // swiftlint:enable force_cast
            let statusCode = httpResponse.statusCode

            switch statusCode {

            case 200..<300:
                
                completion(Result.success(data))

            case 400..<500:

                completion(Result.failure(HTTPClientError.clientError(data!)))

            case 500..<600:

                completion(Result.failure(HTTPClientError.serverError))

            default: return

                completion(Result.failure(HTTPClientError.unexpectedError))
            }

        }).resume()
    }

    private func makeURLRequest(_ APIRequest: APIRequest) -> URLRequest {
        
        let urlString = "http://" + HTTPClient.hostIP + APIRequest.endPoint
        
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        
        request.allHTTPHeaderFields = APIRequest.headers
        
        request.httpBody = APIRequest.body

        request.httpMethod = APIRequest.method

        return request
    }
}

