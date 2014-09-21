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
        static let listIndexUrl = "https://api.idolondemand.com/1/api/async/listindexes/v1?apikey="
        static let jobResult = "https://api.idolondemand.com/1/job/result/"
    }
    
    struct ErrCodes {
        static let ErrAPIKeyNotFound = -1000
    }
    
    private func submitAsyncOp(url : String, completionHandler handler: ((NSString?,NSError?)->Void)) {
        let request = NSURLRequest(URL: NSURL(string: url))
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            
            if error == nil {
                var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                
                if let jobId = json["jobID"] as? String {
                    handler(jobId,nil)
                }
            } else {
                handler(nil,error)
            }
            
        })
    }
    
    func fetchIndexList(completionHandler handler: ((NSData?,NSError?)->Void)) {
    
        let apiKey = NSUserDefaults.standardUserDefaults().valueForKey("idolApiKey") as? String
        
        var err : NSError? = nil
        
        if apiKey == nil {
            err = NSError(domain: "IDOLService", code: ErrCodes.ErrAPIKeyNotFound, userInfo: ["Description":"IDOL API Not Found"])
            handler(nil,err)
        } else {
            submitAsyncOp(URLS.listIndexUrl + apiKey!, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
                
                if jobErr == nil {
                    let urlStr = URLS.jobResult + jobId! + "?apikey=" + apiKey!
                    let request = NSURLRequest(URL: NSURL(string: urlStr))
                    let queue = NSOperationQueue()
                    
                    
                    NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                        
                        handler(data,error)
                        
                    })
                } else {
                    handler(nil, jobErr)
                }
            })
        }
    }
    
    func uploadDocsToIndex(docPaths : [String], completionHandler handler: ((NSData?,NSError?)->Void)) {
        let apiKey = NSUserDefaults.standardUserDefaults().valueForKey("idolApiKey") as? String
        
        if apiKey == nil {
            let err : NSError? = NSError(domain: "IDOLService", code: ErrCodes.ErrAPIKeyNotFound, userInfo: ["Description":"IDOL API Not Found"])
            handler(nil,err)
        } else {
        }
    }
    
}