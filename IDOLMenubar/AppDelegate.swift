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
        self.window!.title = "Preferences"
        self.window!.makeKeyAndOrderFront(self)
    }

    @IBAction func conceptSearch(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true)
        self.window!.title = "Concept Search"
        self.window!.makeKeyAndOrderFront(self)
    }
    
    @IBAction func about(sender: AnyObject) {
    }
    
    @IBAction func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
}

