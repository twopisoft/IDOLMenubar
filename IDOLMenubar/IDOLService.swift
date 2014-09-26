//
//  IDOLService.swift
//  IDOLMenubar
//
//  Created by TwoPi on 19/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

// Central class for carrying out communication with HP IDOL OnDemand webservices
// Designed as a singleton.
// Completely uses async requests

class IDOLService {
    
    typealias FileMeta = (path:String,name:String,isDir:Bool)
    
    class var sharedInstance : IDOLService {
    struct Singleton {
        static let instance = IDOLService()
        }
        return Singleton.instance
    }
    
    // URL strings for various IDOL services
    private struct _URLS {
        static let baseURL          = "https://api.idolondemand.com/1/api/async"
        static let listIndexUrl     = baseURL + "/listindexes/v1?apikey="
        static let addToIndexUrl    = baseURL + "/addtotextindex/v1"
        static let findSimilarUrl   = baseURL + "/findsimilar/v1"
        static let jobResult        = "https://api.idolondemand.com/1/job/result/"
    }
    
    struct ErrCodes {
        static let ErrUnknown           = -1000
        static let ErrAPIKeyNotFound    = -1001
        static let ErrMethodFailed      = -1002
        static let ErrAPIKeyInvalid     = -1003
    }
    
    // MARK: - IDOL Service
    // Method to invoke List Index service and get back the results to caller in a completion handler
    
