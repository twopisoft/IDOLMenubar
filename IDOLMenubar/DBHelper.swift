//
//  DBHelper.swift
//  IDOLMenubar
//
//  Created by TwoPi on 20/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

// Central class for carrying out Core Data operations
// Only provides class level ops

class DBHelper {
    
    // MARK: Typealiases
    // Tuple for index info
    typealias IndexTuple = (name:String,flavor:String,isPublic:Bool,info:String)
    
    // MARK: Data handlers for index information
    
    // Update index data. This involves:
    // 1. From the data coming in from List Index service, find what indexes are updated
    // 2. And which of the indexes have been deleted
    // 3. Finally, add the new index entries
    class func updateIndexes(managedObjectContext : NSManagedObjectContext, data : [IndexTuple]) -> NSError? {
        var foundObjs :[Int:IndexTuple] = [:]
        
        var freq = NSFetchRequest(entityName: "IdolIndexes")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil)
        
        for mo in res {
            var found = false
            for (i,entry) in enumerate(data) {
                let (indexName,indexFlavor,isPublic,indexInfo) = entry
                
                // First update existing indexes info
                if mo.name == indexName {
                    found = true
                    mo.setValue(indexFlavor, forKey: "flavor")
                    mo.setValue(isPublic, forKey: "isPublic")
                    mo.setValue(indexInfo, forKey: "info")
                    foundObjs[i]=entry
                }
            }
            
            // Delete the ones, that no longer exist on the server
            if !found {
                managedObjectContext.deleteObject(mo as NSManagedObject)
            }
        }
        
        // Finally, add the new index entries
        var newData : [IndexTuple] = []
        for (i,entry) in enumerate(data) {
            if foundObjs[i] == nil {
                newData.append(entry)
            }
        }
        
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
    
    // Determine if there is any data stored. Useful to determine whether to run a 
    // auto refresh when SelectIndexPanel is shown
    class func hasIndexList(managedObjectContext: NSManagedObjectContext) -> Bool {
        var freq = NSFetchRequest(entityName: "IdolIndexes")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil)
        
        return res.count > 0
    }
    
    // MARK: Data handler for Directory data
    
    // Find all the directories that have not been synced or are not in active sync
    class func getSyncReadyDirectories(managedObjectContext : NSManagedObjectContext) -> [NSManagedObject] {
        
        var syncReady : [NSManagedObject] = []
        var freq = NSFetchRequest(entityName: "IdolDirectories")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil)
        
        for mo in res {
            let (path:String?,index:String?,insync:Bool?,syncfin:Bool?) =
                                            ((mo.valueForKey("idolDirPath") as? String),
                                             (mo.valueForKey("idolIndexName") as? String),
                                             (mo.valueForKey("isSyncing") as? Bool),
                                             (mo.valueForKey("syncFinished") as? Bool))
            let notReady = (path == nil || index == nil || path!.isEmpty || index!.isEmpty || insync! || syncfin!)
            if !notReady {
                syncReady.append(mo as NSManagedObject)
            }
        }
        return syncReady
    }
}
