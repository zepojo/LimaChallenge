//
//  NetworkService.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 26/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation

enum NetworkServiceErrorCode: Int {
    case invalidURL
    case JSONParsingFailed
    case badServerResponse
}

class NetworkService: NSObject {
    
    // MARK: - Properties
    static let host = "http://ioschallenge.api.meetlima.com"
    
    
    // MARK: - Helpers
    private func createNetworkError(code: NetworkServiceErrorCode, object: AnyObject? = nil) -> NSError {
        var description = ""
        switch code {
        case .invalidURL:
            description = "Invalid URL"
        case .JSONParsingFailed:
            description = "JSON parsing failed"
        case .badServerResponse:
            description = "Bad server response"
        }
        var userInfo = [NSLocalizedDescriptionKey : description]
        if let objectDescription = object?.description {
            userInfo["object"] = objectDescription
        }
        return NSError(domain: "Network", code: code.rawValue, userInfo: userInfo)
    }
    
    func completeURLFromPath(path: String) -> NSURL? {
        if let encodedPath = path.stringByAddingPercentEncodingWithAllowedCharacters(.URLFragmentAllowedCharacterSet()) {
            return NSURL(string: "\(NetworkService.host)\(encodedPath)")
        }
        return nil
    }
    
}


// MARK: - Item Pull (GET)
extension NetworkService {
    
    func loadItemData(path: String, completionHandler: (NSData?, NSError?) -> Void) {
        guard let url = completeURLFromPath(path) else {
            let networkError = createNetworkError(.invalidURL)
            completionHandler(nil, networkError)
            return
        }
        
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            let statusCode = (response as! NSHTTPURLResponse).statusCode
            if statusCode == 200 {
                completionHandler(data!, nil)
            } else {
                let networkError = self.createNetworkError(.badServerResponse, object: statusCode)
                completionHandler(nil, networkError)
            }
        }
        task.resume()
    }
    
    func loadDirectoryContent(path: String, completionHandler: ([String]?, NSError?) -> Void) {
        loadItemData(path) { (data: NSData?, error: NSError?) in
            guard data != nil else {
                completionHandler(nil, error)
                return
            }
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! [String]
                completionHandler(json, nil)
            } catch {
                print("Error: \(error)")
                let networkError = self.createNetworkError(.JSONParsingFailed)
                completionHandler(nil, networkError)
            }
        }
    }
    
    func loadItemMetadata(name: String, fromDirectoryWithPath directoryPath: String, completionHandler: ([String: AnyObject]?, NSError?) -> Void) {
        let path = "\(directoryPath)/\(name)?stat"
        loadItemData(path) { (data: NSData?, error: NSError?) in
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! [String: AnyObject]
                completionHandler(json, nil)
            } catch {
                print("Error: \(error)")
                let networkError = self.createNetworkError(.JSONParsingFailed)
                completionHandler(nil, networkError)
            }
        }
    }
    
}


// MARK: - Item Push (PUT)
extension NetworkService {
    
    func pushItem(type: FileItemType, name: String, toDirectoryWithPath directoryPath: String, data: NSData?, completionHandler: (NSError?) -> Void) {
        let path = "\(directoryPath)/\(name)"
        guard let url = completeURLFromPath(path) else {
            let networkError = createNetworkError(.invalidURL)
            completionHandler(networkError)
            return
        }
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        if type != .directory {
            var headers = request.allHTTPHeaderFields ?? [String: String]()
            // In its current state, the app is only able to upload static images, so we can hardcode the content type
            // Just add a switch here to support other file format
            headers["Content-Type"] = "image/png"
            request.allHTTPHeaderFields = headers
            request.HTTPBody = data
        }
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            guard error == nil else {
                completionHandler(error)
                return
            }
            
            let statusCode = (response as! NSHTTPURLResponse).statusCode
            if statusCode == 201 {
                completionHandler(nil)
            } else {
                let networkError = self.createNetworkError(.badServerResponse, object: statusCode)
                completionHandler(networkError)
            }
        }
        task.resume()
    }
    
}