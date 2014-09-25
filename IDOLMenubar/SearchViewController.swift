//
//  SearchViewController.swift
//  SwiftIDOLMenubar
//
//  Created by TwoPi on 5/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

// Search result entry class used by array controller
class SearchResultEntry : NSObject, NSTextFieldDelegate {
    var title : String = ""
    var reference : String = ""
    var score : Double = 0.0
    
    init(title: String, reference: String, score: Double) {
        self.title = title
        self.reference = reference
        self.score = score
    }
}

// Controller class for SearchView panel
class SearchViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
 
    // MARK: Properties
    var managedObjectContext : NSManagedObjectContext!
    
    @IBOutlet weak var searchBarField: NSTextField!
    
    @IBOutlet weak var indexNameField: NSTextField!
    
    @IBOutlet weak var resultsTableView: NSTableView!
    
    @IBOutlet var userDefaultsController: NSUserDefaultsController!
    
    var isSearching = false
    
    var sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "score",ascending: false, selector: "compare:"),
                                         NSSortDescriptor(key: "title", ascending: true, selector: "compare:"),
                                         NSSortDescriptor(key: "reference",ascending: true, selector: "compare:")]
    
    var results : [SearchResultEntry] = []
    
    private var _apiKey : String? = nil
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK: Action methods
    @IBAction func close(sender: AnyObject) {
        parentWindow()!.orderBack(sender)
        parentWindow()!.close()
    }
    
    @IBAction func selectIndex(sender: AnyObject) {
        _apiKey = userDefaultsController.values.valueForKey("idolApiKey") as? String
        
        if _apiKey == nil  {
            ErrorReporter.showErrorAlert(parentWindow(),
                title: "IDOL API Key not configured",
                desc: "IDOL API Key is not configured. Please set the API Key first.")
        } else {
            showSelectIndexPanel(_apiKey)
        }
    }
    
    @IBAction func selectFile(sender: AnyObject) {
        var panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.beginSheetModalForWindow(parentWindow(), completionHandler: { (response : NSModalResponse) in
            if response == NSOKButton {
                self.searchBarField.stringValue = "@file=\(panel.URL!.path!)"
            }
        })
    }
    
    // Invokes search. Depending on what user specified, calls the appropriate method in IDOLService
    // URLs are detected by using a regex. File entries must start with a @file= token
    
    @IBAction func search(sender: AnyObject) {
        _apiKey = userDefaultsController.values.valueForKey("idolApiKey") as? String
        
        if _apiKey == nil  {
            ErrorReporter.showErrorAlert(parentWindow(),
                title: "IDOL API Key not configured",
                desc: "IDOL API Key is not configured. Please set the API Key first.")
        } else {
            var searchItem = searchBarField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            var indexName = indexNameField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            if !searchItem.isEmpty {
                if indexName.isEmpty {
                    indexName = "wiki_eng"
                }
                self.setValue(true, forKey: "isSearching")
                
                if searchItem.hasPrefix("@file=") { // File based search
                    var fileName = searchItem.substringFromIndex(searchItem.rangeOfString("@file=")!.endIndex)
                    IDOLService.sharedInstance.findSimilarDocsFile(_apiKey!, fileName: fileName, indexName: indexName, completionHandler: { (data: NSData?, err: NSError?) in
                        
                        self.handleSearchResults(data, err: err)
                    })
                } else if isUrl(searchItem) { // Url based search
                    IDOLService.sharedInstance.findSimilarDocsUrl(_apiKey!, url: searchItem, indexName: indexName, completionHandler: { (data: NSData?, err: NSError?) in
                        
                        self.handleSearchResults(data, err: err)
                    })
                } else { // Keyword based search
                    IDOLService.sharedInstance.findSimilarDocs(_apiKey!, text: searchItem, indexName: indexName, completionHandler: { (data: NSData?, err: NSError?) in
                        
                        self.handleSearchResults(data, err: err)
                    })
                }
            }
        }
        
    }
    
    // Open a document when user click the disclose button
    @IBAction func openDocument(sender: AnyObject) {
        let row = resultsTableView.rowForView(sender as NSView)
        let entry = results[row]
        
        var filePath = entry.reference.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        if filePath.hasPrefix("/") {
            filePath = "file://" + filePath
        }
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: filePath))
    }
    
    // MARK: Helper
    private func handleSearchResults(data : NSData?, err: NSError?) {
        
        dispatch_async(dispatch_get_main_queue(), {
            self.setValue(false, forKey: "isSearching")
            
            if err == nil {
                let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                NSLog("results=\(json)")
                let actions = json["actions"] as NSArray
                let result = actions[0]["result"] as NSDictionary
                let documents: AnyObject? = result["documents"]
                
                if documents != nil {
                    var newResult : [SearchResultEntry] = []
                    for doc in documents! as NSArray {
                        let reference = doc["reference"] as String
                        var title = reference
                        if let t: AnyObject? = doc["title"] {
                            title = t != nil ? t as String : ""
                        }
                        let score = doc["weight"] as Double
                        let entry = SearchResultEntry(title: title, reference: reference, score: score)
                        newResult.append(entry)
                    }
                    self.setValue(newResult, forKey: "results")
                }
            } else {
                NSLog("err=\(err)")
                ErrorReporter.showErrorAlert(self.parentWindow()!, error: err!)
            }
        })
    }
    
    private func isUrl(str : String) -> Bool {
        let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        let urlTest = NSPredicate(format: "SELF MATCHES %@", urlRegEx)
        return urlTest.evaluateWithObject(str)
    }
    
    private func showSelectIndexPanel(apiKey : String!) {
        var panel = SelectIndexPanel()
        panel.managedObjectContext = self.managedObjectContext
        panel.apiKey = apiKey
        
        panel.beginSheetModalForWindow(parentWindow()!, completionHandler: { (response : NSModalResponse) in
            if response == NSOKButton {
                let selectedIndex = panel.selectedIndex
                self.indexNameField.stringValue = selectedIndex!.name
            }
        })
    }
    
    private func parentWindow() -> NSWindow? {
        return self.view.superview?.window
    }
    
    private func encodeStr(str : String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
}
