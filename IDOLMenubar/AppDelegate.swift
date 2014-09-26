//
//  AppDelegate.swift
//  IDOLMenubar
//
//  Created by TwoPi on 11/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: Properties
    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var menu: NSMenu!
    
    @IBOutlet weak var currentView: NSView!
    
    var currentViewController : NSViewController? = nil
    
    // Properties for lazily creating various view controllers
    lazy var prefViewController : PreferenceViewController = {
        return PreferenceViewController(nibName: "PreferenceViewController", bundle: NSBundle.mainBundle())
    }()
    
    lazy var searchViewController : SearchViewController = {
        return SearchViewController(nibName: "SearchViewController", bundle: NSBundle.mainBundle())
    }()
    
    lazy var aboutPanelController : AboutPanelController = {
        return AboutPanelController()
    }()
    
    var statusItem : NSStatusItem = NSStatusItem()
    
    private var _statusItemImage : NSImage = NSImage(named: "hp-logo-alpha-small")
    private var _statusItemAltImage : NSImage = NSImage(named: "hp-logo-alpha-small-alt")
    private var _statusErrImage : NSImage = NSImage(named: "hp-logo-alpha-small-err")
    
    private var _timer : NSTimer? = nil
    private var _syncInProgress = false
    private var _opError = false
    
    var syncInProgress : Bool {
        get {
            return _syncInProgress
        }
        set {
            _syncInProgress = newValue
            if _syncInProgress {
                statusItem.toolTip = "Uploading data to Index"
                self._timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "toggleImage:", userInfo: nil, repeats: true)
            } else {
                NSLog("Stopping timer")
                if self._timer != nil {
                    self._timer!.invalidate()
                }
                statusItem.image = _statusItemImage
                statusItem.alternateImage = _statusItemAltImage
                statusItem.toolTip = "IDOLMenubar"
            }
        }
    }
    
    var opError : Bool {
        get {
            return _opError
        }
        set {
            _opError = newValue
            if self._timer != nil {
                self._timer!.invalidate()
            }
            if _opError {
                NSLog("Set error image")
                statusItem.image = _statusErrImage
            } else {
                statusItem.image = _statusItemImage
            }
        }
    }
    
    var lastError : NSError? = nil
        
    // MARK: AppDelegate methods
    class func sharedAppDelegate() -> AppDelegate {
        return NSApplication.sharedApplication().delegate as AppDelegate
    }
    
    override func awakeFromNib() {
        // Set up the status bar item
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        statusItem.menu = menu
        statusItem.highlightMode = true
        statusItem.image = _statusItemImage
        statusItem.alternateImage = _statusItemAltImage
        statusItem.toolTip = "IDOLMenubar"
        
        NSValueTransformer.setValueTransformer(HyperlinkValueTransformer(), forName: "HyperlinkValueTransformer")
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {

    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    // MARK: Menu Actions
    
    // Menu action for preferences
    @IBAction func preferences(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        
        self.prefViewController.managedObjectContext = self.managedObjectContext
        changeViewController(self.prefViewController)
        self.window!.title = "Preferences"
        self.window!.makeKeyAndOrderFront(self)
    }

    // Menu action for concept search
    @IBAction func conceptSearch(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        
        self.searchViewController.managedObjectContext = self.managedObjectContext
        changeViewController(self.searchViewController)
        self.window!.title = "Conceptual Search"
        self.window!.makeKeyAndOrderFront(self)
    }
    
    // Menu action for about info. Note that AboutPanelController is not a
    // NSViewController. Hence it is just shown as a modal panel on the main
    // window
    @IBAction func about(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        
        if currentViewController != nil {
            currentViewController!.view.removeFromSuperview()
            currentViewController = nil
        }
        self.window!.title = "About IDOL Menubar"
        self.window!.makeKeyAndOrderFront(self)
        
        self.aboutPanelController.showAboutPanel(self.window, { self.window!.close() })
    }
    
    // Menu action for quit
    @IBAction func quit(sender: AnyObject) {
        // Undo all uncommitted data
        if let moc = managedObjectContext {
            while moc.hasChanges {
                moc.undo()
            }
        }
        NSApplication.sharedApplication().terminate(self)
    }
    
    // Displays the last error encountered by the service
    @IBAction func lastError(sender: AnyObject) {
        if lastError != nil {
            NSApp.activateIgnoringOtherApps(true)
            if currentViewController != nil {
                currentViewController!.view.removeFromSuperview()
                currentViewController = nil
            }
            self.window!.title = "Last Error Message"
            self.window!.makeKeyAndOrderFront(self)
            
            ErrorReporter.showErrorAlert(self.window, error: lastError!, closeWindow: true)
            //self.window.close()
            self.setValue(false, forKey: "opError")
        }
    }
    
    // MARK: View controller management
    private func changeViewController(controller: NSViewController?) {
        assert(controller != nil, "Nil View Controller passed")
        
        if currentViewController != nil {
            currentViewController!.view.removeFromSuperview()
        }
        currentViewController = controller
        currentView.addSubview(currentViewController!.view)
        currentViewController!.view.frame = currentView.bounds
    }
    
    // MARK: Progress indication
    
    // Simple animation. Just alternate image and alternateImage
    func toggleImage(timer : NSTimer) {
        let temp = statusItem.image
        statusItem.image = statusItem.alternateImage
        statusItem.alternateImage = temp
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
        return NSManagedObjectModel(contentsOfURL: modelURL!)
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
            //error = NSError.errorWithDomain("IDOLMenubar", code: 9999, userInfo: dict)
            error = NSError(domain: "IDOLMenubar", code: 9999, userInfo: dict)
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
}

