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
    
    var sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "idolDirPath", ascending: true, selector: "compare:"),
                                         NSSortDescriptor(key: "idolIndexName",ascending: true, selector: "compare:")]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        userDefaultsController.appliesImmediately = false
    }
    
    @IBAction func cancel(sender: AnyObject) {
        userDefaultsController.revert(self)
        if managedObjectContext.hasChanges {
            managedObjectContext.undo()
        }
        doneEditing()
    }
    
    @IBAction func save(sender: AnyObject) {
        userDefaultsController.save(self)
        saveData()
        triggerDataSync()
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
        //let apiKey = userDefaultsController.values.valueForKey("idolApiKey") as? String
        let apiKey = apiKeyTextField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if apiKey.isEmpty  {
            ErrorReporter.showErrorAlert(parentWindow(),
                title: "IDOL API Key not configured",
                desc: "IDOL API Key is not configured. Please set the API Key first.")
        } else {
            showSelectIndexPanel(apiKey)
        }
    }
    
    private func triggerDataSync() {
        let syncReady = DBHelper.getSyncReadyDirectories(self.managedObjectContext)
        for mo in syncReady {
            let dirPath = mo.valueForKey("idolDirPath") as String
            let indexName = mo.valueForKey("idolIndexName") as String

            mo.setValue(true, forKey: "isSyncing")
            self.saveData()
            IDOLService.sharedInstance.uploadDocsToIndex(dirPath, indexName: indexName, completionHandler: { (data:NSData?, err:NSError?) in
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
                }
            })
        }
    }
    
    private func saveData() {
        managedObjectContext.commitEditing()
        if managedObjectContext.hasChanges {
            managedObjectContext.save(nil)
        }
    }
    
    private func showSelectIndexPanel(apiKey : String!) {
        var panel = SelectIndexPanel()
        panel.managedObjectContext = self.managedObjectContext
        panel.apiKey = apiKey
        
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
        parentWindow()!.close()
    }
    
}
