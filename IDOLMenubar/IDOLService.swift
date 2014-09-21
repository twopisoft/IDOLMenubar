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
    
    typealias FileMeta = (path:String,name:String,isDir:Bool)
    
    class var sharedInstance : IDOLService {
    struct Singleton {
        static let instance = IDOLService()
        }
        return Singleton.instance
    }
    
    private struct URLS {
        static let listIndexUrl = "https://api.idolondemand.com/1/api/async/listindexes/v1?apikey="
        static let jobResult = "https://api.idolondemand.com/1/job/result/"
        static let addToIndexUrl = "https://api.idolondemand.com/1/api/async/addtotextindex/v1"
    }
    
    struct ErrCodes {
        static let ErrAPIKeyNotFound = -1000
    }
    
    func fetchIndexList(completionHandler handler: ((NSData?,NSError?)->Void)) {
    
        let apiKey = NSUserDefaults.standardUserDefaults().valueForKey("idolApiKey") as? String
        
        var err : NSError? = nil
        
        if apiKey == nil {
            err = NSError(domain: "IDOLService", code: ErrCodes.ErrAPIKeyNotFound, userInfo: ["Description":"IDOL API Not Found"])
            handler(nil,err)
        } else {
            submitAsyncJob(URLS.listIndexUrl + apiKey!, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
                
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
    
    func uploadDocsToIndex(dirPath : String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        let apiKey = NSUserDefaults.standardUserDefaults().valueForKey("idolApiKey") as? String
        
        if apiKey == nil {
            let err : NSError? = NSError(domain: "IDOLService", code: ErrCodes.ErrAPIKeyNotFound, userInfo: ["Description":"IDOL API Not Found"])
            if handler != nil {
                handler!(nil,err)
            }
        } else {
            let fileMeta = getFileMeta(dirPath)
            let postRequest = createAddIndexRequest(fileMeta, indexName: indexName, apiKey: apiKey!)
            
            submitAsyncJob(postRequest, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
                
                if jobErr == nil {
                    let urlStr = URLS.jobResult + jobId! + "?apikey=" + apiKey!
                    let request = NSURLRequest(URL: NSURL(string: urlStr))
                    let queue = NSOperationQueue()
                    
                    
                    NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                        
                        handler!(data,error)
                        
                    })
                } else {
                    handler!(nil, jobErr)
                }
            })
        }
    }
    
    private func submitAsyncJob(request : NSURLRequest, completionHandler handler: ((NSString?,NSError?)->Void)) {
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            
            if error == nil {
                var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                NSLog("j1=\(json)")
                if let jobId = json["jobID"] as? String {
                    handler(jobId,nil)
                }
            } else {
                handler(nil,error)
            }
            
        })
    }
    
    private func submitAsyncJob(url : String, completionHandler handler: ((NSString?,NSError?)->Void)) {
        let request = NSURLRequest(URL: NSURL(string: url))
        submitAsyncJob(request, completionHandler: handler)
    }
    
    private func getFileMeta(dirPath: String) -> [FileMeta] {
        var fileMeta : [FileMeta] = []
        
        let dirUrl = NSURL(fileURLWithPath: dirPath, isDirectory: true)
        let dirIter = NSFileManager.defaultManager().enumeratorAtURL(dirUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
        
        while let url = dirIter.nextObject() as? NSURL {
            var path : AnyObject? = nil
            url.getResourceValue(&path, forKey: NSURLPathKey, error: nil)
            var fname : AnyObject? = nil
            url.getResourceValue(&fname, forKey: NSURLNameKey, error: nil)
            var isDir : AnyObject? = nil
            url.getResourceValue(&isDir, forKey: NSURLIsDirectoryKey, error: nil)
            fileMeta.append((path as String,fname as String,isDir as Bool))
        }
        return fileMeta
    }
    
    private func createAddIndexRequest(fileMeta: [FileMeta], indexName: String, apiKey: String) -> NSURLRequest {
        
        let reqUrl = NSURL(string: URLS.addToIndexUrl)
        var req = NSMutableURLRequest(URL: reqUrl)
        let boundary = "---------------------------14737809831466499882746641449"
        req.HTTPMethod = "POST"
        req.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let sepData = stringToData("\r\n--\(boundary)\r\n")
        let ctData = stringToData("Content-Type: application/x-www-form-urlencoded\r\n\r\n")
        
        var postData = NSMutableData()
        
        for (path,fname,isDir) in fileMeta {
            if !isDir {
                NSLog("Processing file=\(fname)")
                let fileData = NSFileManager.defaultManager().contentsAtPath(path)
                postData.appendData(sepData)
                postData.appendData(stringToData("Content-Disposition: form-data; name=\"file\"; filename=\"\(fname)\"\r\n"))
                postData.appendData(ctData)
                postData.appendData(fileData!)
            }
        }
        
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"index\"\r\n\r\n"))
        postData.appendData(stringToData(indexName))
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"apikey\"\r\n\r\n"))
        postData.appendData(stringToData(apiKey))
        /*postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"additional_metadata\"\r\n\r\n"))
        postData.appendData(stringToData(" \r\n"))
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"reference_prefix\"\r\n\r\n"))
        postData.appendData(stringToData(" \r\n"))*/
        postData.appendData(stringToData("\r\n--\(boundary)--\r\n"))
        
        req.HTTPBody = postData
        req.addValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        return req
    }
    
    private func stringToData(str : String) -> NSData {
        return (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
}