//
//  FileSystemService.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 28/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation

class FileSystemService: NSObject {

    // MARK: - Properties
    lazy var fileManager = NSFileManager.defaultManager()
    
    var cacheDirectory: NSURL {
        return fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).last!
    }
    
    
    // MARK: - Helpers
    func cacheURLForName(name: String) -> NSURL {
        return cacheDirectory.URLByAppendingPathComponent(name)
    }
    
    
    // MARK: - Cache Handling
    func saveItem(data: NSData, withName name: String) -> Bool {
        let fileURL = cacheURLForName(name)
        guard let _ = try? data.writeToURL(fileURL, options: .DataWritingAtomic) else {
            return false
        }
        return true
    }
    
    func retrieveCachedItem(name: String) -> NSData? {
        let fileURL = cacheURLForName(name)
        let path = fileURL.path!
        return fileManager.contentsAtPath(path)
    }
    
    func deleteCachedItem(name: String) -> Bool {
        let fileURL = cacheURLForName(name)
        guard let _ = try? fileManager.removeItemAtURL(fileURL) else {
            return false
        }
        return true
    }
}