    func fetchIndexList(apiKey:String, completionHandler handler: ((NSData?,NSError?)->Void)) {
        // First submit the async job and get back the job id
        submitAsyncJob(_URLS.listIndexUrl + apiKey, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
            
            if jobErr == nil {
                let urlStr = _URLS.jobResult + jobId! + "?apikey=" + apiKey
                let request = NSURLRequest(URL: NSURL(string: urlStr))
                let queue = NSOperationQueue()
                
                // Now submit result request
                NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                    
                    handler(data,error)
                    
                })
            } else {
                handler(nil, jobErr)
            }
        })

    }
    
    // Method to upload documents to an IDOL index using the Add to Index service
    func uploadDocsToIndex(apiKey:String, dirPath : String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        
        // Dipatch the request on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            // First get all the files that need to be uploaded
            let fileMeta = self.getFileMeta(dirPath)
            
            // Then create an HTTP POST request containing file data
            let postRequest = self.createAddIndexRequest(fileMeta, dirPath: dirPath, indexName: indexName, apiKey: apiKey)
            
            // Submit the asyn job
            self.submitAsyncJob(postRequest, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
                
                if jobErr == nil {
                    let urlStr = _URLS.jobResult + jobId! + "?apikey=" + apiKey
                    let request = NSURLRequest(URL: NSURL(string: urlStr))
                    let queue = NSOperationQueue()
                    
                    
                    NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                        
                        handler!(data,error)
                        
                    })
                } else {
                    handler!(nil, jobErr)
                }
            })
        })
 
    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a keyword term
    func findSimilarDocs(apiKey:String, text: String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        
        // For keyword term search, we make use of HTTP GET request
        var urlStr = _URLS.findSimilarUrl + "?apikey=" + apiKey + "&text=" + encodeStr(text) + "&indexes=" + encodeStr(indexName) +
                     "&print=reference"
        
        var request = NSURLRequest(URL: NSURL(string: urlStr))
        
        NSLog("findSimilarDocs: text=\(text), indexName=\(indexName)")
        findSimilarDocs(request, key: apiKey, completionHandler: handler)
    }

    // Method to invoke IDOL Find Similar Documents API when user has provided a url
    func findSimilarDocsUrl(apiKey:String, url: String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
    
        // For keyword term search, we make use of HTTP GET request
        var urlStr = _URLS.findSimilarUrl + "?apikey=" + apiKey + "&url=" + encodeStr(url) + "&indexes=" + encodeStr(indexName) +
        "&print=reference"
        
        var request = NSURLRequest(URL: NSURL(string: urlStr))
        
        NSLog("findSimilarDocsUrl: url=\(url), indexName=\(indexName)")
        findSimilarDocs(request, key: apiKey, completionHandler: handler)

    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a file
    func findSimilarDocsFile(apiKey:String, fileName: String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        
        // For file requests, create a HTTP POST request
        var request = createFindSimilarFileRequest(fileName, indexName: indexName, apiKey: apiKey)
        
        NSLog("findSimilarDocsFile: url=\(fileName), indexName=\(indexName)")
        findSimilarDocs(request, key: apiKey, completionHandler: handler)

    }

    // MARK: Helper methods
    // MARK: Request creation and submission
    
    // Common method used by all the findSimilar* methods
    private func findSimilarDocs(request : NSURLRequest , key: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        
        // Submit async job
        submitAsyncJob(request, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
            
            if jobErr == nil {
                let urlStr = _URLS.jobResult + jobId! + "?apikey=" + key
                let request = NSURLRequest(URL: NSURL(string: urlStr))
                let queue = NSOperationQueue()
                
                // Get the results using the jobId
                NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                    
                    if error == nil {
                        var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.convertFromNilLiteral(), error: nil) as NSDictionary
                        let actions = json["actions"] as NSArray
                        NSLog("actions=\(actions)")
                        for act in actions {
                            if let a  = act["errors"] as? NSArray {
                                let code = a[0]["error"] as Int
                                let msg = a[0]["reason"] as NSString
                                return handler!(nil,self.createError(code, msg: msg))
                            } else {
                                handler!(data,nil)
                            }
                        }
                    } else {
                        handler!(data,error)
                    }
                    
                })
            } else {
                handler!(nil, jobErr)
            }
        })
    }
    
    // Submits an async request
    private func submitAsyncJob(request : NSURLRequest, completionHandler handler: ((NSString?,NSError?)->Void)) {
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            
            if error == nil {
                var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                NSLog("j1=\(json)")
                if let jobId = json["jobID"] as? String { // Handle the jobId response
                    handler(jobId,nil)
                } else if json["details"] != nil {  // Handle the error response
                    handler(nil,self.createError(json))
                }
            } else {
                NSLog("Job submission error: \(error)")
                handler(nil,self.createError(error))
            }
            
        })
    }
    
    // Convenience method. Mainly used for GET requests
    private func submitAsyncJob(url : String, completionHandler handler: ((NSString?,NSError?)->Void)) {
        let request = NSURLRequest(URL: NSURL(string: url))
        submitAsyncJob(request, completionHandler: handler)
    }
    
    // Create a HTTP POST request for Find Similar service when user specifies a file
    private func createFindSimilarFileRequest(filePath: String, indexName: String, apiKey: String) -> NSURLRequest {
        let reqUrl = NSURL(string: _URLS.findSimilarUrl)
        var req = NSMutableURLRequest(URL: reqUrl)
        let boundary = "---------------------------14737809831466499882746641449"
        req.HTTPMethod = "POST"
        req.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let sepData = stringToData("\r\n--\(boundary)\r\n")
        let ctData = stringToData("Content-Type: application/x-www-form-urlencoded\r\n\r\n")
        
        var postData = NSMutableData()
        
        NSLog("Processing file=\(filePath)")
        let fileData = NSFileManager.defaultManager().contentsAtPath(filePath)
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"file\"; filename=\"\(filePath)\"\r\n"))
        postData.appendData(ctData)
        postData.appendData(fileData!)
        
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"indexes\"\r\n\r\n"))
        postData.appendData(stringToData(indexName))
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"print\"\r\n\r\n"))
        postData.appendData(stringToData("reference"))
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"apikey\"\r\n\r\n"))
        postData.appendData(stringToData(apiKey))
        postData.appendData(stringToData("\r\n--\(boundary)--\r\n"))
        
        req.HTTPBody = postData
        req.addValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        return req
    }

    // Create HTTP POST request for Add to Index service. This method iterates through a list
    // of files, reads their contents and appends to the post request. For a very large number of
    // *large size* files, this method may cause problems
    private func createAddIndexRequest(fileMeta: [FileMeta], dirPath: String, indexName: String, apiKey: String) -> NSURLRequest {
        
        let reqUrl = NSURL(string: _URLS.addToIndexUrl)
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
                postData.appendData(stringToData("Content-Disposition: form-data; name=\"file\"; filename=\"\(path)\"\r\n"))
                postData.appendData(ctData)
                postData.appendData(fileData!)
            }
        }
        
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"index\"\r\n\r\n"))
        postData.appendData(stringToData(indexName))
        /*postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"reference_prefix\"\r\n\r\n"))
        postData.appendData(stringToData(dirPath))*/
        postData.appendData(sepData)
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"apikey\"\r\n\r\n"))
        postData.appendData(stringToData(apiKey))
        postData.appendData(stringToData("\r\n--\(boundary)--\r\n"))
        
        req.HTTPBody = postData
        req.addValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        return req
    }
    
    // MARK: Method to read directory and file info
    private func getFileMeta(dirPath: String) -> [FileMeta] {
        var fileMeta : [FileMeta] = []
        
        // Get all director contents. Recursively descend to subdirectories
        let dirUrl = NSURL(fileURLWithPath: dirPath, isDirectory: true)
        let dirIter = NSFileManager.defaultManager().enumeratorAtURL(dirUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
        
        // Iterate through all files and get their path, name and type (dir or not) info
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
    
    // MARK: Miscellaneous methods
    
    private func encodeStr(str : String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
    private func stringToData(str : String) -> NSData {
        return (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    private func createError(json : NSDictionary) -> NSError {
        let detail = json["details"] as? NSDictionary
        
        var msg = "Unknown Error"
        if var code = json["error"] as? Int {
            if code == -1012 {
                msg = "Operation Failed.\nPossible reason: Invalid API Key"
            } else {
                if let d = detail!["reason"] as? String {
                    msg = d
                } else {
                    if let m = json["message"] as? String {
                        msg = json["message"] as String
                    } else {
                        if let r = json["reason"] as? String {
                            msg = r
                        }
                    }
                }
            }
            return createError(code, msg: msg)
        }
        
        return createError(ErrCodes.ErrUnknown, msg: msg)
    }
    
    private func createError(error: NSError) -> NSError {
        if error.code == -1012 {
            return createError(error.code, msg: "Operation Failed.\nPossible reason: Invalid API Key")
        }
        
        return error
    }
    
    private func createError(code: Int, msg: String) -> NSError {
       return NSError(domain: "IDOLService", code: code, userInfo: ["Description":msg])
    }
}