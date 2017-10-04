//
//  NetworkClient.swift
//  On The Map
//
//  Created by Pete Barnes on 9/11/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import Foundation

// MARK: - HTTPMethod

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - NetworkClient

protocol NetworkClient {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    
    func preprocessData (data: Data) -> Data
}

// Enums below from suggestions at:  https://appventure.me/2015/10/17/advanced-practical-enum-examples/#errortype


// MARK: - DecodeError

enum DecodeError: Error {
    case typeMismatch(expected: String, actual: String)
    case missingKey(String)
    case custom(String)
}

// MARK: - APIError

enum APIError : Error {
    // Missing parameters to make request
    case missingParametersError(String)
    // Can't connect to the server (maybe offline?)
    case connectionError(error: Error)
    // The server responded with a non 200 status code
    case serverError(statusCode: Int, error: Error)
    // We got no data (0 bytes) back from the server
    case noDataError
    // The server response can't be converted from JSON to a Dictionary
    case jsonSerializationError(error: Error)
    // The decoding Failed
    case jsonMappingError(converstionError: DecodeError)
}

// MARK: - NetworkClient

extension NetworkClient {
    
    
    func buildTheURL(_ method: String, parameters: [String: String?], httpMethod: HTTPMethod = .get, headers: [String:AnyObject] = [:], jsonBodyParameters: [String:AnyObject] = [:]) -> NSMutableURLRequest {
        
        let request = NSMutableURLRequest(url: buildURLFromParameters(parameters, withPathExtension: method))
        
        request.httpMethod = httpMethod.rawValue
        
        let headersKeys = headers.keys
        
        for key in headersKeys {
            request.addValue((headers[key] as? String)!, forHTTPHeaderField: key)
        }
        
        if jsonBodyParameters.count > 0 {
            let postData: Data!
            do {
                postData =  try JSONSerialization.data(withJSONObject: jsonBodyParameters, options: .prettyPrinted)
            } catch {
                print("Could not create JSON data from \(jsonBodyParameters)")
                return request
            }
            
            request.httpBody = postData
        }
        
        return request
    }
    
    func makeTheTask(request: URLRequest, errorDomain: String, completionHandler: @escaping (_ result: AnyObject?, _ error: APIError?) -> Void) -> URLSessionDataTask {
        
        var session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            
            func sendError(_ errorString: String,_ error: APIError) {
                print(error)
                completionHandler(nil, error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)", APIError.connectionError(error: error!))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                
                let userInfo = [NSLocalizedDescriptionKey : "The server responded with a non 200 status code"]
                let error = NSError(domain: errorDomain, code: 1, userInfo: userInfo)
                
                sendError("Your request returned a status code other than 2xx!", APIError.serverError(statusCode: statusCode!, error: error))
                
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!", APIError.noDataError)
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            
            let newData = self.preprocessData(data: data)
            self.convertDataWithCompletionHandler(newData, completionHandlerForConvertData: completionHandler)
        }
        
        /* 7. Start the request */
        task.resume()
        
        
        return task
    }
    
    
    
    // MARK: Helpers
    
    // substitute the key for the value that is contained within the method name
    func substituteKeyInMethod(_ method: String, key: String, value: String) -> String? {
        if method.range(of: "{\(key)}") != nil {
            return method.replacingOccurrences(of: "{\(key)}", with: value)
        } else {
            return nil
        }
    }
    
    
    // create a URL from parameters
    private func buildURLFromParameters(_ parameters: [String:String?], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: value)
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: APIError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, APIError.jsonSerializationError(error: NSError(domain: "NetworkClient.convertDataWithCompletionHandler", code: 1, userInfo: userInfo)))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
}
