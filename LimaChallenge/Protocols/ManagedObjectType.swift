//
//  ManagedObjectType.swift
//  friendscode
//
//  Created by Paul Ulric on 21/06/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation
import CoreData

protocol ManagedObjectType {
    // Generates a string from the name of the ManagedObject class
    // Prevents using strings when using entity names
    static var entityName: String { get }
}

extension ManagedObjectType where Self: NSManagedObject {
    static var entityName: String {
        get {
            return String(self)
        }
    }
}
