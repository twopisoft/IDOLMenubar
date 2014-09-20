//
//  PreferenceViewController.swift
//  SwiftIDOLMenubar
//
//  Created by TwoPi on 4/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa
import AppKit

class PreferenceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    
    @IBOutlet weak var dirPrefTableView: NSTableView!
    
    @IBOutlet weak var apiKeyTextField: NSTextField!
    
    @IBOutlet var userDefaultsController: NSUserDefaultsController!
    
    @IBOutlet var prefArrayController: NSArrayController!
    
    var managedObjectContext : NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        userDefaultsController.appliesImmediately = false
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
    
    @IBAction func addDir(sender: AnyObject) {
        let mo : NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("IdolDirectories", inManagedObjectContext: self.managedObjectContext) as NSManagedObject
        
        mo.setValue(nil, forKey: "idolDirPath")
        mo.setValue(nil, forKey: "idolIndexName")
        mo.setValue(false, forKey: "isSyncing")
        mo.setValue(false, forKey: "syncFinished")
    }
    
    @IBAction func locateDir(sender: AnyObject) {
        let row = dirPrefTableView.rowForView(sender as NSView)
        prefArrayController.setSelectionIndex(row)
        
        var panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.beginSheetModalForWindow(parentWindow(), completionHandler: { (response : NSModalResponse) in
            if response == NSOKButton {
                self.prefArrayController.setValue(panel.URL!.path!, forKeyPath: "selection.idolDirPath")
            }
        })
    }
    
    @IBAction func locateIndex(sender: AnyObject) {
        let apiKey = userDefaultsController.values.valueForKey("idolApiKey") as? String
        if apiKey == nil  {
            let alert = NSAlert()
            alert.messageText = "IDOL API Key not configured"
            alert.informativeText = "IDOL API Key is not configured. Please set the API Key first."
            alert.beginSheetModalForWindow(parentWindow(), completionHandler: nil)
        } else {
            showSelectIndexPanel(apiKey)
        }
    }
    
    private func showSelectIndexPanel(apiKey : String!) {
        var panel = SelectIndexPanel()
        panel.managedObjectContext = self.managedObjectContext
        panel.apiKey = apiKey
        
        panel.beginSheetModalForWindow(parentWindow()!, completionHandler: { (response : NSModalResponse) in
            if response == NSOKButton {
                self.prefArrayController.setValue(panel.indexName!, forKeyPath: "selection.idolIndexName")
            }
        })
    }
    
    private func parentWindow() -> NSWindow? {
        return self.view.superview?.window
    }
    
    private func doneEditing() {
        parentWindow()!.close()
    }
    
}
