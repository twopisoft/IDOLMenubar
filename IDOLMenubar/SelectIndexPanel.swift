//
//  SelectIndexPanel.swift
//  IDOLMenubar
//
//  Created by TwoPi on 20/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

// Controller class for Index select panel

class SelectIndexPanel : NSObject {
    
    // MARK: Properties
    
    // Optional user defined handler, to be called when panel closes
    private var _handler : ((NSModalResponse) -> Void)! = nil
    
    @IBOutlet var indexArrayController: NSArrayController!
    @IBOutlet var selectIndexPanel: NSPanel!
    
    var managedObjectContext : NSManagedObjectContext! = nil
    var isRefreshing : Bool = false
    var apiKey : String? = nil
    var listPublicIndex : Bool = true
    var selectedIndex : DBHelper.IndexTuple? = nil
    
    var sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "name", ascending: true, selector: "compare:")]
    
    var filterPredicate : NSPredicate? = nil
    
    // MARK: NSObject methods
    
    override func awakeFromNib() {
        // Do an auto refresh if we do not have any index data
        if !DBHelper.hasIndexList(managedObjectContext) {
            refresh(self)
        }
    }
    
    // MARK: Select panel management
    
    // Show the sheet as modal
    func beginSheetModalForWindow(_window : NSWindow!, completionHandler handler: ((NSModalResponse) -> Void)!) {
        
        if selectIndexPanel == nil {
            NSBundle.mainBundle().loadNibNamed("SelectIndexSheet", owner: self, topLevelObjects: nil)
        }
        
        self._handler = handler
        indexArrayController.filterPredicate = !listPublicIndex ? NSPredicate(format: "isPublic=%@", argumentArray: [listPublicIndex]) : nil
        
        NSApplication.sharedApplication().beginSheet(selectIndexPanel, modalForWindow: _window!, modalDelegate: self, didEndSelector: nil, contextInfo: nil)
    }
    
    // Cancel action
    @IBAction func cancel(sender: AnyObject) {
        selectedIndex = nil
        
        if _handler != nil {
            _handler(NSCancelButton)
        }
        closeSheet()
    }
    
    // Select action
    @IBAction func select(sender: AnyObject) {
        let indexName = indexArrayController.valueForKeyPath("selection.name") as? String
        let indexFlavor = indexArrayController.valueForKeyPath("selection.flavor") as? String
        let indexIsPublic = indexArrayController.valueForKeyPath("selection.isPublic") as? Bool
        let indexInfo = indexArrayController.valueForKeyPath("selection.info") as? String
        
        selectedIndex = (indexName!,indexFlavor!,indexIsPublic!,indexInfo!)
        
        if _handler != nil {
            _handler(NSOKButton)
        }
        closeSheet()
    }
    
    // Refresh index data
    @IBAction func refresh(sender: AnyObject) {
        self.setValue(true, forKey: "isRefreshing")
        
        // Fetch data from IDOL List Index service
        IDOLService.sharedInstance.fetchIndexList(apiKey!, completionHandler: {(data:NSData?, error:NSError?) in
            if error == nil {
                let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                let actions = json["actions"] as NSArray
                let result = actions[0]["result"] as NSDictionary
                var indexes : [DBHelper.IndexTuple] = []
                let publicIndexes: AnyObject? = result["public_index"]
                let privateIndexes : AnyObject? = result["index"]
                
                if publicIndexes != nil {
                    for pui in publicIndexes! as NSArray {
                        let indexName = pui["index"] as String
                        let indexType = pui["type"] as String
                        indexes.append((name:indexName,flavor:indexType,isPublic:true,info:""))
                    }
                }
                
                if privateIndexes != nil {
                    for pri in privateIndexes! as NSArray {
                        let indexName = pri["index"] as String
                        let indexFlavor = pri["flavor"] as String
                        let indexInfo = pri["description"]! != nil ?  pri["description"] as String : ""
                        indexes.append((name:indexName,flavor:indexFlavor,isPublic:false,info:indexInfo))
                    }
                }
                DBHelper.updateIndexes(self.managedObjectContext, data: indexes)
            } else {
                ErrorReporter.showErrorAlert(self.selectIndexPanel, error: error!)
            }
            
            self.setValue(false, forKey: "isRefreshing")
        })
    }
    
    private func closeSheet() {
        NSApplication.sharedApplication().endSheet(self.selectIndexPanel)
        self.selectIndexPanel.close()
    }
}
