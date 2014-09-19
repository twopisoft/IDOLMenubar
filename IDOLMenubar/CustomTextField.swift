//
//  CustomTextField.swift
//  IDOLMenubar
//
//  Created by TwoPi on 19/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Cocoa

class CustomTextField: NSTextField {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func performKeyEquivalent(theEvent: NSEvent) -> Bool {
        if (theEvent.type == .KeyDown &&
            (theEvent.modifierFlags & .CommandKeyMask) == .CommandKeyMask) {
                if let responder = self.window!.firstResponder {
                    if responder.isKindOfClass(NSTextView) {
                        let textField = responder as NSTextView
                        let range = textField.selectedRange
                        let isSelected = range.length > 0
                        let keyCode = theEvent.keyCode
                        
                        var ret = false
                        
                        switch keyCode {
                        case 6: if textField.undoManager.canUndo {
                            textField.undoManager.undo()
                            ret = true
                            }
                        case 7 : if isSelected {
                            textField.cut(self)
                            ret = true
                            }
                        case 8: if isSelected {
                            textField.copy(self)
                            ret = true
                            }
                        case 9: textField.paste(self);  ret = true
                        default: break
                        }
                        
                        return ret
                    }
                } else {
                    super.performKeyEquivalent(theEvent)
                }
        }
        return super.performKeyEquivalent(theEvent)
    }
    
}
