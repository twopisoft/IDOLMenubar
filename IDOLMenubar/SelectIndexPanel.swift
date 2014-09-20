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
        indexName = indexArrayController.valueForKeyPath("selection.indexName") as? String
        
        if handler != nil {
            handler(NSOKButton)
        }
        closeSheet()
    }
    
    @IBAction func refresh(sender: AnyObject) {
        self.setValue(true, forKey: "isRefreshing")
    }
    
    private func closeSheet() {
        NSApplication.sharedApplication().endSheet(self.selectIndexPanel)
        self.selectIndexPanel.close()
    }
}
