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
    private struct URLS {
        static let listIndexUrl = "https://api.idolondemand.com/1/api/async/listindexes/v1?apikey="
        static let addToIndexUrl = "https://api.idolondemand.com/1/api/async/addtotextindex/v1"
        static let findSimilarUrl = "https://api.idolondemand.com/1/api/async/findsimilar/v1"
        static let jobResult = "https://api.idolondemand.com/1/job/result/"
    }
    
    struct ErrCodes {
        static let ErrAPIKeyNotFound = -1000
        static let ErrMethodFailed   = -1001
    }
    
    // MARK: - IDOL Service
    // Method to invoke List Index service and get back the results to caller in a completion handler
    
    func fetchIndexList(completionHandler handler: ((NSData?,NSError?)->Void)) {
    
        let (key,err) = apiKey()
        
        if key == nil {
            handler(nil,err)
        } else {
            
            // First submit the async job and get back the job id
            submitAsyncJob(URLS.listIndexUrl + key!, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
                
                if jobErr == nil {
                    let urlStr = URLS.jobResult + jobId! + "?apikey=" + key!
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
    }
    
    // Method to upload documents to an IDOL index using the Add to Index service
    func uploadDocsToIndex(dirPath : String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        let (key,err) = apiKey()
        
        if key == nil {
            if handler != nil {
                handler!(nil,err)
            }
        } else {
            // Dipatch the request on a background thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                // First get all the files that need to be uploaded
                let fileMeta = self.getFileMeta(dirPath)
                
                // Then create an HTTP POST request containing file data
                let postRequest = self.createAddIndexRequest(fileMeta, dirPath: dirPath, indexName: indexName, apiKey: key!)
                
                // Submit the asyn job
                self.submitAsyncJob(postRequest, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
                    
                    if jobErr == nil {
                        let urlStr = URLS.jobResult + jobId! + "?apikey=" + key!
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
    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a keyword term
    func findSimilarDocs(text: String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        let (key,err) = apiKey()
        
        if key == nil {
            if handler != nil {
                handler!(nil,err)
            }
        } else {
            // For keyword term search, we make use of HTTP GET request
            var urlStr = URLS.findSimilarUrl + "?apikey=" + key! + "&text=" + encodeStr(text) + "&indexes=" + encodeStr(indexName) +
                         "&print=reference"
            
            var request = NSURLRequest(URL: NSURL(string: urlStr))
            
            NSLog("findSimilarDocs: text=\(text), indexName=\(indexName)")
            findSimilarDocs(request, key: key!, completionHandler: handler)
        }
    }

    // Method to invoke IDOL Find Similar Documents API when user has provided a url
    func findSimilarDocsUrl(url: String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        let (key,err) = apiKey()
        
        if key == nil {
            if handler != nil {
                handler!(nil,err)
            }
        } else {
            // For keyword term search, we make use of HTTP GET request
            var urlStr = URLS.findSimilarUrl + "?apikey=" + key! + "&url=" + encodeStr(url) + "&indexes=" + encodeStr(indexName) +
            "&print=reference"
            
            var request = NSURLRequest(URL: NSURL(string: urlStr))
            
            NSLog("findSimilarDocsUrl: url=\(url), indexName=\(indexName)")
            findSimilarDocs(request, key: key!, completionHandler: handler)
        }
    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a file
    func findSimilarDocsFile(fileName: String, indexName: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        let (key,err) = apiKey()
        
        if key == nil {
            if handler != nil {
                handler!(nil,err)
            }
        } else {
            // For file requests, create a HTTP POST request
            var request = createFindSimilarFileRequest(fileName, indexName: indexName, apiKey: key!)
            
            NSLog("findSimilarDocsFile: url=\(fileName), indexName=\(indexName)")
            findSimilarDocs(request, key: key!, completionHandler: handler)
        }
    }

    // MARK: Helper methods
    // MARK: Request creation and submission
    
    // Common method used by all the findSimilar* methods
    private func findSimilarDocs(request : NSURLRequest , key: String, completionHandler handler: ((NSData?,NSError?)->Void)?) {
        
        // Submit async job
        submitAsyncJob(request, completionHandler: { (jobId: NSString?,jobErr: NSError?) in
            
            if jobErr == nil {
                let urlStr = URLS.jobResult + jobId! + "?apikey=" + key
                let request = NSURLRequest(URL: NSURL(string: urlStr))
                let queue = NSOperationQueue()
                
                // Get the results using the jobId
                NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                    
                    handler!(data,error)
                    
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
                } else if json["error"] != nil {  // Handle the error response
                    handler(nil,self.createError(json))
                }
            } else {
                handler(nil,error)
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
        let reqUrl = NSURL(string: URLS.findSimilarUrl)
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
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"reference_prefix\"\r\n\r\n"))
        postData.appendData(stringToData(dirPath))
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
    private func apiKey() -> (String?,NSError?) {
        let key = NSUserDefaults.standardUserDefaults().valueForKey("idolApiKey") as? String
        
        if key == nil {
            return (nil, createError(ErrCodes.ErrAPIKeyNotFound, msg: "IDOL API Key Not Found"))
        }
        return (key,nil)
    }
    
    private func encodeStr(str : String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
    private func stringToData(str : String) -> NSData {
        return (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    private func createError(json : NSDictionary) -> NSError {
        let code = json["error"] as? Int
        let msg = json["reason"] as? String
        return createError(code!, msg: msg!)
    }
    
    private func createError(code: Int, msg: String) -> NSError {
       return NSError(domain: "IDOLService", code: code, userInfo: ["Description":msg])
    }
}