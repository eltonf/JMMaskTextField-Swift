//
//  JMMaskTextField.swift
//  JMMaskTextField Swift
//
//  Created by Jota Melo on 02/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

open class JMMaskTextField: UITextField {

    // damn, maskView is just mask in Swift
    open private(set) var stringMask: JMStringMask? {
        didSet {
            self.maskDelegate.stringMask = self.stringMask
        }
    }
    open lazy private(set) var maskDelegate: JMMaskTextFieldDelegate = JMMaskTextFieldDelegate()
    
    override weak open var delegate: UITextFieldDelegate? {
        get {
            return self.maskDelegate.realDelegate
        }
        
        set (newValue) {
            self.maskDelegate.realDelegate = newValue
            super.delegate = self.maskDelegate
        }
    }
    
    open var unmaskedText: String? {
        get {
            return self.stringMask?.unmask(string: self.text) ?? self.text
        }
    }
    
    @IBInspectable open var maskString: String? {
        didSet {
            guard let maskString = self.maskString else { return }
            self.stringMask = JMStringMask(mask: maskString)
        }
    }
    
    #if TARGET_INTERFACE_BUILDER
    @IBOutlet open weak var maskStringDelegate: AnyObject?
    #else
    open weak var maskStringDelegate: JMMaskStringDelegate?
    #endif
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        self.commonInit()
    }
    
    func commonInit() {
        self.maskDelegate.stringMask = self.stringMask
        self.maskDelegate.maskStringDelegate = self.maskStringDelegate
        super.delegate = self.maskDelegate
    }
    
}

@objc public protocol JMMaskStringDelegate {

    // Allow the user to change the string mask based on current state
    func maskString(textField: JMMaskTextField, willChangeCharactersIn range: NSRange, replacementString string: String) -> String?
    
}

open class JMMaskTextFieldDelegate: NSObject {
    
    open var stringMask: JMStringMask?
    open var maskStringDelegate: JMMaskStringDelegate?
    fileprivate weak var realDelegate: UITextFieldDelegate?
    
}

extension JMMaskTextFieldDelegate: UITextFieldDelegate {
    
    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.realDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        self.realDelegate?.textFieldDidBeginEditing?(textField)
    }
    
    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return self.realDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        self.realDelegate?.textFieldDidEndEditing?(textField)
    }
    
    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let previousMask = self.stringMask
        let currentText: NSString = textField.text as NSString? ?? ""
        
        if let realDelegate = self.realDelegate, realDelegate.responds(to: #selector(textField(_:shouldChangeCharactersIn:replacementString:))) {
            let delegateResponse = realDelegate.textField!(textField, shouldChangeCharactersIn: range, replacementString: string)
            
            if !delegateResponse {
                return false
            }
        }
        
        if let delegate = self.maskStringDelegate, let textField = textField as? JMMaskTextField {
            if let maskString = delegate.maskString(textField: textField, willChangeCharactersIn: range, replacementString: string) {
                self.stringMask = JMStringMask(mask: maskString)
            } else {
                self.stringMask = nil
            }
        }
        
        guard let mask = self.stringMask else { return true }
        
        let newText = currentText.replacingCharacters(in: range, with: string)
        var formattedString = mask.mask(string: newText)
        
        // if the mask changed or if the text couldn't be formatted,
        // unmask the newText and mask it again
        if (previousMask != nil && mask != previousMask!) || formattedString == nil {
            let unmaskedString = mask.unmask(string: newText)
            formattedString = mask.mask(string: unmaskedString)
        }
        
        guard let finalText = formattedString as NSString? else { return false }
        
        // if the cursor is not at the end and the string hasn't changed
        // it means the user tried to delete a mask character, so we'll
        // change the range to include the character right before it
        if finalText == currentText && range.location < currentText.length && range.location > 0 {
            return self.textField(textField, shouldChangeCharactersIn: NSRange(location: range.location - 1, length: range.length + 1) , replacementString: string)
        }
        
        if finalText != currentText {
            textField.text = finalText as String
            
            // the user is trying to delete something so we need to
            // move the cursor accordingly
            if range.location < currentText.length {
                var cursorLocation = 0
                
                if range.location > finalText.length {
                    cursorLocation = finalText.length
                } else if currentText.length > finalText.length {
                    cursorLocation = range.location
                } else {
                    cursorLocation = range.location + 1
                }
                
                guard let startPosition = textField.position(from: textField.beginningOfDocument, offset: cursorLocation) else { return false }
                guard let endPosition = textField.position(from: startPosition, offset: 0) else { return false }
                textField.selectedTextRange = textField.textRange(from: startPosition, to: endPosition)
            }
            
            return false
        }
        
        return true
    }
    
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return self.realDelegate?.textFieldShouldClear?(textField) ?? true
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.realDelegate?.textFieldShouldReturn?(textField) ?? true
    }
    
}
