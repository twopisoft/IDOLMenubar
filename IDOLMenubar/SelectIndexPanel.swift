//
//  SelectIndexPanel.swift
//  IDOLMenubar
//
//  Created by TwoPi on 20/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa


class SelectIndexPanel : NSObject {
    
    private var handler : ((NSModalResponse) -> Void)! = nil
    
    @IBOutlet var indexArrayController: NSArrayController!
    @IBOutlet var selectIndexPanel: NSPanel!
    
    var managedObjectContext : NSManagedObjectContext! = nil
    var isRefreshing : Bool = false
    var apiKey : String? = nil
    var indexName : String? = nil
    
    func beginSheetModalForWindow(_window : NSWindow!, completionHandler handler: ((NSModalResponse) -> Void)!) {
        
        if selectIndexPanel == nil {
            NSBundle.mainBundle().loadNibNamed("SelectIndexSheet", owner: self, topLevelObjects: nil)
        }
        
        self.handler = handler
        
        NSApplication.sharedApplication().beginSheet(selectIndexPanel, modalForWindow: _window!, modalDelegate: self, didEndSelector: nil, contextInfo: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        indexName = nil
        
        if handler != nil {
            handler(NSCancelButton)
        }
        closeSheet()
    }
    
    @IBAction func select(sender: AnyObject) {
        indexName = indexArrayController.valueForKeyPath("selection.name") as? String
        
        if handler != nil {
            handler(NSOKButton)
        }
        closeSheet()
    }
    
    @IBAction func refresh(sender: AnyObject) {
        self.setValue(true, forKey: "isRefreshing")
        
        IDOLService.sharedInstance.fetchIndexList(completionHandler: {(data:NSData?, error:NSError?) in
            if error == nil {
                let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                
                var indexes : [DBHelper.IndexTuple] = []
                let publicIndexes: AnyObject? = json["public_index"]
                let privateIndexes : AnyObject? = json["index"]
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
                        let indexInfo = pri["description"] as String
                        indexes.append((name:indexName,flavor:indexFlavor,isPublic:false,info:indexInfo))
                    }
                }
                DBHelper.updateIndexes(self.managedObjectContext, data: indexes)
            } else {
                if error!.domain == "IDOLService" {
                    self.showErrorAlert(error!.code, desc: error!.userInfo!["Description"]! as String)
                } else {
                    self.showErrorAlert(error!.code, desc: error!.localizedDescription)
                }
            }
            self.setValue(false, forKey: "isRefreshing")
        })
    }
    
    private func closeSheet() {
        NSApplication.sharedApplication().endSheet(self.selectIndexPanel)
        self.selectIndexPanel.close()
    }
    
    private func showErrorAlert(code:Int, desc:String) {
        dispatch_async(dispatch_get_main_queue(), {
            let alert = NSAlert()
            alert.messageText = "Operation Failed"
            alert.informativeText = "Error code: \(code)\nError: \(desc)"
            alert.beginSheetModalForWindow(self.selectIndexPanel, completionHandler: nil)
        })
    }
}
