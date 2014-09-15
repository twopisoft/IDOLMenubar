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
    
    var prefs = Preferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func reloadView() {
        if dirPrefTableView != nil {
            prefs.loadPreferences()
            apiKeyTextField.stringValue = prefs.apiKey
            dirPrefTableView.reloadData()
        }
    }
    
    private func parentWindow() -> NSWindow? {
        return self.view.superview?.window
    }
    
    private func doneEditing() {
        parentWindow()!.close()
    }
    
    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        return prefs.dirEntryCount()
    }
    
    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
        if let dirPref = prefs.getDirEntry(row) {
            var identifier = tableColumn.identifier!
           
            var cellView : NSTableCellView = tableView.makeViewWithIdentifier(identifier, owner: self) as NSTableCellView
            switch identifier {
            case "DirectoryCell": cellView.textField.stringValue = dirPref.path
            case "IndexCell"    : cellView.textField.stringValue = dirPref.index
            default: break
            }
        
            return cellView
        }
        
        return nil
    }
    
    @IBAction func cancel(sender: AnyObject) {
        doneEditing()
    }
    
    @IBAction func save(sender: AnyObject) {
        if let apiKey = apiKeyTextField.stringValue {
            prefs.apiKey = apiKey
        }
        prefs.savePreferences()
        doneEditing()
    }
    
    @IBAction func locateDir(sender: AnyObject) {
        let selectedRow = dirPrefTableView.rowForView(sender as NSView)
        var dirPref = prefs.getDirEntry(selectedRow)!
        var path = dirPref.path.isEmpty ? "~/" : dirPref.path
        
        var panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.beginSheetModalForWindow(parentWindow(), completionHandler: { (response : NSModalResponse) in
                if response == 1 {
                    dirPref.path = panel.URL!.path!
                    self.prefs.updateDirEntry(dirPref, atIndex: selectedRow)
                    self.dirPrefTableView.reloadData()
                }
            })
    }
    
    @IBAction func locateIndex(sender: AnyObject) {
        if prefs.apiKey.isEmpty {
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
    
    @IBAction func insertNewEntry(sender: AnyObject) {
        let selectedRow = dirPrefTableView.selectedRow+1
        prefs.insertDirEntry(DirEntry(), atIndex: selectedRow)
        dirPrefTableView.beginUpdates()
        dirPrefTableView.insertRowsAtIndexes(NSIndexSet(index: selectedRow), withAnimation: NSTableViewAnimationOptions.EffectGap)
        dirPrefTableView.scrollRowToVisible(selectedRow)
        dirPrefTableView.endUpdates()
    }
    
    @IBAction func removeEntry(sender: AnyObject) {
        let selectedRows = dirPrefTableView.selectedRowIndexes
        if selectedRows.count > 0 {
            prefs.removeDirEntry(selectedRows.firstIndex)
            dirPrefTableView.removeRowsAtIndexes(selectedRows, withAnimation: NSTableViewAnimationOptions.SlideDown)
        }
    }
    
}
