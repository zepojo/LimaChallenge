//
//  MediaPlayerViewModel.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 27/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import UIKit
import RxSwift

class MediaPlayerViewModel: NSObject {
    
    // MARK: - Properties
    private var model: FileItem!
    // The data of the file being displayed (only for cacheable data types)
    var data: NSData?
    
    lazy private var networkService = NetworkService()
    lazy private var fileSystemService = FileSystemService()
    
    var modelType: FileItemType {
        return FileItemType(rawValue: Int(model.type!))!
    }
    var title: String {
        return model.name!
    }
    var readableSize: String {
        return NSByteCountFormatter.stringFromByteCount(model.size!.longLongValue, countStyle: NSByteCountFormatterCountStyle.File)
    }
    var mediaURL: NSURL? {
        return networkService.completeURLFromPath(model.path!)
    }
    // Only texts and images can be marked as favorite and persisted to disk
    var dataIsCacheable: Bool {
        return [FileItemType.text, FileItemType.staticImage, FileItemType.animatedImage].contains(modelType)
    }

    var isFavorite = Variable<Bool?>(false)
    private var disposeBag = DisposeBag()
    
    // MARK: - Initialization
    init(model: FileItem) {
        super.init()
        self.model = model
        model.rx_observe(Bool.self, "favorite").bindTo(isFavorite).addDisposableTo(disposeBag)
    }
    
    
    // MARK: - Data Loading
    // Load fileItem data, either from the local cache (if available) or from the web
    func loadContent(completionHandler: (NSData?, NSError?) -> Void) {
        if model.favorite! == true, let data = fileSystemService.retrieveCachedItem(model.id!) {
            self.data = data
            completionHandler(data, nil)
        } else {
            networkService.loadItemData(model.path!) { (data: NSData?, error: NSError?) in
                guard error == nil else {
                    completionHandler(nil, error)
                    return
                }
                
                self.data = data
                completionHandler(data, nil)
            }
        }
    }

    
    // MARK: - User Actions
    // When marking fileItem as a favorite, its data is persisted to disk.
    // When unmarking as a favorite, its persisted data is deleted.
    func toggleFavoriteItem() -> Bool {
        if model.favorite! == true {
            fileSystemService.deleteCachedItem(model.id!)
            model.favorite = false
        }
        else {
            guard self.data != nil &&
                fileSystemService.saveItem(self.data!, withName: model.id!) == true else {
                    return false
            }
            model.favorite = true
        }
        
        model.managedObjectContext?.saveOrRollback()
        return true
    }
    
}
