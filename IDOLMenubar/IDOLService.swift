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
    
    typealias FileMeta          = (path:String,name:String,isDir:Bool)
    typealias ResponseHandler   = (data:NSData?, error:NSError?) -> ()
    typealias JobRespHandler    = (jobId:String?, jobError:NSError?) -> ()
    
    class var sharedInstance : IDOLService {
    struct Singleton {
        static let instance = IDOLService()
        }
        return Singleton.instance
    }
    
    // URL strings for various IDOL services
    private struct _URLS {
        static let baseURL          = "https://api.idolondemand.com/1"
        static let asyncSvc         = baseURL + "/api/async"
        static let listIndexUrl     = asyncSvc + "/listindexes/v1?apikey="
        static let addToIndexUrl    = asyncSvc + "/addtotextindex/v1"
        static let findSimilarUrl   = asyncSvc + "/findsimilar/v1"
        static let jobResult        = baseURL + "/job/result/"
    }
    
    struct ErrCodes {
        static let ErrUnknown           = -10000
        static let ErrAPIKeyNotFound    = -10001
        static let ErrMethodFailed      = -10002
        static let ErrAPIKeyInvalid     = -10003
    }
    
    private let Boundary = "---------------------------" + NSUUID.UUID().UUIDString
    
    // MARK: - IDOL Service
    // Method to invoke List Index service and get back the results to caller in a completion handler
    
    func fetchIndexList(apiKey:String, completionHandler handler: ResponseHandler?) {
        // First submit the async job and get back the job id
        submitAsyncJob(_URLS.listIndexUrl + apiKey, completionHandler: { (jobId: String?,jobErr: NSError?) in
            // Then process the job result
            self.processJobResult(apiKey, jobId: jobId, jobErr: jobErr, handler)
        })
    }
    
    // Method to upload documents to an IDOL index using the Add to Index service
    func uploadDocsToIndex(apiKey:String, dirPath : String, indexName: String, completionHandler handler: ResponseHandler?) {
        
        // Dipatch the request on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            // First get all the files that need to be uploaded
            let fileMeta = self.getFileMeta(dirPath)
            
            // Then create an HTTP POST request containing file data
            let postRequest = self.createAddIndexRequest(fileMeta, dirPath: dirPath, indexName: indexName, apiKey: apiKey)
            
            // Submit the async job
            self.submitAsyncJob(postRequest, completionHandler: { (jobId: String?,jobErr: NSError?) in
                // Then process the job result
                self.processJobResult(apiKey, jobId: jobId, jobErr: jobErr, handler: handler)
            })
        })
    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a keyword term
    func findSimilarDocs(apiKey:String, text: String, indexName: String, completionHandler handler: ResponseHandler?) {
        
        // For keyword term search, we make use of HTTP GET request
        var urlStr = _URLS.findSimilarUrl + "?apikey=" + apiKey + "&text=" + encodeStr(text) + "&indexes=" + encodeStr(indexName) +
                     "&print=reference"
        
        var request = NSURLRequest(URL: NSURL(string: urlStr))
        
        NSLog("findSimilarDocs: text=\(text), indexName=\(indexName)")
        findSimilarDocs(apiKey, request: request, completionHandler: handler)
    }

    // Method to invoke IDOL Find Similar Documents API when user has provided a url
    func findSimilarDocsUrl(apiKey:String, url: String, indexName: String, completionHandler handler: ResponseHandler?) {
    
        // For keyword term search, we make use of HTTP GET request
        var urlStr = _URLS.findSimilarUrl + "?apikey=" + apiKey + "&url=" + encodeStr(url) + "&indexes=" + encodeStr(indexName) +
        "&print=reference"
        
        var request = NSURLRequest(URL: NSURL(string: urlStr))
        
        NSLog("findSimilarDocsUrl: url=\(url), indexName=\(indexName)")
        findSimilarDocs(apiKey, request: request, completionHandler: handler)

    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a file
    func findSimilarDocsFile(apiKey:String, fileName: String, indexName: String, completionHandler handler: ResponseHandler?) {
        
        // For file requests, create a HTTP POST request
        var request = createFindSimilarFileRequest(fileName, indexName: indexName, apiKey: apiKey)
        
        NSLog("findSimilarDocsFile: url=\(fileName), indexName=\(indexName)")
        findSimilarDocs(apiKey, request: request, completionHandler: handler)

    }

    // MARK: Helper methods
    // MARK: Request creation and submission
    
    // Common method used by all the findSimilar* methods
    private func findSimilarDocs(apiKey:String, request : NSURLRequest, completionHandler handler: ResponseHandler?) {
        
        // Submit async job
        submitAsyncJob(request, completionHandler: { (jobId: String?,jobErr: NSError?) in
            // Then process the job result
            self.processJobResult(apiKey, jobId: jobId, jobErr: jobErr, handler: handler)
        })
    }
    
    private func processJobResult(apiKey:String, jobId: String?, jobErr: NSError?, handler: ResponseHandler?) {
        if handler != nil {
            if jobErr == nil {
                let urlStr = _URLS.jobResult + jobId! + "?apikey=" + apiKey
                let request = NSURLRequest(URL: NSURL(string: urlStr))
                let queue = NSOperationQueue()
                
                // Now submit for result request
                NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                    
                    if error == nil {
                        var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.convertFromNilLiteral(), error: nil) as NSDictionary
                        let actions = json["actions"] as NSArray
                        NSLog("actions=\(actions)")
                        for act in actions {
                            if let a  = act["errors"] as? NSArray {
                                let code = a[0]["error"] as Int
                                let msg = a[0]["reason"] as String
                                return handler!(data: nil,error: self.createError(code, msg: msg))
                            } else {
                                handler!(data: data,error: nil)
                            }
                        }
                    } else {
                        handler!(data: nil, error: error)
                    }
                })
            } else {
                handler!(data: nil, error: jobErr)
            }
        } else {
            NSLog("processJobResult: No response handler provided. Doing nothing...")
        }
    }
    
    // Submits an async request
    private func submitAsyncJob(request : NSURLRequest, completionHandler handler: JobRespHandler) {
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            
            if error == nil {
                var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                NSLog("j1=\(json)")
                if let jobId = json["jobID"] as? String { // Handle the jobId response
                    handler(jobId: jobId,jobError: nil)
                } else if json["details"] != nil {  // Handle the error response
                    handler(jobId: nil,jobError: self.createError(json))
                }
            } else {
                NSLog("Job submission error: \(error)")
                handler(jobId: nil,jobError: self.createError(error))
            }
            
        })
    }
    
    // Convenience method. Mainly used for GET requests
    private func submitAsyncJob(url : String, completionHandler handler: JobRespHandler) {
        let request = NSURLRequest(URL: NSURL(string: url))
        submitAsyncJob(request, completionHandler: handler)
    }
    
    // Create a HTTP POST request for Find Similar service when user specifies a file
    private func createFindSimilarFileRequest(filePath: String, indexName: String, apiKey: String) -> NSURLRequest {
        
        var (req, postData) = initPostRequest(apiKey, reqUrlStr: _URLS.findSimilarUrl)
        
        NSLog("Processing file=\(filePath)")
        let fileData = NSFileManager.defaultManager().contentsAtPath(filePath)
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"file\"; filename=\"\(filePath)\"\r\n"))
        postData.appendData(contentTypeData())
        postData.appendData(fileData!)
        
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(contentDispositionData("indexes"))
        postData.appendData(stringToData(indexName))
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(contentDispositionData("print"))
        postData.appendData(stringToData("reference"))
        postData.appendData(stringToData("\r\n--\(Boundary)--\r\n"))
        
        req.HTTPBody = postData
        req.addValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        return req
    }

    // Create HTTP POST request for Add to Index service. This method iterates through a list
    // of files, reads their contents and appends to the post request. For a very large number of
    // *large size* files, this method may cause problems
    private func createAddIndexRequest(fileMeta: [FileMeta], dirPath: String, indexName: String, apiKey: String) -> NSURLRequest {
        
        let reqUrl = NSURL(string: _URLS.addToIndexUrl)
        var (req, postData) = initPostRequest(apiKey, reqUrlStr: _URLS.addToIndexUrl)
        
        // Note that we have used the full path for the filename because the reference_prefix sometimes
        // return strange error for some files
        for (path,fname,isDir) in fileMeta {
            if !isDir {
                NSLog("Processing file=\(fname)")
                let fileData = NSFileManager.defaultManager().contentsAtPath(path)
                postData.appendData(paramSeparatorData(Boundary))
                postData.appendData(stringToData("Content-Disposition: form-data; name=\"file\"; filename=\"\(path)\"\r\n"))
                postData.appendData(contentTypeData())
                postData.appendData(fileData!)
            }
        }
        
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"index\"\r\n\r\n"))
        postData.appendData(stringToData(indexName))
        postData.appendData(stringToData("\r\n--\(Boundary)--\r\n"))
        
        req.addValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        return req
    }
    
    // Method to initialize a POST request with common fields
    private func initPostRequest(apiKey: String, reqUrlStr: String) -> (request:NSMutableURLRequest, postData: NSMutableData) {
        let reqUrl = NSURL(string: reqUrlStr)
        var req = NSMutableURLRequest(URL: reqUrl)
        
        req.HTTPMethod = "POST"
        req.addValue("multipart/form-data; boundary=\(Boundary)", forHTTPHeaderField: "Content-Type")
        
        var postData = NSMutableData()
        
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(contentDispositionData("apikey"))
        postData.appendData(stringToData(apiKey))
        
        req.HTTPBody = postData
        return (req, postData)
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
    
    // Encode non-URL characters to URL allowed ones
    private func encodeStr(str : String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
    // Converts a string to Data
    private func stringToData(str : String) -> NSData {
        return (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    // Returns a Data for parameter Boundary string
    private func paramSeparatorData(boundary: String) -> NSData {
        return stringToData("\r\n--\(boundary)\r\n")
    }
    
    private func contentTypeData () -> NSData {
        return stringToData("Content-Type: application/x-www-form-urlencoded\r\n\r\n")
    }
    
    private func contentDispositionData(name: String) -> NSData {
        return stringToData("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
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