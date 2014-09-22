//
//  SearchViewController.swift
//  SwiftIDOLMenubar
//
//  Created by TwoPi on 5/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

class SearchResultEntry : NSObject {
    var title : String = ""
    var reference : String = ""
    var score : Double = 0.0
    
    init(title: String, reference: String, score: Double) {
        self.title = title
        self.reference = reference
        self.score = score
    }
}

class SearchViewController: NSViewController {
 
    var managedObjectContext : NSManagedObjectContext!
    
    @IBOutlet weak var searchBarField: NSTextField!
    
    @IBOutlet weak var indexNameField: NSTextField!
    
    @IBOutlet weak var resultsTableView: NSTableView!
    
    @IBOutlet var userDefaultsController: NSUserDefaultsController!
    
    var isSearching = false
    
    var sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "title", ascending: true, selector: "compare:"),
                                         NSSortDescriptor(key: "reference",ascending: true, selector: "compare:"),
                                         NSSortDescriptor(key: "score",ascending: false, selector: "compare:")]
    
    //var results : [SearchResultEntry] = [SearchResultEntry(title: "Test", reference: "ABC", score: 89.9),
    //                                     SearchResultEntry(title: "ABC", reference: "Test", score: 45.5)]
    
    var results : [SearchResultEntry] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func close(sender: AnyObject) {
        parentWindow()!.close()
    }
    
    @IBAction func selectIndex(sender: AnyObject) {
        let apiKey = userDefaultsController.values.valueForKey("idolApiKey") as? String
        if apiKey == nil  {
            ErrorReporter.showErrorAlert(parentWindow(),
                title: "IDOL API Key not configured",
                desc: "IDOL API Key is not configured. Please set the API Key first.")
        } else {
            showSelectIndexPanel(apiKey)
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
    
    @IBAction func search(sender: AnyObject) {
        var searchItem = searchBarField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var indexName = indexNameField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if !searchItem.isEmpty {
            if indexName.isEmpty {
                indexName = "wiki_eng"
            }
            self.setValue(true, forKey: "isSearching")
            
            if searchItem.hasPrefix("@file=") {
                var fileName = searchItem.substringFromIndex(searchItem.rangeOfString("@file=")!.endIndex)
                IDOLService.sharedInstance.findSimilarDocsFile(fileName, indexName: indexName, completionHandler: { (data: NSData?, err: NSError?) in
                    
                    self.handleSearchResults(data, err: err)
                })
            } else if isUrl(searchItem) {
                IDOLService.sharedInstance.findSimilarDocsUrl(searchItem, indexName: indexName, completionHandler: { (data: NSData?, err: NSError?) in
                    
                    self.handleSearchResults(data, err: err)
                })
            } else {
                IDOLService.sharedInstance.findSimilarDocs(searchItem, indexName: indexName, completionHandler: { (data: NSData?, err: NSError?) in
                    
                    self.handleSearchResults(data, err: err)
                })
            }
        }
        
    }
    
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
                        let title = doc["title"] as String
                        let reference = doc["reference"] as String
                        let score = doc["weight"] as Double
                        let entry = SearchResultEntry(title: title, reference: reference, score: score)
                        newResult.append(entry)
                    }
                    self.setValue(newResult, forKey: "results")
                }
            } else {
                NSLog("err=\(err)")
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
    
}
