//
//  ScopeValueTransformer.swift
//  IDOLMenubar
//
//  Created by TwoPi on 18/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa
import Foundation

class ScopeValueTransformer: NSValueTransformer {

    override class func transformedValueClass() -> AnyClass {
        return NSNumber.Type.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(value: AnyObject!) -> AnyObject! {
        if value != nil {
            if value.respondsToSelector("boolValue") {
                println("1")
                return value.boolValue! ? "Public" : "Private"
            }
        }
        return nil
    }
    
    override func reverseTransformedValue(value: AnyObject!) -> AnyObject! {
        if value != nil {
            if value.respondsToSelector("stringValue") {
                if value.stringValue! == "Public" {
                    return NSNumber(bool: true)
                }
                return NSNumber(bool: false)
            }
        }
        return nil
    }
}
