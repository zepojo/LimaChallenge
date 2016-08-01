//
//  DirectoryViewerViewModel.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 26/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

class DirectoryViewerViewModel: NSObject {

    // MARK: - Properties
    private var model: FileItem!
    
    lazy private var networkService = NetworkService()
    
    private var moc: NSManagedObjectContext {
        return model.managedObjectContext!
    }

    private var _fetchedResultsController: NSFetchedResultsController?
    private var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let request = NSFetchRequest(entityName: FileItem.entityName)
        let sortDescriptor = NSSortDescriptor(key: FileItem.Key.name.rawValue, ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        request.sortDescriptors = [sortDescriptor]
        request.fetchBatchSize = 20
        if searchQuery?.characters.count > 0 {
            request.predicate = NSPredicate(format: "parent == %@ && name contains[c] %@", model, searchQuery!)
        } else {
            request.predicate = NSPredicate(format: "parent == %@", model)
        }
        _fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: FileItem.Key.initial.rawValue, cacheName: nil)
        _fetchedResultsController!.delegate = self
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            print("ERROR: \(error)")
        }
        return _fetchedResultsController!
    }
    
    var searchQuery: String?
    
    var title: String {
        return model.name!
    }
    
    // Reactive variable used to notify that the content has changed
    var contentFetched = Variable(0)
    
    
    // MARK: - Initialization
    init(model: FileItem) {
        super.init()
        self.model = model
    }
    
    
    // MARK: - Helpers
    private func fileItemAtIndexPath(indexPath: NSIndexPath) -> FileItem {
        return fetchedResultsController.objectAtIndexPath(indexPath) as! FileItem
    }
    
    func fileItemTypeAtIndexPath(indexPath: NSIndexPath) -> FileItemType {
        let fileItem = fileItemAtIndexPath(indexPath)
        return FileItemType(rawValue: Int(fileItem.type!))!
    }
    
}


// MARK: - Data Loading
extension DirectoryViewerViewModel {
    
    // Load the content of a remote directory, and set every item in it as its children
    func loadContent(completionHandler: (NSError?) -> Void) {
        networkService.loadDirectoryContent(model.path!) { (items: [String]?, error: NSError?) in
            guard error == nil else {
                completionHandler(error)
                return
            }
            
            var fileItems = [FileItem]()
            for item in items! {
                let fileItem: FileItem = self.moc.insertObject()
                fileItem.name = item
                fileItems.append(fileItem)
            }
            self.model.children = NSSet(array: fileItems)
            
            completionHandler(nil)
            
            self.loadNextChildMetadata()
        }
    }
    
    // Once the content of a directory has been fetched, we retrieve all of its children metadata,
    // to get their type (directory, image, audio, ...) among other data.
    // We do this in a recursive way, to prevent having a lot of network requests at the same time.
    private func loadNextChildMetadata() {
        guard let items = model.children?.allObjects as? [FileItem] else { return }
        let unsetItems = items.filter({ $0.type == FileItemType.unset.rawValue })
        guard let item = unsetItems.first else { return }
        
        networkService.loadItemMetadata(item.name!, fromDirectoryWithPath: model.path!) { (metadata: [String : AnyObject]?, error: NSError?) in
            if error != nil {
                // Task has failed, but we don't need to inform the user (the fileItem will remain unchanged, with an .unset type)
                // and we should continue to fetch metadata for other items
                print(error)
            }
            
            if let mimetype = metadata!["mimetype"] as? String {
                item.type = FileItem.fileItemTypeFromMimetype(mimetype).rawValue
            }
            if let path = metadata!["path"] as? String { item.path = path }
            if let size = metadata!["size"] as? Double { item.size = size }
            self.loadNextChildMetadata()
        }
    }
    
}


// MARK: - Table Data
extension DirectoryViewerViewModel {
    
    func numberOfSections() -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfItemsInSection(section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections?[section]
        return sectionInfo?.numberOfObjects ?? 0
    }
    
    func titleForSection(section: Int) -> String {
        guard let sectionInfo = fetchedResultsController.sections?[section],
            let firstObject = sectionInfo.objects?.first as? FileItem else {
                return ""
        }
        return firstObject.initial
    }
    
    func sectionTitles() -> [String] {
        return fetchedResultsController.sectionIndexTitles
    }
    
    func sectionForSectionIndexTitle(title: String, atIndex index: Int) -> Int {
        return fetchedResultsController.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    func titleAtIndexPath(indexPath: NSIndexPath) -> String? {
        let fileItem = fileItemAtIndexPath(indexPath)
        return fileItem.name
    }

}


// MARK: - CoreData Results Manager
extension DirectoryViewerViewModel: NSFetchedResultsControllerDelegate {
    
    // Called when data corresponding to the NSFetchedResultsController changes
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // No need to increment a variable, should emit the signal explicitly
        contentFetched.value += 1
    }
    
}


// MARK: - Search Handler
extension DirectoryViewerViewModel {

    func performSearch(query: String?) {
        searchQuery = query
        _fetchedResultsController = nil
        
        contentFetched.value += 1
    }
    
}


// MARK: - FileItem Creation
extension DirectoryViewerViewModel {
    
    func createDirectory(name: String, completionHandler: (NSError?) -> Void) {
        createItem(.directory, name: name, data: nil, completionHandler: completionHandler)
    }
    
    func createImage(name: String, data: NSData, completionHandler: (NSError?) -> Void) {
        createItem(.staticImage, name: name, data: data, completionHandler: completionHandler)
    }
    
    func createItem(type: FileItemType, name: String, data: NSData?, completionHandler: (NSError?) -> Void) {
        networkService.pushItem(type, name: name, toDirectoryWithPath: model.path!, data: data) { (error: NSError?) in
            guard error == nil else {
                completionHandler(error)
                return
            }
            
            let item: FileItem = self.moc.insertObject()
            item.type = type.rawValue
            item.name = name
            item.path = "\(self.model.path!)/\(name)"
            item.parent = self.model
            self.moc.saveOrRollback()
            
            completionHandler(nil)
        }
    }
    
}



// MARK: - Sub-viewModels creation
extension DirectoryViewerViewModel {
    
    func directoryViewerViewModelForIndexPath(indexPath: NSIndexPath) -> DirectoryViewerViewModel {
        let fileItem = fileItemAtIndexPath(indexPath)
        return DirectoryViewerViewModel(model: fileItem)
    }
    
    func mediaPlayerViewModelForIndexPath(indexPath: NSIndexPath) -> MediaPlayerViewModel {
        let fileItem = fileItemAtIndexPath(indexPath)
        return MediaPlayerViewModel(model: fileItem)
    }
    
}