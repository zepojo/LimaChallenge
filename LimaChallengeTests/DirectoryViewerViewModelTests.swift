//
//  DirectoryViewerViewModelTests.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 29/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import XCTest
import CoreData
@testable import LimaChallenge

class DirectoryViewerViewModelTests: XCTestCase {
    
    var model: DirectoryViewerViewModel!
    
    //MARK: - Private Helpers
    private func mockRootFileItem(moc: NSManagedObjectContext) -> FileItem {
        let rootItem: FileItem = moc.insertObject()
        rootItem.root = true
        rootItem.type = FileItemType.directory.rawValue
        rootItem.path = ""
        rootItem.name = "/"
        return rootItem
    }
    
    private func mockChildrenFileItem(parentItem: FileItem) {
        let childItem1: FileItem = parentItem.managedObjectContext!.insertObject()
        childItem1.type = FileItemType.directory.rawValue
        childItem1.path = "/folder"
        childItem1.name = "folder"
        childItem1.parent = parentItem
        
        let childItem2: FileItem = parentItem.managedObjectContext!.insertObject()
        childItem2.type = FileItemType.staticImage.rawValue
        childItem2.path = "/image"
        childItem2.name = "image"
        childItem2.parent = parentItem
    }
    
    //MARK: - Tests
    override func setUp() {
        super.setUp()
        
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let fileItem = mockRootFileItem(moc)
        mockChildrenFileItem(fileItem)
        model = DirectoryViewerViewModel(model: fileItem)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testSectionsCount() {
        XCTAssert(model.numberOfSections() == 2)
    }
    
    func testRowsCount() {
        XCTAssert(model.numberOfItemsInSection(0) == 1)
    }
    
    func testSectionTitle() {
        XCTAssert(model.titleForSection(0) == "F")
    }
    
    func testCellTitle() {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        XCTAssert(model.titleAtIndexPath(indexPath) == "folder")
    }
    
    func testSearch() {
        model.performSearch("ima")
        XCTAssert(model.numberOfSections() == 1)
        XCTAssert(model.numberOfItemsInSection(0) == 1)
        XCTAssert(model.titleForSection(0) == "I")
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        XCTAssert(model.titleAtIndexPath(indexPath) == "image")
    }
    
    func testFileItemType() {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        XCTAssert(model.fileItemTypeAtIndexPath(indexPath) == FileItemType.directory)
    }
    
}
