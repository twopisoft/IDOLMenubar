//
//  PreferenceViewController.swift
//  SwiftIDOLMenubar
//
//  Created by TwoPi on 4/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa
import AppKit

// Controller for Preference panel
class PreferenceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var dirPrefTableView: NSTableView!
    
    @IBOutlet weak var apiKeyTextField: NSTextField!
    
    @IBOutlet var userDefaultsController: NSUserDefaultsController!
    
    @IBOutlet var prefArrayController: NSArrayController!
    
    var managedObjectContext : NSManagedObjectContext!
    
    var sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "idolDirPath", ascending: true, selector: "compare:"),
                                         NSSortDescriptor(key: "idolIndexName",ascending: true, selector: "compare:")]
    
    var needsSave = false
    
    private var _apiKey : String? = nil
    var apiKey : String? {
        get {
            return _apiKey
        }
        set {
            if newValue == nil {
                _apiKey = nil
            } else {
                let trimmed : String = newValue!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                _apiKey = trimmed.isEmpty ? nil : trimmed
            }
        }
    }
    
    // MARK: NSObject/NSViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        userDefaultsController.appliesImmediately = false
    }
    
    // MARK: Actions
    @IBAction func cancel(sender: AnyObject) {
        userDefaultsController.revert(self)
        while managedObjectContext.hasChanges {
            managedObjectContext.undo()
        }
        self.setValue(false, forKey: "needsSave")
        doneEditing()
    }
    
    @IBAction func save(sender: AnyObject) {
        userDefaultsController.save(self)
        saveData()
        self.setValue(false, forKey: "needsSave")
        triggerDataSync()
    }
    
    @IBAction func addDir(sender: AnyObject) {
        let mo : NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("IdolDirectories", inManagedObjectContext: self.managedObjectContext) as NSManagedObject
        
        mo.setValue(nil, forKey: "idolDirPath")
        mo.setValue(nil, forKey: "idolIndexName")
        mo.setValue(false, forKey: "isSyncing")
        mo.setValue(false, forKey: "syncFinished")
        
        self.setValue(apiKeyTextField.stringValue, forKey: "apiKey")
        self.setValue(true, forKey: "needsSave")
    }
    
    @IBAction func delDir(sender: AnyObject) {
        prefArrayController.remove(sender)
        
        self.setValue(apiKeyTextField.stringValue, forKey: "apiKey")
        self.setValue(true, forKey: "needsSave")
    }
    
    // Open an NSOpen Panel to let user select a file
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
        let row = dirPrefTableView.rowForView(sender as NSView)
        prefArrayController.setSelectionIndex(row)
        showSelectIndexPanel(apiKey)
    }
    
    override func controlTextDidChange(obj: NSNotification!) {
        self.setValue(apiKeyTextField.stringValue, forKey: "apiKey")
        self.setValue(true, forKey: "needsSave")
    }
    
    // MARK: Helper methods
    private func triggerDataSync() {
        dispatch_async(dispatch_get_main_queue(), {
            let syncReady = DBHelper.getSyncReadyDirectories(self.managedObjectContext)
            for mo in syncReady {
                let dirPath = mo.valueForKey("idolDirPath") as String
                let indexName = mo.valueForKey("idolIndexName") as String

                mo.setValue(true, forKey: "isSyncing")
                self.saveData()
                AppDelegate.sharedAppDelegate().setValue(true, forKey: "syncInProgress")
                IDOLService.sharedInstance.uploadDocsToIndex(self._apiKey!, dirPath: dirPath, indexName: indexName, completionHandler: { (data:NSData?, err:NSError?) in
                    if err == nil {
                        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                        
                        if json["error"] == nil {
                            NSLog("Sync completed for directory \(dirPath). Response=\(json)")
                            mo.setValue(false, forKey: "isSyncing")
                            mo.setValue(true, forKey: "syncFinished")
                            
                        } else {
                            mo.setValue(false, forKey: "isSyncing")
                            NSLog("Error while syncing directory \(dirPath)")
                        }
                        self.saveData()
                        AppDelegate.sharedAppDelegate().setValue(false, forKey: "syncInProgress")
                    } else {
                        NSLog("PreferenceViewController: err=\(err)")
                        AppDelegate.sharedAppDelegate().setValue(false, forKey: "syncInProgress")
                        AppDelegate.sharedAppDelegate().setValue(true, forKey: "opError")
                        AppDelegate.sharedAppDelegate().setValue(err!, forKey: "lastError")
                    }
                })
            }
        })
    }
    
    private func saveData() {
        managedObjectContext.commitEditing()
        if managedObjectContext.hasChanges {
            managedObjectContext.save(nil)
        }
    }
    
    // Displays the selectIndexPanel. This is only shown if apiKey is set
    private func showSelectIndexPanel(apiKey : String!) {
        var panel = SelectIndexPanel()
        panel.managedObjectContext = self.managedObjectContext
        panel.apiKey = apiKey
        panel.listPublicIndex = false
        
        panel.beginSheetModalForWindow(parentWindow()!, completionHandler: { (response : NSModalResponse) in
            if response == NSOKButton {
                let selectedIndex = panel.selectedIndex
                if selectedIndex!.isPublic {
                    ErrorReporter.showErrorAlert(self.parentWindow(), title: "Error", desc: "Public Index cannot be used")
                } else {
                    self.prefArrayController.setValue(selectedIndex!.name, forKeyPath: "selection.idolIndexName")
                }
            }
        })
    }
    
    private func parentWindow() -> NSWindow? {
        return self.view.superview?.window
    }
    
    private func doneEditing() {
        parentWindow()!.orderBack(self)
        parentWindow()!.close()
    }
    
}
