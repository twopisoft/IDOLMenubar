//
//  DBHelper.swift
//  IDOLMenubar
//
//  Created by TwoPi on 20/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

class DBHelper {
    
    typealias IndexTuple = (name:String,flavor:String,isPublic:Bool,info:String)
    
    class func updateIndexes(managedObjectContext : NSManagedObjectContext, data : [IndexTuple]) -> NSError? {
        var foundObjs :[Int:IndexTuple] = [:]
        
        var freq = NSFetchRequest(entityName: "IdolIndexes")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil)
        
        for mo in res {
            var found = false
            for (i,entry) in enumerate(data) {
                let (indexName,indexFlavor,isPublic,indexInfo) = entry
                
                if mo.name == indexName {
                    found = true
                    mo.setValue(indexFlavor, forKey: "flavor")
                    mo.setValue(isPublic, forKey: "isPublic")
                    mo.setValue(indexInfo, forKey: "info")
                    foundObjs[i]=entry
                }
            }
            
            if !found {
                managedObjectContext.deleteObject(mo as NSManagedObject)
            }
        }
        
        var newData : [IndexTuple] = []
        for (i,entry) in enumerate(data) {
            if foundObjs[i] == nil {
                newData.append(entry)
            }
        }
        //NSLog("newData=\(newData)")
        
        for newEntry in newData {
            let (indexName,indexFlavor,isPublic,indexInfo) = newEntry
            let obj = IdolIndexes(entity: NSEntityDescription.entityForName("IdolIndexes", inManagedObjectContext: managedObjectContext), insertIntoManagedObjectContext: managedObjectContext)
            obj.setValue(indexName, forKey: "name")
            obj.setValue(indexFlavor, forKey: "flavor")
            obj.setValue(isPublic, forKey: "isPublic")
            obj.setValue(indexInfo, forKey: "info")
        }
        
        return nil
    }
}
