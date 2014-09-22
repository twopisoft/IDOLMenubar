//
//  AboutPanelController.swift
//  IDOLMenubar
//
//  Created by TwoPi on 21/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

class AboutPanelController: NSObject {

    private var handler : (() -> Void)! = nil
    
    @IBOutlet var aboutPanelSheet: NSPanel!
    
    @IBOutlet var aboutTextView: NSTextView!
    
    @IBOutlet weak var logoImageView: NSImageView!
    
    func showAboutPanel(_window: NSWindow!, completionHandler handler: (() -> Void)!) {
        
        if aboutPanelSheet == nil {
            NSBundle.mainBundle().loadNibNamed("AboutPanelSheet", owner: self, topLevelObjects: nil)
        }
        
        self.handler = handler
        
        aboutTextView.string = "\n\nSubmitted by arshad01\n\n Video: https://www.youtube.com/watch?v=oesV4bhGyUs\n\nBlog: http://linkedin.com"
        aboutTextView.alignment = NSTextAlignment.CenterTextAlignment
        aboutTextView.font = NSFont(name: "Arial", size: 14)
        aboutTextView.editable = true
        aboutTextView.checkTextInDocument(nil)
        aboutTextView.editable = false

        logoImageView.image = NSImage(named: "logo-lg.png")
        
        NSApplication.sharedApplication().beginSheet(self.aboutPanelSheet, modalForWindow: _window, modalDelegate: self, didEndSelector: nil, contextInfo: nil)
    }
    
    @IBAction func closePanel(sender: AnyObject) {
        NSApplication.sharedApplication().endSheet(self.aboutPanelSheet)
        self.aboutPanelSheet.close()
        if handler != nil {
            handler()
        }
    }
}