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
    var prefViewController : PreferenceViewController? = nil
    var searchViewController : SearchViewController? = nil
    
    var statusItem : NSStatusItem = NSStatusItem()
    
    override func awakeFromNib() {
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        statusItem.menu = menu
        statusItem.highlightMode = true
        statusItem.image = NSImage(named: "hp-logo-small")
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    @IBAction func preferences(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        
        if prefViewController == nil {
            prefViewController = PreferenceViewController(nibName: "PreferenceViewController", bundle: nil)
        }
        changeViewController(prefViewController)
        prefViewController?.reloadView()
        self.window!.title = "Preferences"
        self.window!.makeKeyAndOrderFront(self)
    }

    @IBAction func conceptSearch(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        
        if searchViewController == nil {
            searchViewController = SearchViewController(nibName: "SearchViewController", bundle: nil)
        }
        changeViewController(searchViewController)
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
}

