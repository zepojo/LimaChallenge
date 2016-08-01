//
//  KeyCodable.swift
//  friendscode
//
//  Created by Paul Ulric on 21/06/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import Foundation

protocol KeyCodable {
    associatedtype Key: RawRepresentable
}