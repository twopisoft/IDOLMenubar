//
//  HyperlinkValueTransformer.swift
//  IDOLMenubar
//
//  Created by TwoPi on 22/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

// Custom NSValueTransformer to convert a URL into a hyperlink. To be used for a NSTextField
// when displayed inside a NSTableCellView

// This transformer changes the string value to an attributed string value

class HyperlinkValueTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSAttributedString.Type.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(value: AnyObject!) -> AnyObject! {
        if value != nil {
            let origVal = value as String
            var attrStr = NSMutableAttributedString(string: origVal)
            let range = NSMakeRange(0, attrStr.length)
            attrStr.beginEditing()
            attrStr.addAttribute(NSLinkAttributeName, value: origVal, range: range)
            attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.blackColor(), range: range)
            attrStr.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(integer: NSSingleUnderlineStyle), range: range)
            attrStr.endEditing()
            return attrStr
        }
        return nil
    }
    
    override func reverseTransformedValue(value: AnyObject!) -> AnyObject! {
        if value != nil {
            if value.respondsToSelector("string") {
                return value.string
            }
        }
        return nil
    }
}
