//
//  FileItem.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 26/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation
import CoreData


enum FileItemType: Int {
    case unset
    case unknown
    case directory
    case text
    case staticImage
    case animatedImage
    case audio
    case video
}


class FileItem: NSManagedObject {
    
    // MARK: - Properties
    var initial: String {
        guard name != nil && name!.characters.count > 0 else { return "" }
        return name!.substringToIndex(name!.startIndex.advancedBy(1)).uppercaseString
    }
    
    
    // MARK: - ManagedObject Lifecycle
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.id = NSUUID().UUIDString
        self.type = FileItemType.unset.rawValue
    }
    
    
    // MARK: - Helpers
    class func fileItemTypeFromMimetype(mimetype: String) -> FileItemType {
        let type = mimetype.componentsSeparatedByString("/")
        guard let mainType = type.first else { return FileItemType.unknown }
        let subType: String? = type.count > 1 ? type[1] : nil
        
        switch mainType {
        case "inode":
            return FileItemType.directory
        case "text":
            return FileItemType.text
        case "image":
            if subType == "gif" {
                return FileItemType.animatedImage
            }
            return FileItemType.staticImage
        case "audio":
            return FileItemType.audio
        case "video":
            return FileItemType.video
            
        default:
            return FileItemType.unknown
        }
    }
    
}

// Enum with a case for every properties of the ManagedObject
// Prevents using strings for keyPaths (e.g in predicates or sort descriptors)
extension FileItem: KeyCodable {
    enum Key: String {
        case id
        case type
        case name
        case path
        case size
        case favorite
        case root
        case children
        case parent
        case initial
    }
}