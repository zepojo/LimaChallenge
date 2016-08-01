//
//  FileItem+CoreDataProperties.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 01/08/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension FileItem {

    @NSManaged var favorite: NSNumber?
    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var path: String?
    @NSManaged var root: NSNumber?
    @NSManaged var size: NSNumber?
    @NSManaged var type: NSNumber?
    @NSManaged var modificationTime: NSNumber?
    @NSManaged var children: NSSet?
    @NSManaged var parent: FileItem?

}
