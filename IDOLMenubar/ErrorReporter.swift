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
    
    class func showErrorAlert(_window:NSWindow!, error: NSError) {
        var title = ""
        var desc = ""
        if error.domain == "IDOLService" {
            title = "IDOLService Error"
            desc = error.userInfo!["Description"]! as String + " \(error.code)"
        } else {
            title = "Operation Failed"
            desc = error.localizedDescription
        }
        
        showErrorAlert(_window, title: title, desc: desc)
    }
}