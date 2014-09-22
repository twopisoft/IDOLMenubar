//
//  CustomTableView.swift
//  IDOLMenubar
//
//  Created by TwoPi on 22/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

class CustomTableView: NSTableView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func validateProposedFirstResponder(responder: NSResponder!, forEvent event: NSEvent!) -> Bool {
        return true
    }
    
}
