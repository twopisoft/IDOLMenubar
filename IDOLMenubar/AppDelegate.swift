//
//  AppDelegate.swift
//  IDOLMenubar
//
//  Created by TwoPi on 11/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var menu: NSMenu!
    
    @IBOutlet weak var currentView: NSView!
    
    var currentViewController : NSViewController? = nil
    
    lazy var prefViewController : PreferenceViewController = {
        return PreferenceViewController(nibName: "PreferenceViewController", bundle: NSBundle.mainBundle())
    }()
    
    lazy var searchViewController : SearchViewController = {
        return SearchViewController(nibName: "SearchViewController", bundle: NSBundle.mainBundle())
    }()
    
    lazy var manualDataAdd : Bool = {
        let mo : NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("IdolIndexes", inManagedObjectContext: self.managedObjectContext) as NSManagedObject
        mo.setValue("Test Index", forKey: "name")
        mo.setValue(true, forKey: "isPublic")
        mo.setValue("Explorer",forKey: "flavor")
        mo.setValue("Information about this index.", forKey: "info")
        return true
    }()
    
    var statusItem : NSStatusItem = NSStatusItem()
    
    override func awakeFromNib() {
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        statusItem.menu = menu
        statusItem.highlightMode = true
        statusItem.image = NSImage(named: "hp-logo-small")
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        //println("managedObjectModel=\(self.managedObjectModel)")
        NSValueTransformer.setValueTransformer(ScopeValueTransformer(), forName: "ScopeValueTransformer")
        let x = self.manualDataAdd
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    @IBAction func preferences(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        
        self.prefViewController.managedObjectContext = self.managedObjectContext
        changeViewController(self.prefViewController)
        self.window!.title = "Preferences"
        self.window!.makeKeyAndOrderFront(self)
    }

    @IBAction func conceptSearch(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        
        self.searchViewController.managedObjectContext = self.managedObjectContext
        changeViewController(self.searchViewController)
        self.window!.title = "Conceptual Search"
        self.window!.makeKeyAndOrderFront(self)
    }
    
    @IBAction func about(sender: AnyObject) {
    }
    
    @IBAction func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    func changeViewController(controller: NSViewController?) {
        assert(controller != nil, "Nil View Controller passed")
        
        if currentViewController != nil {
            currentViewController!.view.removeFromSuperview()
        }
        currentViewController = controller
        currentView.addSubview(currentViewController!.view)
        currentViewController!.view.frame = currentView.bounds
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.twopi.IDOLMenubar" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1] as NSURL
        return appSupportURL.URLByAppendingPathComponent("com.twopi.IDOLMenubar")
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("IDOLMenubar", withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL)
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        // Make sure the application files directory is there
        let propertiesOpt = self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey], error: &error)
        if let properties = propertiesOpt {
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else if error!.code == NSFileReadNoSuchFileError {
            error = nil
            fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil, error: &error)
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("IDOLMenubar.storedata")
            if coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
                coordinator = nil
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            error = NSError.errorWithDomain("IDOLMenubar", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error)
            return nil
        } else {
            return coordinator
        }
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving and Undo support
    
    /*@IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSApplication.sharedApplication().presentError(error)
            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow!) -> NSUndoManager! {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }*/
    
    /*func applicationShouldTerminate(sender: NSApplication!) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
                return .TerminateCancel
            }
            
            if !moc.hasChanges {
                return .TerminateNow
            }
            
            var error: NSError? = nil
            if !moc.save(&error) {
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(error)
                if (result) {
                    return .TerminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButtonWithTitle(quitButton)
                alert.addButtonWithTitle(cancelButton)
                
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .TerminateCancel
                }
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }*/
}

