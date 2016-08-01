//
//  MediaPlayerViewModelTests.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 29/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import XCTest
import CoreData
@testable import LimaChallenge

class MediaPlayerViewModelTests: XCTestCase {
    
    var model: MediaPlayerViewModel!
    
    //MARK: - Private Helpers
    private func mockFileItem(moc: NSManagedObjectContext) -> FileItem {
        let fileItem: FileItem = moc.insertObject()
        fileItem.type = FileItemType.staticImage.rawValue
        fileItem.path = "/image"
        fileItem.name = "image"
        fileItem.size = 1321788
        return fileItem
    }
    
    //MARK: - Tests
    override func setUp() {
        super.setUp()
        
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let fileItem = mockFileItem(moc)
        model = MediaPlayerViewModel(model: fileItem)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testModelType() {
        XCTAssert(model.modelType == FileItemType.staticImage)
    }
    
    func testTitle() {
        XCTAssert(model.title == "image")
    }
    
    func testReadableSize() {
        print(model.readableSize)
        XCTAssert(model.readableSize == "1.3 MB")
    }
    
    func testDataIsCacheable() {
        XCTAssert(model.dataIsCacheable == true)
    }
}
