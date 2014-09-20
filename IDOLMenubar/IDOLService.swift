//
//  IDOLService.swift
//  IDOLMenubar
//
//  Created by TwoPi on 19/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

class IDOLService {
    
    class var sharedInstance : IDOLService {
    struct Singleton {
        static let instance = IDOLService()
        }
        return Singleton.instance
    }
    
    private struct URLS {
        static let listIndexUrl = "https://api.idolondemand.com/1/api/sync/listindexes/v1?apikey="
    }
    
    private lazy var apiKeyDict : Dictionary<String,String> = {
        return [ : ]
    }()
    
    private var defaultKey : String? = nil
    
    func registerApiKey(apiKey : String, friendlyName : String, isDefault : Bool = true) -> String? {
        if isDefault {
            defaultKey = apiKey
        }
        
        if let oldValue = self.apiKeyDict.updateValue(apiKey, forKey: friendlyName) {
            return oldValue
        }
        return nil
    }
    
    func fetchIndexList(managedObjectContext:NSManagedObjectContext?=nil, friendlyKeyName:String?=nil) -> NSError? {
        
        if friendlyKeyName == nil {
            assert (defaultKey != nil, "You must have register a default api key when friendlyName == nil")
        } else {
           assert (self.apiKeyDict[friendlyKeyName!] != nil, "No API Key registered with the friendlyKeyName (\(friendlyKeyName!)) provided")
        }
        
        let apiKey = friendlyKeyName == nil ? defaultKey! : self.apiKeyDict[friendlyKeyName!]
        let urlStr = URLS.listIndexUrl + apiKey!
        let request = NSURLRequest(URL: NSURL(string: urlStr))
        var response : AutoreleasingUnsafeMutablePointer<NSURLResponse?> = nil
        var reqError : NSError? = nil
        
        
        let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: response, error: &reqError)
        
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        if reqError == nil {
            
        }
        NSLog("jsonResult=\(json)")
        
        return reqError
    }
}