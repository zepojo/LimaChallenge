//
//  FileItemTests.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 29/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import XCTest
import CoreData
@testable import LimaChallenge

class FileItemTests: XCTestCase {
    
    var fileItem: FileItem!
    
    //MARK: - Private Helpers
    private func mockFileItem(moc: NSManagedObjectContext) -> FileItem {
        let fileItem: FileItem = moc.insertObject()
        fileItem.path = "/image"
        fileItem.name = "image"
        return fileItem
    }
    
    //MARK: - Tests
    override func setUp() {
        super.setUp()
        
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        fileItem = mockFileItem(moc)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHasAnId() {
        XCTAssert(fileItem.id != nil)
    }
    
    func testInitialType() {
        XCTAssert(fileItem.type == FileItemType.unset.rawValue)
    }
    
    func testInitial() {
        XCTAssert(fileItem.initial == "I")
    }
    
    func testItemTypeMapping() {
        let mimetypes = ["inode/directory", "text/plain", "image/jpeg", "image/gif", "audio/mp3", "video/mp4", "other/type"]
        let types: [FileItemType] = [.directory, .text, .staticImage, .animatedImage, .audio, .video, .unknown]
        
        for (index, mimetype) in mimetypes.enumerate() {
            let type = FileItem.fileItemTypeFromMimetype(mimetype)
            let expectedType = types[index]
            XCTAssert(type == expectedType)
        }
    }
}
