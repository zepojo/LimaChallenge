//
//  NSManagedObjectContext.swift
//  friendscode
//
//  Created by Paul Ulric on 21/06/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    // Helper to create a new object by inferring its entity from the type of the variable it will be assigned to
    // Prevents using entity names as String (not safe)
    func insertObject<A: NSManagedObject where A: ManagedObjectType>() -> A {
        guard let obj = NSEntityDescription.insertNewObjectForEntityForName(A.entityName, inManagedObjectContext: self) as? A else {
            fatalError("Entity \(A.entityName) does not correspond to \(A.self)")
        }
        return obj
    }
    
    func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch {
            print("Error while saving data: \(error)")
            rollback()
            return false
        }
    }
}