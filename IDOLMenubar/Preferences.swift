//
//  Preferences.swift
//  SwiftIDOLMenubar
//
//  Created by TwoPi on 10/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation

class DirEntry : NSObject, NSCoding {
    var path  : String = ""
    var index : String = ""
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        
        path = aDecoder.decodeObjectForKey("path") as String
        index = aDecoder.decodeObjectForKey("index") as String
    }
    
    override var description : String {
        return "(\(path):\(index))"
    }
    
    init(path:String="", index:String="") {
        self.path = path
        self.index = index
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(path, forKey: "path")
        aCoder.encodeObject(index, forKey: "index")
    }
}

class Preferences : NSObject, NSCoding {
    private var prefs : [String:AnyObject] = [:]
    var dirty : Bool = false
    
    enum KeyNames {
        static var PrefsKey = "prefsKey"
        static var APIKey   = "idolApiKey"
        static var DirKey   = "idolDirs"
    }
    
    var prefsKey = KeyNames.PrefsKey
    
    var apiKey : String {
        get {
            let key: AnyObject? = prefs[KeyNames.APIKey]
            if key != nil {
                return key as String
            }
            return ""
        }
        set {
            let val = newValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            prefs[KeyNames.APIKey] = val
        }
    }
    
    override var description : String {
        var ret = "\nIDOL Preferences:\n"
        ret += "API Key: \(self.apiKey)\n"
        ret += "Directory/Index Mappings ["
        for (var i=0; i<self.dirEntryCount(); i += 1) {
            ret += "\(self.getDirEntry(i)!)"
        }
        
        ret += "]"
        return ret
    }
    
    init(prefsKey : String = KeyNames.PrefsKey) {
        super.init()
        self.prefsKey = prefsKey
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()

        prefs[KeyNames.APIKey] = aDecoder.decodeObjectForKey(KeyNames.APIKey)
        prefs[KeyNames.DirKey] = aDecoder.decodeObjectForKey(KeyNames.DirKey)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(prefs[KeyNames.APIKey]!, forKey: KeyNames.APIKey)
        aCoder.encodeObject(prefs[KeyNames.DirKey]!, forKey: KeyNames.DirKey)
    }
    
    private func getDirEntryArray() -> [DirEntry]? {
        if let obj : AnyObject? = prefs[KeyNames.DirKey] {
            return obj as? [DirEntry]
        }
        
        return nil
    }
    
    func getDirEntry(atIndex:Int) -> DirEntry? {
        
        assert(atIndex>=0, "Negative index not allowed")
        
        if let dirList = getDirEntryArray() {
            assert (atIndex < dirList.count, "Index out of bound")
            return dirList[atIndex]
        }
        
        return nil
    }
    
    func updateDirEntry(entry:DirEntry, atIndex:Int) -> DirEntry?{
        
        assert(atIndex>=0, "Negative index not allowed")
        
        dirty = true
        if var dirList = getDirEntryArray() {
            assert(atIndex < dirList.count, "Index out of bound")
            let oldEntry = dirList[atIndex]
            dirList[atIndex] = DirEntry(path: entry.path,index: entry.index)
            prefs[KeyNames.DirKey] = dirList
            return oldEntry
        } else {
            let dirList : [DirEntry] = [DirEntry(path: entry.path,index: entry.index)]
            prefs[KeyNames.DirKey] = dirList
            return nil
        }
    }
    
    func removeDirEntry(atIndex: Int) -> DirEntry? {
        assert(atIndex>=0, "Negative index not allowed")
        
        dirty = true
        if var dirList = getDirEntryArray() {
            assert(atIndex < dirList.count, "Index out of bound")
            let oldEntry = dirList[atIndex]
            dirList.removeAtIndex(atIndex)
            prefs[KeyNames.DirKey] = dirList
            return oldEntry
        }
        return nil
    }
    
    func insertDirEntry(entry:DirEntry, atIndex:Int) {
        assert(atIndex>=0, "Negative index not allowed")
        
        dirty = true
        if var dirList = getDirEntryArray() {
            assert(atIndex==0 || atIndex < dirList.count, "Index out of bound")
            dirList.insert(DirEntry(path: entry.path,index: entry.index), atIndex: atIndex)
            prefs[KeyNames.DirKey] = dirList
        } else {
            assert(atIndex==0, "Index out of bound")
            let dirList : [DirEntry] = [DirEntry(path: entry.path,index: entry.index)]
            prefs[KeyNames.DirKey] = dirList
        }
    }
    
    func dirEntryCount() -> Int {
        if let dirList = getDirEntryArray() {
            return dirList.count
        }
        
        return 0
    }
    
    func loadPreferences() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let data = defaults.objectForKey(KeyNames.PrefsKey) as? NSData {
            prefs = NSKeyedUnarchiver.unarchiveObjectWithData(data) as [String:AnyObject]
        }
    }
    
    func savePreferences() {
        var defaults = NSUserDefaults.standardUserDefaults()
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(prefs)
        defaults.setObject(data, forKey: KeyNames.PrefsKey)
        defaults.synchronize()
        dirty = false
    }
    
    
}