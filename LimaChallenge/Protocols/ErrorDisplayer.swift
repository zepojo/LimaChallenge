//
//  ErrorDisplayer.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 30/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation
import UIKit

protocol ErrorDisplayer {
    func displayError(error: NSError)
    func displayError(message: String)
}

extension ErrorDisplayer where Self: UIViewController {
 
    func displayError(message: String) {
        dispatch_async(dispatch_get_main_queue()) { 
            let alert = UIAlertController(title: "An error occured", message: message, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func displayError(error: NSError) {
        self.displayError(error.localizedDescription)
    }
    
}