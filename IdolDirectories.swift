//
//  IdolDirectories.swift
//  IDOLMenubar
//
//  Created by TwoPi on 18/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

class IdolDirectories: NSManagedObject {

    @NSManaged var idolDirPath: String
    @NSManaged var idolIndexName: String
    @NSManaged var isSyncing: NSNumber

}
