//
//  FileSystemServiceTests.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 29/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import XCTest
@testable import LimaChallenge

class FileSystemServiceTests: XCTestCase {
    
    var service: FileSystemService!
    
    override func setUp() {
        super.setUp()
        
        service = FileSystemService()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testService() {
        let dataString = "Random test string"
        let data = dataString.dataUsingEncoding(NSUTF8StringEncoding)!
        let name = "File"
        
        let write = service.saveItem(data, withName: name)
        XCTAssert(write == true)
        
        let cachedData = service.retrieveCachedItem(name)
        XCTAssert(cachedData != nil)
        
        let decodedString = NSString(data: cachedData!, encoding: NSUTF8StringEncoding)!
        XCTAssert(decodedString == "Random test string")
        
        let delete = service.deleteCachedItem(name)
        XCTAssert(delete == true)
    }
}
