//
//  PreferenceViewController.swift
//  SwiftIDOLMenubar
//
//  Created by TwoPi on 4/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

class PreferenceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    
    @IBOutlet weak var dirPrefTableView: NSTableView!
    
    @IBOutlet weak var apiKeyTextField: NSTextField!
    
    @IBOutlet var selectIndexSheet : NSWindow!
    
    @IBOutlet var userDefaultsController: NSUserDefaultsController!
    
    @IBOutlet var prefArrayController: NSArrayController!
    
    var managedObjectContext : NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        userDefaultsController.appliesImmediately = false
    }
    
    private func parentWindow() -> NSWindow? {
        return self.view.superview?.window
    }
    
    private func doneEditing() {
        parentWindow()!.close()
    }
    
    @IBAction func cancel(sender: AnyObject) {
        userDefaultsController.revert(self)
        managedObjectContext.undo()
        doneEditing()
    }
    
    @IBAction func save(sender: AnyObject) {
        userDefaultsController.save(self)
        managedObjectContext.save(nil)
        doneEditing()
    }
    
    @IBAction func add(sender: AnyObject) {
        IdolDirectories(entity: NSEntityDescription.entityForName("IdolDirectories", inManagedObjectContext: self.managedObjectContext),
            insertIntoManagedObjectContext: self.managedObjectContext)
    }
    
    @IBAction func locateDir(sender: AnyObject) {
        let row = dirPrefTableView.rowForView(sender as NSView)
        prefArrayController.setSelectionIndex(row)
        
        var panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.beginSheetModalForWindow(parentWindow(), completionHandler: { (response : NSModalResponse) in
            if response == 1 {
                self.prefArrayController.setValue(panel.URL!.path!, forKeyPath: "selection.idolDirPath")
            }
        })
        
    }
    
    @IBAction func locateIndex(sender: AnyObject) {
        let apiKey: AnyObject! = userDefaultsController.values.valueForKey("idolApiKey")
        if apiKey == nil  {
            let alert = NSAlert()
            alert.messageText = "IDOL API Key not configured"
            alert.informativeText = "IDOL API Key is not configured. Please set the API Key first."
            alert.beginSheetModalForWindow(parentWindow(), completionHandler: nil)
        } else {
            showSelectIndexSheet()
        }
    }
    
    private func showSelectIndexSheet() {
        if selectIndexSheet == nil {
            NSBundle.mainBundle().loadNibNamed("SelectIndexSheet", owner: self, topLevelObjects: nil)
        }
        NSApplication.sharedApplication().beginSheet(self.selectIndexSheet,
            modalForWindow: parentWindow(),
            modalDelegate: self,
            didEndSelector: nil,
            contextInfo: nil)
    }
    
    @IBAction func closeIndexSheet(sender: AnyObject) {
        NSApplication.sharedApplication().endSheet(self.selectIndexSheet)
        self.selectIndexSheet.close()
        //self.selectIndexSheet = nil
    }
    
}
