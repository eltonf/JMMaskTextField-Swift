//
//  ViewController.swift
//  JMMaskTextField
//
//  Created by Jota Melo on 01/05/2017.
//  Copyright (c) 2017 Jota Melo. All rights reserved.
//

import UIKit
import JMMaskTextField

class ViewController: UIViewController {
    
}

extension ViewController: JMMaskStringDelegate {
    
    func maskString(textField: JMMaskTextField, willChangeCharactersIn range: NSRange, replacementString string: String) -> String? {
        guard let text = textField.text as NSString? else {
            return textField.maskString
        }
        let newText = text.replacingCharacters(in: range, with: string)
        
        guard let unmaskedText = textField.stringMask?.unmask(string: newText) else {
            return textField.maskString
        }
        
        if unmaskedText.characters.count >= 11 {
            textField.maskString = "(00) 0 0000-0000"
        } else {
            textField.maskString = "(00) 0000-0000"
        }
        
        return textField.maskString
    }
}
