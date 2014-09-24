//
//  IdolIndexes.swift
//  IDOLMenubar
//
//  Created by TwoPi on 18/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

class IdolIndexes: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var isPublic: NSNumber
    @NSManaged var info: String
    @NSManaged var flavor: String

}
