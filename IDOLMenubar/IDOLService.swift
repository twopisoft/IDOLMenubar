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
    
    struct ErrCodes {
        static let ErrAPIKeyNotFound = -1000
    }
    
    func fetchIndexList(completionHandler handler: ((NSData?,NSError?)->Void)) {
    
        let apiKey = NSUserDefaults.standardUserDefaults().valueForKey("idolApiKey") as? String
        
        if apiKey == nil {
            let err : NSError? = NSError(domain: "IDOLService", code: ErrCodes.ErrAPIKeyNotFound, userInfo: ["Description":"IDOL API Not Found"])
            handler(nil,err)
        } else {
            let urlStr = URLS.listIndexUrl + apiKey!
            let request = NSURLRequest(URL: NSURL(string: urlStr))
            let queue = NSOperationQueue()
            
            
            NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                
                handler(data,error)
                
            })
        }
    }
}