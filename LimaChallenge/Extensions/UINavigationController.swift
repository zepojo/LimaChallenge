//
//  UINavigationController.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 31/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    override public func shouldAutorotate() -> Bool {
        return !(self.visibleViewController is PortraitViewController)
    }
    
    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return self.visibleViewController is PortraitViewController ? .Portrait : .All
    }
    
}
