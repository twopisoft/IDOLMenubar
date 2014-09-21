//
//  ErrorReporter.swift
//  IDOLMenubar
//
//  Created by TwoPi on 21/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import Cocoa

class ErrorReporter {
    
    class func showErrorAlert(_window:NSWindow!, title:String, desc:String) {
        dispatch_async(dispatch_get_main_queue(), {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = desc
            alert.beginSheetModalForWindow(_window, completionHandler: nil)
        })
    }
}